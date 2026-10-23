import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/command_runner.dart';
import '../core/git_client.dart';
import '../core/vscode.dart';
import '../devices/device_service.dart';
import '../doctor/checks.dart';
import '../doctor/diagnostics.dart';
import '../devices/mobile_device.dart';
import '../flutter/flutter_project.dart';
import 'build_options.dart';
import 'install_plan.dart';

enum VsCodeResult { opened, notFound, failed }

enum GitAction { fetch, pull }

enum StepStatus { pending, running, done, failed, cancelled }

/// 프로젝트·기기·모드를 고르고 계획을 실행하는 화면의 상태.
class InstallController extends ChangeNotifier {
  InstallController({
    required this.runner,
    required this.deviceService,
    this.diagnosticsService,
    GitClient? gitClient,
    this.vscodeCommand = vscodeOpenCommand,
    bool? hostIsMac,
    bool? hostIsWindows,
  }) : git = gitClient ?? GitClient(runner),
       hostIsMac = hostIsMac ?? Platform.isMacOS,
       hostIsWindows = hostIsWindows ?? Platform.isWindows;

  /// 이 앱이 도는 OS. 이 컴퓨터를 빌드 대상으로 보여 줄지(데스크톱)와 iOS 설치 가능 여부가 여기에 달렸다.
  final bool hostIsMac;
  final bool hostIsWindows;

  static const _projectKey = 'last_project';
  static const _teamKey = 'ios_team_id';
  static const _modeKey = 'build_mode';
  static const _tabKey = 'last_tab';
  static const _toolKeyPrefix = 'tool_path_';
  static const _optionsKeyPrefix = 'build_options:';

  /// 사용자가 위치를 지정할 수 있는 도구.
  static const configurableTools = ['flutter', 'adb'];

  final CommandRunner runner;
  final DeviceService deviceService;
  final DiagnosticsService? diagnosticsService;
  final GitClient git;

  /// VS Code로 폴더를 여는 명령을 찾는다. 테스트에서 바꾼다.
  final Future<List<String>?> Function(String dir, {required String path}) vscodeCommand;

  SharedPreferences? _prefs;
  FlutterProject? project;
  String? projectError;
  List<MobileDevice> devices = const [];
  bool loadingDevices = false;
  String? selectedId;
  BuildMode mode = BuildMode.release;
  String? teamId;

  /// 이 프로젝트의 빌드 옵션 (flavor, 진입 파일, dart-define 파일 …). 프로젝트마다 따로 저장한다.
  BuildOptions options = const BuildOptions();

  Diagnostics? diagnostics;
  bool diagnosing = false;

  /// 마지막으로 보던 탭 (0 설치 · 1 기기 · 2 서명 · 3 점검 · 4 기록).
  int tabIndex = 0;

  /// 저장된 탭을 읽었는지 — 화면이 한 번만 그 탭으로 옮긴다.
  bool tabLoaded = false;

  bool running = false;

  /// `flutter clean` + `flutter pub get`을 실행 중인지, 마지막 결과(null이면 아직 안 함).
  bool cleaning = false;
  bool? cleanResult;
  List<StepStatus> statuses = const [];
  FailureHint? hint;

  /// 실행 파일을 찾지 못해 실패했을 때 그 이름 (`flutter`, `adb` …).
  String? missingCommand;
  RunHandle? _handle;

  /// 화면에 보이는 대상: 연결된 실기기 + (프로젝트가 이 OS의 데스크톱을 이미 지원하면) 이 컴퓨터.
  List<MobileDevice> get visibleDevices {
    final host = hostDesktopDevice(project, isMac: hostIsMac, isWindows: hostIsWindows);
    return [...devices, ?host];
  }

  MobileDevice? get device {
    for (final d in visibleDevices) {
      if (d.id == selectedId) return d;
    }
    return null;
  }

  /// 이 프로젝트가 그 대상의 플랫폼을 지원하는지 (프로젝트를 아직 안 열었으면 지원한다고 본다).
  bool _supports(MobileDevice d) {
    final p = project;
    if (p == null) return true;
    return switch (d.platform) {
      DevicePlatform.ios => p.hasIos,
      DevicePlatform.android => p.hasAndroid,
      DevicePlatform.macos => p.hasMacos,
      DevicePlatform.windows => p.hasWindows,
    };
  }

