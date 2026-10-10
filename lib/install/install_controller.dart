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
  });

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

  MobileDevice? get device {
    for (final d in devices) {
      if (d.id == selectedId) return d;
    }
    return null;
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
    hostIsMac: Platform.isMacOS,
  );

  List<CheckItem> get checks => buildChecks(
    diagnostics: diagnostics,
    project: project,
    device: device,
    teamId: effectiveTeamId,
    hostIsMac: Platform.isMacOS,
    now: DateTime.now(),
  );

  /// 도구·인증서·프로파일·키스토어를 다시 읽는다.
  Future<void> runDiagnostics() async {
    final service = diagnosticsService;
    if (service == null || diagnosing) return;
    diagnosing = true;
    notifyListeners();
    diagnostics = await service.collect(project);
    diagnosing = false;
    notifyListeners();
  }

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
    if (device == null) {
      // 프로젝트가 지원하는 플랫폼의 USB 기기를 먼저 고른다.
      final preferred = found.where((d) => d.isUsb).followedBy(found).firstOrNull;
      selectedId = preferred?.id;
    }
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
