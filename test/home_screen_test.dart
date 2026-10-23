import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
import 'package:flutty_dock/core/git_client.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/doctor/diagnostics.dart';
import 'package:flutty_dock/doctor/signing_info.dart';
import 'package:flutty_dock/flutter/flutter_project.dart';
import 'package:flutty_dock/install/install_controller.dart';
import 'package:flutty_dock/install/install_plan.dart';
import 'package:flutty_dock/l10n/app_localizations.dart';
import 'package:flutty_dock/settings/app_settings.dart';
import 'package:flutty_dock/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Devices implements DeviceService {
  _Devices(this.devices);
  final List<MobileDevice> devices;
  @override
  Future<List<MobileDevice>> list() async => devices;
}

class _Diag implements DiagnosticsService {
  _Diag(this.d);
  final Diagnostics d;
  @override
  Future<Diagnostics> collect(FlutterProject? project) async => d;
}

const _project = FlutterProject(
  path: '/p/app',
  name: 'app',
  version: '1.0.0+1',
  hasIos: true,
  hasAndroid: true,
  iosBundleId: 'art.zoomon.app',
  androidApplicationId: 'art.zoomon.app',
);

const _wireless = MobileDevice(
  id: 'W',
  name: 'My iPhone',
  platform: DevicePlatform.ios,
  link: DeviceLink.wireless,
  developerModeOn: true,
);

Diagnostics _diag({List<SigningCert> certs = const []}) => Diagnostics(
  flutter: const ToolInfo('3.47.1'),
  xcode: const ToolInfo('27.0'),
  adb: const ToolInfo('1.0.41'),
  certs: certs,
  collectedAt: DateTime(2026, 10, 10, 9, 30),
);