  /// 프로젝트가 지원하는 대상을 먼저, 그중 USB로 연결된 실기기를 먼저 고른다. 없으면 보이는 첫 대상.
  void _pickDefaultDevice() {
    final all = visibleDevices;
    final supported = all.where(_supports).toList();
    selectedId = [
      ...supported.where((d) => d.isUsb),
      ...supported,
      ...all.where((d) => d.isUsb),
      ...all,
    ].firstOrNull?.id;
  }

  /// 입력한 Team ID → 프로젝트의 Team ID → 키체인에 쓸 수 있는 인증서가 하나뿐이면 그 Team 순서.
  String? get effectiveTeamId {
    if (teamId != null) return teamId;
    if (project?.iosTeamId != null) return project!.iosTeamId;
    final teams = diagnostics?.usableTeams ?? const <String>{};
    return teams.length == 1 ? teams.single : null;
  }

  InstallPlan get plan => buildInstallPlan(
    project: project,
    device: device,
    mode: mode,
    teamId: effectiveTeamId,
    hostIsMac: hostIsMac,
    // Windows ARM에서는 산출물이 build\windows\arm64 아래에 생긴다.
    windowsArch: Platform.environment['PROCESSOR_ARCHITECTURE']?.toUpperCase() == 'ARM64' ? 'arm64' : 'x64',
    options: options,
  );

  List<CheckItem> get checks => buildChecks(
    diagnostics: diagnostics,
    project: project,
    device: device,
    teamId: effectiveTeamId,
    hostIsMac: hostIsMac,
    hostIsWindows: hostIsWindows,
    now: DateTime.now(),
  );

  /// 도구·인증서·프로파일·키스토어를 다시 읽는다.
  Future<void> runDiagnostics() async {
    final service = diagnosticsService;
    if (service == null) return;
    // 읽는 도중에 다시 요청되면(도구 경로를 방금 바꾼 경우 등) 끝난 뒤 한 번 더 읽는다.
    if (diagnosing) {
      _diagnoseAgain = true;
      return;
    }
    diagnosing = true;
    notifyListeners();
    do {
      _diagnoseAgain = false;
      final result = await service.collect(project);
      // 읽는 사이에 다시 요청됐다면 이 결과는 이미 낡았다 — 보여 주지 않는다.
      if (!_diagnoseAgain) diagnostics = result;
    } while (_diagnoseAgain);
    diagnosing = false;
    notifyListeners();
  }

