import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/command_runner.dart';
import '../core/vscode.dart';
import '../devices/device_service.dart';
import '../doctor/checks.dart';
import '../doctor/diagnostics.dart';
import '../devices/mobile_device.dart';
import '../flutter/flutter_project.dart';
import 'install_plan.dart';

enum VsCodeResult { opened, notFound, failed }

enum StepStatus { pending, running, done, failed, cancelled }

/// 프로젝트·기기·모드를 고르고 계획을 실행하는 화면의 상태.
class InstallController extends ChangeNotifier {
  InstallController({
    required this.runner,
    required this.deviceService,
    this.diagnosticsService,
    this.vscodeCommand = vscodeOpenCommand,
    bool? hostIsMac,
    bool? hostIsWindows,
  }) : hostIsMac = hostIsMac ?? Platform.isMacOS,
       hostIsWindows = hostIsWindows ?? Platform.isWindows;

  /// 이 앱이 도는 OS. 이 컴퓨터를 빌드 대상으로 보여 줄지(데스크톱)와 iOS 설치 가능 여부가 여기에 달렸다.
  final bool hostIsMac;
  final bool hostIsWindows;

  static const _projectKey = 'last_project';
  static const _teamKey = 'ios_team_id';
  static const _modeKey = 'build_mode';
  static const _tabKey = 'last_tab';
  static const _toolKeyPrefix = 'tool_path_';

  /// 사용자가 위치를 지정할 수 있는 도구.
  static const configurableTools = ['flutter', 'adb'];

  final CommandRunner runner;
  final DeviceService deviceService;
  final DiagnosticsService? diagnosticsService;

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

  Diagnostics? diagnostics;
  bool diagnosing = false;

  /// 마지막으로 보던 탭 (0 설치 · 1 기기 · 2 서명 · 3 점검 · 4 기록).
  int tabIndex = 0;

  /// 저장된 탭을 읽었는지 — 화면이 한 번만 그 탭으로 옮긴다.
  bool tabLoaded = false;

  bool running = false;
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
  );

  List<CheckItem> get checks => buildChecks(
    diagnostics: diagnostics,
    project: project,
    device: device,
    teamId: effectiveTeamId,
    hostIsMac: hostIsMac,
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
    } on Object {
      // 기억해 둔 값은 편의일 뿐이다.
    }
    notifyListeners();
    await Future.wait([refreshDevices(), runDiagnostics()]);
  }

  Future<bool> openProject(String dir) async {
    final found = await FlutterProject.detect(dir);
    projectError = found == null ? dir : null;
    if (found != null) {
      project = found;
      statuses = const [];
      hint = null;
      await _prefs?.setString(_projectKey, dir);
      // 새 프로젝트가 지금 고른 대상(예: 이 컴퓨터)을 지원하지 않으면 다시 고른다.
      if (device == null) _pickDefaultDevice();
    }
    notifyListeners();
    if (found != null) await runDiagnostics();
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
  Future<void> start() async {
    final p = plan;
    if (running || !p.runnable) return;
    running = true;
    hint = null;
    missingCommand = null;
    statuses = List.filled(p.steps.length, StepStatus.pending);
    final handle = _handle = RunHandle();
    notifyListeners();
    for (var i = 0; i < p.steps.length; i++) {
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
