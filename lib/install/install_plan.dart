import '../core/command_log.dart';
import '../devices/mobile_device.dart';
import '../flutter/flutter_project.dart';
import 'build_options.dart';

enum BuildMode { debug, release }

/// 단계의 역할 — 화면의 이름과 진행바가 이 값을 쓴다.
enum StepKind { prepare, build, install, launch, run }

/// 계획을 어디까지 실행할지. release는 빌드와 실행을 따로 할 수 있다.
enum RunPhase { all, build, run }

/// 실행할 명령 한 개. 화면에 보이는 명령과 실제로 실행하는 명령이 같다.
class PlanStep {
  const PlanStep(this.kind, this.args, {this.workingDirectory, this.environment = const {}});

  final StepKind kind;
  final List<String> args;
  final String? workingDirectory;

  /// 이 명령에만 더하는 환경 변수. 화면의 명령에도 `NAME=값` 접두어로 보인다.
  final Map<String, String> environment;

  /// 터미널에 붙여 넣어 그대로 실행할 수 있는 한 줄.
  String get commandLine =>
      [for (final e in environment.entries) '${e.key}=${e.value}', formatCommandLine(args)].join(' ');

  /// 계속 실행되는 단계(`flutter run`): 끝나는 것이 아니라 사용자가 멈춘다.
  bool get interactive => kind == StepKind.run;

  /// 빌드 단계(준비·빌드)인지, 기기에서 실행하는 단계(올리기·열기·`flutter run`)인지.
  RunPhase get phase => switch (kind) {
    StepKind.prepare || StepKind.build => RunPhase.build,
    StepKind.install || StepKind.launch || StepKind.run => RunPhase.run,
  };
}

/// 계획을 세울 수 없거나 실행해도 실패할 이유 — 실행 전에 알려 준다.
enum Blocker {
  noProject,
  noDevice,
  platformMissing,
  iosNeedsMac,
  wireless,
  developerModeOff,
  androidUnauthorized,
  needsTeamId,
}

class InstallPlan {
  const InstallPlan(this.steps, this.blockers, {this.artifact});

  final List<PlanStep> steps;
  final List<Blocker> blockers;

  /// release 빌드가 만드는 결과물의 경로(`Runner.app`, `app-release.apk`, `.exe`). 빌드 없이 실행하려면 이게 있어야 한다.
  final String? artifact;

  /// [phase]에 해당하는 단계들의 위치(전체 계획 안에서).
  List<int> indicesOf(RunPhase phase) => [
    for (var i = 0; i < steps.length; i++)
      if (phase == RunPhase.all || steps[i].phase == phase) i,
  ];

  /// 빌드와 실행을 따로 할 수 있는지 — 두 단계가 모두 있을 때만.
  bool get splittable => indicesOf(RunPhase.build).isNotEmpty && indicesOf(RunPhase.run).isNotEmpty;

  bool get runnable => blockers.isEmpty && steps.isNotEmpty;
}

