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
import 'package:flutty_dock/install/build_options.dart';
import 'package:flutty_dock/install/install_plan.dart';
import 'package:flutty_dock/l10n/app_localizations.dart';
import 'package:flutty_dock/settings/app_settings.dart';
import 'package:flutty_dock/ui/build_options_section.dart' show flavorDocsUrlFor;
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

Future<void> _pump(
  WidgetTester tester,
  InstallController c, {
  Locale locale = const Locale('en'),
  Size size = const Size(440, 960),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final settings = await AppSettings.load();
  await tester.pumpWidget(
    AppSettingsScope(
      settings: settings,
      child: MaterialApp(
        locale: locale,
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

  /// git이 설치되어 있는지, 그리고 이 저장소의 worktree들.
  bool installed = true;
  List<GitWorktree> trees = const [];

  @override
  Future<GitState?> status(String directory) async => state;

  @override
  Future<bool> available() async => installed;

  @override
  Future<List<GitWorktree>> worktrees(String directory) async => trees;

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

/// Git는 이제 전용 탭에 있다.
Future<void> _openGitTab(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(Tab, 'Git'));
  await tester.pumpAndSettle();
}

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
    expect(c.tabIndex, 4);
    // 저장된 탭이 나중에 도착하면 그 탭으로 옮긴다.
    c
      ..tabIndex = 2
      ..tabLoaded = true;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    c.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.textContaining('No device is connected over USB'), findsOneWidget);
  });

  testWidgets('without a project the banner asks to open one and the six tabs exist', (tester) async {
    await _pump(tester, _controller());
    expect(find.text('Open a Flutter project first'), findsOneWidget);
    for (final t in ['Run', 'Git', 'Devices', 'Signing', 'Doctor', 'Log']) {
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
    // 프로젝트 카드(모든 탭에 보임)에 브랜치와 상태가 글자로 보인다.
    expect(find.text('main'), findsOneWidget);
    expect(find.text('↓ 2 to pull'), findsOneWidget);
    await _openGitTab(tester);
    expect(find.text('main'), findsNWidgets(2), reason: 'the header pill and the Git tab card');
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
    expect(find.text('● Changes'), findsOneWidget, reason: 'visible in the header without opening the Git tab');
    await _openGitTab(tester);
    expect(find.text('Not pulling: there are uncommitted changes'), findsWidgets);
    await tester.ensureVisible(find.text('Pull'));
    await tester.tap(find.text('Pull'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(git.calls, isEmpty);
  });

  testWidgets('the project card stays above every tab and shows the git status in words', (tester) async {
    final git = _FakeGit(const GitState(branch: 'main', upstream: 'origin/main', remoteUrl: 'git@github.com:o/r.git'));
    final c = InstallController(
      runner: CommandRunner(CommandLog()),
      deviceService: _Devices(const []),
      diagnosticsService: _Diag(_diag()),
      gitClient: git,
    )..project = _project;
    await c.refreshGit();
    await _pump(tester, c);
    for (final tab in ['Run', 'Git', 'Devices', 'Signing', 'Doctor', 'Log']) {
      await tester.tap(find.widgetWithText(Tab, tab));
      await tester.pumpAndSettle();
      expect(find.text('app  1.0.0+1'), findsOneWidget, reason: 'project name on the $tab tab');
      expect(find.text('✓ Up to date'), findsOneWidget, reason: 'git status on the $tab tab');
    }
    // 프로젝트 카드의 버튼은 아이콘이고, 이름은 툴팁으로 남는다. 폴더 바꾸기는 타이틀 바 메뉴로 옮겼으니 카드에는 없다.
    expect(find.byTooltip('Open in VS Code'), findsOneWidget);
    expect(find.byTooltip('Reload this project'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open_rounded), findsNothing);
  });

  for (final locale in const [Locale('en'), Locale('ko')]) {
    testWidgets('fits the smallest docked window (380x560) on every tab, ${locale.languageCode}', (tester) async {
      const project = FlutterProject(
        path: 'D:/work/a-rather-long-project-folder-name/app',
        name: 'a_rather_long_project_name',
        version: '12.34.56+789',
        hasIos: true,
        hasAndroid: true,
        hasMacos: true,
        hasWindows: true,
      );
      final git = _FakeGit(
        const GitState(
          branch: 'feature/a-rather-long-branch-name-for-testing',
          upstream: 'origin/feature/a-rather-long-branch-name-for-testing',
          ahead: 3,
          behind: 12,
          dirty: true,
          remoteUrl: 'git@github.com:some-organization/some-repository.git',
        ),
      )..trees = const [
          GitWorktree(path: 'D:/work/a-rather-long-project-folder-name/app', branch: 'feature/a-rather-long-branch-name-for-testing'),
          GitWorktree(path: 'D:/work/other-worktree-with-a-long-name', branch: 'main'),
        ];
      final c = InstallController(
        runner: CommandRunner(CommandLog()),
        deviceService: _Devices(const [_galaxy]),
        diagnosticsService: _Diag(_diag()),
        gitClient: git,
      )
        ..project = project
        ..devices = const [_galaxy]
        ..selectedId = _galaxy.id
        ..mode = BuildMode.release;
      await c.refreshGit();
      await _pump(tester, c, locale: locale, size: const Size(380, 560));
      expect(tester.takeException(), isNull, reason: 'run tab');
      final labels = locale.languageCode == 'ko'
          ? ['실행', 'Git', '기기', '서명', '점검', '기록']
          : ['Run', 'Git', 'Devices', 'Signing', 'Doctor', 'Log'];
      for (final label in labels) {
        await tester.tap(find.widgetWithText(Tab, label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label tab');
      }
    });
  }

  testWidgets('tabs show an icon above the label', (tester) async {
    await _pump(tester, _controller());
    final tab = find.widgetWithText(Tab, 'Devices');
    expect(find.descendant(of: tab, matching: find.byType(Icon)), findsOneWidget);
    final icon = tester.getCenter(find.descendant(of: tab, matching: find.byType(Icon))).dy;
    final label = tester.getCenter(find.descendant(of: tab, matching: find.text('Devices'))).dy;
    expect(icon, lessThan(label));
  });

  testWidgets('the Git tab says why when the folder is not a repository', (tester) async {
    final c = InstallController(
      runner: CommandRunner(CommandLog()),
      deviceService: _Devices(const []),
      diagnosticsService: _Diag(_diag()),
      gitClient: _FakeGit(null),
    )..project = _project;
    await c.refreshGit();
    await _pump(tester, c);
    expect(find.text('✓ Up to date'), findsNothing, reason: 'no git chip in the header either');
    await _openGitTab(tester);
    expect(find.text('This project folder is not a git repository'), findsOneWidget);
    expect(find.text('Fetch'), findsNothing);
    expect(find.textContaining("wasn't found"), findsNothing);
  });

  testWidgets('without git installed the Git card says so', (tester) async {
    final c = InstallController(
      runner: CommandRunner(CommandLog()),
      deviceService: _Devices(const []),
      diagnosticsService: _Diag(_diag()),
      gitClient: _FakeGit(null)..installed = false,
    )..project = _project;
    await c.refreshGit();
    expect(c.gitMissing, isTrue);
    await _pump(tester, c);
    await _openGitTab(tester);
    expect(find.text("The git command wasn't found. Install it and make sure it is on PATH"), findsOneWidget);
    expect(find.text('This project folder is not a git repository'), findsNothing);
    expect(find.text('Fetch'), findsNothing);
  });

  testWidgets('the worktree picker appears only when there is more than one worktree', (tester) async {
    InstallController make(List<GitWorktree> trees) => InstallController(
      runner: CommandRunner(CommandLog()),
      deviceService: _Devices(const []),
      diagnosticsService: _Diag(_diag()),
      gitClient: _FakeGit(
        const GitState(branch: 'main', upstream: 'origin/main', remoteUrl: 'git@github.com:o/r.git'),
      )..trees = trees,
    )..project = _project;

    final one = make(const [GitWorktree(path: '/p/app', branch: 'main')]);
    await one.refreshGit();
    await _pump(tester, one);
    await _openGitTab(tester);
    expect(find.text('Worktree'), findsNothing);

    final many = make(const [
      GitWorktree(path: '/p/app', branch: 'main'),
      GitWorktree(path: '/p/app-feature', branch: 'feature/x'),
    ]);
    await many.refreshGit();
    await _pump(tester, many);
    await _openGitTab(tester);
    expect(find.text('Worktree'), findsOneWidget);
    expect(many.currentWorktree?.branch, 'main');
    // 현재 항목이 칸에 보인다.
    expect(find.textContaining('main  ·  app'), findsWidgets);
  });

  testWidgets('the clean button sits at the top of the commands card, above the first step', (tester) async {
    final c = _controller()
      ..project = _project
      ..devices = const [_galaxy]
      ..selectedId = _galaxy.id
      ..mode = BuildMode.release;
    await _pump(tester, c);
    final clean = find.text('Clean & get packages');
    expect(clean, findsOneWidget);
    expect(tester.getTopLeft(clean).dy, lessThan(tester.getTopLeft(find.textContaining('1. ')).dy));
    // 같은 카드 안에 있다 — 단계 목록과 같은 Card의 자손이다.
    expect(find.descendant(of: find.byType(Card), matching: clean), findsOneWidget);
    expect(find.descendant(of: find.byType(Card), matching: find.textContaining('1. ')), findsOneWidget);
  });

  testWidgets('without steps (no device yet) the clean button is still offered on its own', (tester) async {
    final c = _controller()..project = _project;
    await _pump(tester, c);
    expect(c.plan.steps, isEmpty);
    expect(find.text('Clean & get packages'), findsOneWidget);
  });

  testWidgets('build options start collapsed and typing a flavor shows up in the command', (tester) async {
    final c = _controller()
      ..project = _project
      ..devices = const [_galaxy]
      ..selectedId = _galaxy.id
      ..mode = BuildMode.release;
    await _pump(tester, c);
    expect(find.text('Build options'), findsOneWidget);
    expect(find.text('Defaults'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Flavor'), findsNothing, reason: 'collapsed');

    await tester.tap(find.text('Build options'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Flavor'), 'dev');
    await tester.pumpAndSettle();
    expect(c.options.flavor, 'dev');
    expect(find.textContaining('flutter build apk --release --flavor dev'), findsWidgets);
    expect(find.text('Clear options'), findsOneWidget);

    await tester.tap(find.text('Clear options'));
    await tester.pumpAndSettle();
    expect(c.options.isEmpty, isTrue);
    // (입력칸의 도움말에도 '--flavor'가 있으므로 명령 줄로 좁혀서 본다.)
    expect(find.textContaining('flutter build apk --release --flavor'), findsNothing);
    expect(find.textContaining('flutter build apk --release'), findsOneWidget);
  });

  testWidgets('a Help button sits next to the build options title, visible while collapsed', (tester) async {
    final c = _controller()..project = _project;
    await _pump(tester, c);
    final help = find.widgetWithText(TextButton, 'Help');
    expect(help, findsOneWidget);
    expect(find.widgetWithText(TextField, 'Flavor'), findsNothing, reason: 'still collapsed');
    // 제목 바로 옆에 있다 (같은 줄).
    expect((tester.getCenter(help).dy - tester.getCenter(find.text('Build options')).dy).abs(), lessThan(12));
  });

  test('the help page follows the selected target', () {
    String page(DevicePlatform? p) => flavorDocsUrlFor(p).toString();
    expect(page(DevicePlatform.android), 'https://docs.flutter.dev/deployment/flavors');
    expect(page(DevicePlatform.ios), 'https://docs.flutter.dev/deployment/flavors-ios');
    expect(page(DevicePlatform.macos), 'https://docs.flutter.dev/deployment/flavors-ios');
    expect(page(DevicePlatform.windows), 'https://docs.flutter.dev/deployment/flavors-windows');
    expect(page(null), 'https://docs.flutter.dev/deployment/flavors');
  });

  testWidgets('an invalid flavor is flagged and not used', (tester) async {
    final c = _controller()
      ..project = _project
      ..devices = const [_galaxy]
      ..selectedId = _galaxy.id
      ..mode = BuildMode.release
      ..options = const BuildOptions(flavor: 'dev;x');
    await _pump(tester, c);
    expect(find.text('Start with a letter; letters, digits, _ and - only'), findsOneWidget);
    expect(find.textContaining('--flavor'), findsNothing);
  });

  testWidgets('a desktop target runs, a phone gets installed', (tester) async {
    const winProject = FlutterProject(
      path: '/p/app',
      name: 'app',
      hasIos: false,
      hasAndroid: false,
      hasWindows: true,
      windowsBinaryName: 'app',
    );
    final c = InstallController(
      runner: CommandRunner(CommandLog()),
      deviceService: _Devices(const []),
      diagnosticsService: _Diag(_diag()),
      hostIsMac: false,
      hostIsWindows: true,
    )
      ..project = winProject
      ..selectedId = 'windows'
      ..mode = BuildMode.release;
    expect(c.device?.isDesktop, isTrue);
    await _pump(tester, c);
    expect(find.text('Build & run'), findsOneWidget);
    expect(find.text('Run only'), findsOneWidget);
    expect(find.text('Build & install'), findsNothing);
    expect(find.text('Install only'), findsNothing);
  });

  testWidgets('release offers Build & install, Build only and Install only (disabled until a build exists)', (tester) async {
    final c = _controller()
      ..project = _project
      ..devices = const [_galaxy]
      ..selectedId = _galaxy.id
      ..mode = BuildMode.release;
    await _pump(tester, c);
    expect(find.text('Build & install'), findsOneWidget);
    expect(find.text('Build only'), findsOneWidget);
    final runOnly = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Install only'));
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