Future<void> _pump(WidgetTester tester, InstallController c) async {
  tester.view.physicalSize = const Size(440, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final settings = await AppSettings.load();
  await tester.pumpWidget(
    AppSettingsScope(
      settings: settings,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(controller: c, log: CommandLog(), onAbout: () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeGit extends GitClient {
  _FakeGit(this.state) : super(CommandRunner(CommandLog()));
  GitState? state;
  final calls = <String>[];

  @override
  Future<GitState?> status(String directory) async => state;

  @override
  Future<CommandResult> fetch(String directory) async {
    calls.add('fetch');
    return const CommandResult(0, '', '');
  }

  @override
  Future<CommandResult> pull(String directory) async {
    calls.add('pull');
    state = const GitState(branch: 'main', upstream: 'origin/main', remoteUrl: 'git@github.com:o/r.git');
    return const CommandResult(0, '', '');
  }
}

const _galaxy = MobileDevice(id: 'R3CY', name: 'SM S931N', platform: DevicePlatform.android, link: DeviceLink.usb);

InstallController _controller({List<MobileDevice> devices = const [], Diagnostics? diag}) {
  final runner = CommandRunner(CommandLog());
  return InstallController(
    runner: runner,
    deviceService: _Devices(devices),
    diagnosticsService: _Diag(diag ?? _diag()),
  );
}

void main() {
  testWidgets('remembers the selected tab and restores it after init loaded the saved one', (tester) async {
    final c = _controller();
    await _pump(tester, c);
    await tester.tap(find.widgetWithText(Tab, 'Doctor'));
    await tester.pumpAndSettle();
    expect(c.tabIndex, 3);
    // 저장된 탭이 나중에 도착하면 그 탭으로 옮긴다.
    c
      ..tabIndex = 1
      ..tabLoaded = true;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    c.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.textContaining('No device is connected over USB'), findsOneWidget);
  });

  testWidgets('without a project the banner asks to open one and the five tabs exist', (tester) async {
    await _pump(tester, _controller());
    expect(find.text('Open a Flutter project first'), findsOneWidget);
    for (final t in ['Run', 'Devices', 'Signing', 'Doctor', 'Log']) {
      expect(find.widgetWithText(Tab, t), findsOneWidget);
    }
  });

  testWidgets('a wireless iPhone makes the banner explain the USB steps', (tester) async {
    final c = _controller(devices: [_wireless])
      ..project = _project
      ..devices = [_wireless]
      ..selectedId = 'W';
    await c.runDiagnostics();
    await _pump(tester, c);
    expect(find.textContaining('connected wirelessly'), findsWidgets);
    await tester.tap(find.text('Show how to fix'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Connect the iPhone'), findsOneWidget);
  });

  testWidgets('the Doctor tab lists checks, and a missing certificate offers steps', (tester) async {
    final c = _controller()..project = _project;
    await c.runDiagnostics();
    await _pump(tester, c);
    await tester.tap(find.widgetWithText(Tab, 'Doctor'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter 3.47.1'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(find.text('No usable Apple Development certificate'), findsOneWidget);
  });

  testWidgets('the Signing tab shows certificates and lets you pick the team', (tester) async {
    final cert = SigningCert(
      name: 'Apple Development: A (X)',
      teamId: '6N35L95QS4',
      expires: DateTime.now().add(const Duration(days: 200)),
      hasPrivateKey: true,
    );
    final c = _controller(diag: _diag(certs: [cert]))..project = _project;
    await c.runDiagnostics();
    await _pump(tester, c);
    await tester.tap(find.widgetWithText(Tab, 'Signing'));
    await tester.pumpAndSettle();
    expect(find.text('Apple Development: A (X)'), findsOneWidget);
    expect(c.effectiveTeamId, '6N35L95QS4'); // the only usable team is picked automatically
    await tester.tap(find.widgetWithText(ChoiceChip, '6N35L95QS4'));
    await tester.pumpAndSettle();
    expect(c.teamId, '6N35L95QS4');
  });

  testWidgets('the Git section shows branch, remote link and lets you fetch and pull', (tester) async {
    final git = _FakeGit(
      const GitState(branch: 'main', upstream: 'origin/main', behind: 2, remoteUrl: 'git@github.com:o/r.git'),
    );
    final c = InstallController(
      runner: CommandRunner(CommandLog()),
      deviceService: _Devices(const []),
      diagnosticsService: _Diag(_diag()),
      gitClient: git,
    )..project = _project;
    await c.refreshGit();
    await _pump(tester, c);
    expect(find.text('main'), findsOneWidget);
    expect(find.text('github.com/o/r'), findsOneWidget);
    expect(find.text('2 behind the remote'), findsOneWidget);

    await tester.ensureVisible(find.text('Fetch'));
    await tester.tap(find.text('Fetch'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pull'));
    await tester.tap(find.text('Pull'));
    await tester.pumpAndSettle();
    expect(git.calls, ['fetch', 'pull']);
    expect(find.text('Pulled'), findsOneWidget);
    // pull 뒤 상태 갱신(앞섬·뒤처짐)은 컨트롤러 테스트에서 확인한다 — 위젯 테스트의 가짜 시계에서는
    // 실제 파일 읽기(프로젝트 다시 읽기)가 끝나지 않는다.
  });

  testWidgets('pull is disabled while there are uncommitted changes', (tester) async {
    final git = _FakeGit(
      const GitState(branch: 'main', upstream: 'origin/main', behind: 1, dirty: true, remoteUrl: 'git@github.com:o/r.git'),
    );
    final c = InstallController(
      runner: CommandRunner(CommandLog()),
      deviceService: _Devices(const []),
      diagnosticsService: _Diag(_diag()),
      gitClient: git,
    )..project = _project;
    await c.refreshGit();
    await _pump(tester, c);
    expect(find.text('Not pulling: there are uncommitted changes'), findsWidgets);
    await tester.ensureVisible(find.text('Pull'));
    await tester.tap(find.text('Pull'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(git.calls, isEmpty);
  });

  testWidgets('no Git section when the folder is not a repository', (tester) async {
    final c = InstallController(
      runner: CommandRunner(CommandLog()),
      deviceService: _Devices(const []),
      diagnosticsService: _Diag(_diag()),
      gitClient: _FakeGit(null),
    )..project = _project;
    await c.refreshGit();
    await _pump(tester, c);
    expect(find.text('Fetch'), findsNothing);
  });

  testWidgets('release offers Build & run, Build only and Run only (disabled until a build exists)', (tester) async {
    final c = _controller()
      ..project = _project
      ..devices = const [_galaxy]
      ..selectedId = _galaxy.id
      ..mode = BuildMode.release;
    await _pump(tester, c);
    expect(find.text('Build & run'), findsOneWidget);
    expect(find.text('Build only'), findsOneWidget);
    final runOnly = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Run only'));
    expect(runOnly.onPressed, isNull, reason: '/p/app has no APK');
    final buildOnly = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Build only'));
    expect(buildOnly.onPressed, isNotNull);

    c.mode = BuildMode.debug;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    c.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Build only'), findsNothing);
    expect(find.text('Run debug'), findsOneWidget);
  });
}