/// Phase 0에서 이 Mac(Flutter 3.47, Xcode 27)으로 검증한 명령 순서.
///
/// - 프로젝트 파일을 고치지 않는다. 서명 Team은 `xcodebuild` 인자로 넘긴다.
/// - iOS release: `flutter build ios --config-only`로 준비 → 서명 빌드 → `devicectl install`.
///   TestFlight 없이 development 서명 release가 실기기에 직접 설치된다.
/// - debug는 `flutter run`이다 — iOS 14+ debug 빌드는 홈 화면에서 실행되지 않고 Flutter가 붙어야 한다.
InstallPlan buildInstallPlan({
  required FlutterProject? project,
  required MobileDevice? device,
  required BuildMode mode,
  required String? teamId,
  required bool hostIsMac,
  String windowsArch = 'x64',
  BuildOptions options = const BuildOptions(),
}) {
  if (project == null) return const InstallPlan([], [Blocker.noProject]);
  if (device == null) return const InstallPlan([], [Blocker.noDevice]);
  final blockers = <Blocker>[];
  final steps = <PlanStep>[];
  String? artifact;
  final dir = project.path;
  // flavor는 Windows에서 쓸 수 없다. 나머지 옵션(-t, dart-define, 추가 인자)은 모든 대상에 붙는다.
  final flavorOk = device.platform != DevicePlatform.windows;
  final flavor = flavorOk ? options.validFlavor : '';
  final flags = options.flutterArgs(flavorSupported: flavorOk);
  // flavor가 있으면 Flutter 규칙대로 scheme은 flavor 이름, configuration은 `Release-<flavor>`.
  final releaseConfig = flavor.isEmpty ? 'Release' : 'Release-$flavor';

  if (device.platform == DevicePlatform.ios) {
    if (!project.hasIos) blockers.add(Blocker.platformMissing);
    if (!hostIsMac) blockers.add(Blocker.iosNeedsMac);
    if (!device.isUsb) blockers.add(Blocker.wireless);
    if (device.developerModeOn == false) blockers.add(Blocker.developerModeOff);
    final team = teamId ?? project.iosTeamId;
    if (team == null || team.isEmpty) blockers.add(Blocker.needsTeamId);

    if (mode == BuildMode.debug) {
      // flutter run은 xcodebuild 인자를 받지 않는다. 대신 `FLUTTER_XCODE_` 접두어 환경 변수가
      // xcodebuild 빌드 설정으로 전달되므로 프로젝트를 고치지 않고 Team을 넘길 수 있다.
      steps.add(
        PlanStep(
          StepKind.run,
          ['flutter', 'run', '-d', device.id, '--debug', ...flags],
          workingDirectory: dir,
          environment: {
            if (team != null && team.isNotEmpty) ...{
              'FLUTTER_XCODE_DEVELOPMENT_TEAM': team,
              'FLUTTER_XCODE_CODE_SIGN_STYLE': 'Automatic',
            },
          },
        ),
      );
    } else {
      final config = releaseConfig;
      final app = '$dir/build/ios_dd/Build/Products/$config-iphoneos/Runner.app';
      artifact = app;
      steps.addAll([
        PlanStep(StepKind.prepare, [
          'flutter',
          'build',
          'ios',
          '--release',
          '--config-only',
          '--no-codesign',
          ...flags,
        ], workingDirectory: dir),
        PlanStep(StepKind.build, [
          'xcodebuild',
          '-workspace',
          'Runner.xcworkspace',
          '-scheme',
          flavor.isEmpty ? 'Runner' : flavor,
          '-configuration',
          config,
          '-destination',
          'generic/platform=iOS',
          '-derivedDataPath',
          '../build/ios_dd',
          '-allowProvisioningUpdates',
          'DEVELOPMENT_TEAM=${team ?? '<TEAM_ID>'}',
          'CODE_SIGN_STYLE=Automatic',
          'build',
        ], workingDirectory: '$dir/ios'),
        PlanStep(StepKind.install, ['xcrun', 'devicectl', 'device', 'install', 'app', '--device', device.id, app]),
        if (options.appIdOr(project.iosBundleId) != null)
          PlanStep(StepKind.launch, [
            'xcrun',
            'devicectl',
            'device',
            'process',
            'launch',
            '--device',
            device.id,
            options.appIdOr(project.iosBundleId)!,
          ]),
      ]);
    }
  } else if (device.platform == DevicePlatform.macos) {
    // 이 컴퓨터(Mac)의 데스크톱 빌드 — 프로젝트에 macos/가 이미 있을 때만. 설치할 곳이 따로 없어서 빌드하고 연다.
    if (!project.hasMacos) blockers.add(Blocker.platformMissing);
    if (mode == BuildMode.debug) {
      steps.add(PlanStep(StepKind.run, ['flutter', 'run', '-d', 'macos', '--debug', ...flags], workingDirectory: dir));
    } else {
      if (project.macosAppName != null) {
        artifact = '$dir/build/macos/Build/Products/$releaseConfig/${project.macosAppName}.app';
      }
      steps.addAll([
        PlanStep(StepKind.build, ['flutter', 'build', 'macos', '--release', ...flags], workingDirectory: dir),
        if (project.macosAppName != null)
          PlanStep(StepKind.launch, ['open', '$dir/build/macos/Build/Products/$releaseConfig/${project.macosAppName}.app']),
      ]);
    }
  } else if (device.platform == DevicePlatform.windows) {
    // Windows PC의 데스크톱 빌드. 산출물은 build\windows\<아키텍처>\runner\Release\<BINARY_NAME>.exe.
    // explorer.exe는 실행하고 바로 돌아온다 (앱이 끝날 때까지 이 단계가 붙잡히지 않는다).
    if (!project.hasWindows) blockers.add(Blocker.platformMissing);
    if (mode == BuildMode.debug) {
      steps.add(PlanStep(StepKind.run, ['flutter', 'run', '-d', 'windows', '--debug', ...flags], workingDirectory: dir));
    } else {
      if (project.windowsBinaryName != null) {
        artifact = '$dir\\build\\windows\\$windowsArch\\runner\\Release\\${project.windowsBinaryName}.exe';
      }
      steps.addAll([
        PlanStep(StepKind.build, ['flutter', 'build', 'windows', '--release', ...flags], workingDirectory: dir),
        if (project.windowsBinaryName != null)
          PlanStep(StepKind.launch, [
            'explorer.exe',
            '$dir\\build\\windows\\$windowsArch\\runner\\Release\\${project.windowsBinaryName}.exe',
          ]),
      ]);
    }
  } else {
    if (!project.hasAndroid) blockers.add(Blocker.platformMissing);
    if (!device.authorized) blockers.add(Blocker.androidUnauthorized);
    if (mode == BuildMode.debug) {
      steps.add(PlanStep(StepKind.run, ['flutter', 'run', '-d', device.id, '--debug', ...flags], workingDirectory: dir));
    } else {
      // flavor가 있으면 APK 이름에 들어간다: app-<flavor>-release.apk.
      final apk = '$dir/build/app/outputs/flutter-apk/${flavor.isEmpty ? 'app-release' : 'app-$flavor-release'}.apk';
      artifact = apk;
      steps.addAll([
        PlanStep(StepKind.build, ['flutter', 'build', 'apk', '--release', ...flags], workingDirectory: dir),
        PlanStep(StepKind.install, [
          'adb',
          '-s',
          device.id,
          'install',
          '-r',
          apk,
        ]),
        if (options.appIdOr(project.androidApplicationId) != null)
          PlanStep(StepKind.launch, [
            'adb',
            '-s',
            device.id,
            'shell',
            'monkey',
            '-p',
            options.appIdOr(project.androidApplicationId)!,
            '-c',
            'android.intent.category.LAUNCHER',
            '1',
          ]),
      ]);
    }
  }
  return InstallPlan(steps, blockers, artifact: artifact);
}