  bool _diagnoseAgain = false;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      teamId = _prefs!.getString(_teamKey);
      mode = BuildMode.values.asNameMap()[_prefs!.getString(_modeKey)] ?? BuildMode.release;
      tabIndex = (_prefs!.getInt(_tabKey) ?? 0).clamp(0, 4);
      tabLoaded = true;
      for (final tool in configurableTools) {
        final saved = _prefs!.getString('$_toolKeyPrefix$tool');
        if (saved != null && saved.isNotEmpty) runner.toolPaths[tool] = saved;
      }
      final last = _prefs!.getString(_projectKey);
      if (last != null) project = await FlutterProject.detect(last);
      _loadOptions();
    } on Object {
      // 기억해 둔 값은 편의일 뿐이다.
    }
    notifyListeners();
    await Future.wait([refreshDevices(), runDiagnostics(), refreshGit()]);
  }

  Future<bool> openProject(String dir) async {
    final found = await FlutterProject.detect(dir);
    projectError = found == null ? dir : null;
    if (found != null) {
      project = found;
      _loadOptions();
      statuses = const [];
      hint = null;
      await _prefs?.setString(_projectKey, dir);
      // 새 프로젝트가 지금 고른 대상(예: 이 컴퓨터)을 지원하지 않으면 다시 고른다.
      if (device == null) _pickDefaultDevice();
    }
    gitState = null;
    lastGitAction = null;
    lastGitOk = null;
    notifyListeners();
    if (found != null) await Future.wait([runDiagnostics(), refreshGit()]);
    return found != null;
  }

  Future<void> refreshDevices() async {
    loadingDevices = true;
    notifyListeners();
    final found = await deviceService.list();
    devices = found;
    if (device == null) _pickDefaultDevice();
    loadingDevices = false;
    notifyListeners();
  }

  bool isCustomTool(String tool) => runner.toolPaths.containsKey(tool);

  /// [tool]을 실제로 실행하게 될 파일. 찾지 못하면 null.
  Future<String?> locateTool(String tool) => runner.locate(tool);

  /// 도구 위치를 직접 지정한다 (null이면 자동 탐색으로 되돌림). 저장하고 기기·점검을 다시 읽는다.
  Future<void> setToolPath(String tool, String? path) async {
    if (path == null || path.isEmpty) {
      runner.toolPaths.remove(tool);
      await _prefs?.remove('$_toolKeyPrefix$tool');
    } else {
      runner.toolPaths[tool] = path;
      await _prefs?.setString('$_toolKeyPrefix$tool', path);
    }
    // 이전 경로로 읽은 결과("찾지 못함")를 점검이 끝날 때까지 남겨 두지 않는다 — Windows에서는 수십 초 걸린다.
    diagnostics = null;
    notifyListeners();
    await Future.wait([refreshDevices(), runDiagnostics()]);
  }

  void setTab(int i) {
    if (i == tabIndex) return;
    tabIndex = i;
    _prefs?.setInt(_tabKey, i);
  }

  void select(MobileDevice d) {
    selectedId = d.id;
    notifyListeners();
  }

  void _loadOptions() {
    final p = project;
    options = p == null ? const BuildOptions() : BuildOptions.decode(_prefs?.getString('$_optionsKeyPrefix${p.path}'));
  }

  /// 빌드 옵션을 바꾸고 이 프로젝트용으로 저장한다 (비우면 저장된 것도 지운다).
  void setOptions(BuildOptions value) {
    final p = project;
    if (running || value == options) return;
    options = value;
    if (p != null) {
      final key = '$_optionsKeyPrefix${p.path}';
      if (value.isEmpty) {
        _prefs?.remove(key);
      } else {
        _prefs?.setString(key, value.encode());
      }
    }
    notifyListeners();
  }

  void setMode(BuildMode m) {
    mode = m;
    _prefs?.setString(_modeKey, m.name);
    notifyListeners();
  }

  void setTeamId(String value) {
    final v = value.trim().toUpperCase();
    teamId = v.isEmpty ? null : v;
    if (teamId == null) {
      _prefs?.remove(_teamKey);
    } else if (RegExp(r'^[A-Z0-9]{10}$').hasMatch(teamId!)) {
      _prefs?.setString(_teamKey, teamId!);
    }
    notifyListeners();
  }

  /// 계획의 단계를 차례로 실행한다. 하나라도 실패하면 거기서 멈춘다.
  ///
  /// [phase]가 build나 run이면 그 단계들만 실행한다 (release에서 빌드와 실행을 따로 할 때).
  /// 다른 단계의 이전 결과(체크 표시)는 그대로 둔다.
  Future<void> start({RunPhase phase = RunPhase.all}) async {
    final p = plan;
    if (running || !p.runnable) return;
    final indices = p.indicesOf(phase);
    if (indices.isEmpty) return;
    running = true;
    hint = null;
    missingCommand = null;
    if (phase == RunPhase.all || statuses.length != p.steps.length) {
      statuses = List.filled(p.steps.length, StepStatus.pending);
    } else {
      statuses = [...statuses];
      for (final i in indices) {
        statuses[i] = StepStatus.pending;
      }
    }
    final handle = _handle = RunHandle();
    notifyListeners();
    for (final i in indices) {
      final step = p.steps[i];
      statuses[i] = StepStatus.running;
      notifyListeners();
      final r = await runner.run(
        step.args,
        workingDirectory: step.workingDirectory,
        environment: step.environment,
        handle: handle,
        keepStdinOpen: step.interactive,
      );
      if (handle.cancelled) {
        statuses[i] = StepStatus.cancelled;
        break;
      }
      // 계속 실행되는 단계(flutter run)는 사용자가 `q`로 끝내도 정상이다.
      if (r.ok || step.interactive && r.exitCode == 0) {
        statuses[i] = StepStatus.done;
        continue;
      }
      statuses[i] = StepStatus.failed;
      if (r.exitCode == 127) missingCommand = step.args.first;
      hint = explainFailure(r.combined);
      break;
    }
    running = false;
    _handle = null;
    notifyListeners();
  }

  /// 빌드 없이 실행할 수 있는지: release 결과물이 이미 있다.
  bool get artifactReady {
    final a = plan.artifact;
    return a != null && FileSystemEntity.typeSync(a) != FileSystemEntityType.notFound;
  }

  /// 프로젝트 폴더의 git 상태. git 저장소가 아니면 null.
  GitState? gitState;
  bool gitBusy = false;

  /// 마지막 fetch·pull의 결과 (null이면 아직 안 함).
  GitAction? lastGitAction;
  bool? lastGitOk;

  Future<void> refreshGit() async {
    final p = project;
    if (p == null) {
      gitState = null;
      notifyListeners();
      return;
    }
    gitState = await git.status(p.path);
    notifyListeners();
  }

  /// `git fetch --prune`. 명령과 출력은 기록 탭에 남는다.
  Future<bool> gitFetch() => _runGit(GitAction.fetch, git.fetch);

  /// `git pull --ff-only`. 받을 수 있는 상태일 때만 실행한다.
  Future<bool> gitPull() async {
    if (gitState?.canPull != true) return false;
    return _runGit(GitAction.pull, git.pull);
  }

  Future<bool> _runGit(GitAction action, Future<CommandResult> Function(String dir) run) async {
    final p = project;
    if (p == null || gitBusy || running || cleaning) return false;
    gitBusy = true;
    lastGitAction = null;
    lastGitOk = null;
    missingCommand = null;
    notifyListeners();
    final r = await run(p.path);
    if (r.exitCode == 127) missingCommand = 'git';
    lastGitAction = action;
    lastGitOk = r.ok;
    gitBusy = false;
    // pull은 pubspec을 바꿀 수 있다 — 프로젝트 정보(버전·이름)도 다시 읽는다.
    if (action == GitAction.pull && r.ok) {
      final reread = await FlutterProject.detect(p.path);
      if (reread != null) project = reread;
    }
    await refreshGit();
    return r.ok;
  }

  /// 빌드가 알 수 없는 이유로 깨질 때의 처방: `flutter clean` 다음 `flutter pub get`.
  /// 둘 다 성공하면 true. 명령은 기록 탭에도 남는다.
  Future<bool> cleanProject() async {
    final p = project;
    if (p == null || running || cleaning) return false;
    cleaning = true;
    cleanResult = null;
    missingCommand = null;
    hint = null;
    statuses = const [];
    notifyListeners();
    var ok = true;
    for (final args in const [
      ['flutter', 'clean'],
      ['flutter', 'pub', 'get'],
    ]) {
      final r = await runner.run(args, workingDirectory: p.path);
      if (!r.ok) {
        ok = false;
        if (r.exitCode == 127) missingCommand = args.first;
        break;
      }
    }
    cleaning = false;
    cleanResult = ok;
    notifyListeners();
    return ok;
  }

  /// 프로젝트 폴더를 VS Code로 연다. 명령은 기록 탭에도 남는다.
  Future<VsCodeResult> openInVsCode() async {
    final p = project;
    if (p == null) return VsCodeResult.notFound;
    final command = await vscodeCommand(p.path, path: await runner.path);
    if (command == null) return VsCodeResult.notFound;
    final r = await runner.run(command);
    return r.ok ? VsCodeResult.opened : VsCodeResult.failed;
  }

  void cancel() => _handle?.cancel();

  /// 실행 중인 `flutter run`에 키를 보낸다: `r` 핫 리로드, `R` 핫 리스타트, `q` 종료.
  void sendKey(String key) => _handle?.send(key);
}