/// 실패한 출력에서 흔한 원인을 찾는다. 모르면 null (원문 로그를 그대로 보여 준다).
enum FailureHint { useUsb, unlockDevice, developerMode, signing, trustComputer, noAdb, cocoapods, visualStudio, restartApp }

FailureHint? explainFailure(String output) {
  final o = output.toLowerCase();
  // 일부 환경에서 첫 빌드가 플러그인 링크(`.plugin_symlinks`)를 못 찾고 실패한다 — 앱을 다시 열면 된다.
  // CMake가 긴 줄을 접어 쓰므로 줄바꿈·들여쓰기를 공백 하나로 모아서 찾는다.
  final flat = o.replaceAll(RegExp(r'\s+'), ' ');
  // Windows 빌드의 `.plugin_symlinks/<플러그인>/windows`만 — Linux 빌드의 같은 문장은 해당하지 않는다.
  if (RegExp(r'\.plugin_symlinks/[^/\s"]+/windows').hasMatch(flat) && flat.contains('not an existing directory')) {
    return FailureHint.restartApp;
  }
  if (o.contains('connection reset by peer') || o.contains('controlchannelconnectionerror')) return FailureHint.useUsb;
  if (o.contains('device is locked') || o.contains('is locked')) return FailureHint.unlockDevice;
  if (o.contains('developer mode')) return FailureHint.developerMode;
  if (o.contains('no profiles for') ||
      o.contains('provisioning profile') ||
      o.contains('requires a development team')) {
    return FailureHint.signing;
  }
  if (o.contains('not trusted') || o.contains('trust this computer')) return FailureHint.trustComputer;
  // 데스크톱 빌드 도구: macOS는 CocoaPods, Windows는 Visual Studio(C++ 데스크톱 개발).
  if (o.contains('cocoapods not installed') || o.contains('cocoapods is not installed')) return FailureHint.cocoapods;
  if (o.contains('unable to find suitable visual studio') || o.contains('visual studio')) {
    return FailureHint.visualStudio;
  }
  if (o.contains('adb: command not found') || o.contains('adb') && o.contains('no such file')) return FailureHint.noAdb;
  return null;
}
