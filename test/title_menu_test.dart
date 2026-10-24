import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
import 'package:flutty_dock/core/git_client.dart';
import 'package:flutty_dock/core/window_bounds.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/install/install_controller.dart';
import 'package:flutty_dock/l10n/app_localizations.dart';
import 'package:flutty_dock/settings/app_settings.dart';
import 'package:flutty_dock/ui/home_screen.dart';
import 'package:flutty_dock/ui/project_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoDevices implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [];
}

/// 실제 git을 실행하지 않는다 (이 테스트들은 git과 상관없다).
class _NoGit extends GitClient {
  _NoGit() : super(CommandRunner(CommandLog()));

  @override
  Future<GitState?> status(String directory) async => null;

  @override
  Future<bool> available() async => true;

  @override
  Future<List<GitWorktree>> worktrees(String directory) async => const [];
}

InstallController _controller() => InstallController(
  runner: CommandRunner(CommandLog()),
  deviceService: _NoDevices(),
  gitClient: _NoGit(),
  hostIsMac: false,
  hostIsWindows: false,
);

void main() {
  group('docking geometry', () {
    const work = ui.Rect.fromLTWH(0, 0, 1920, 1040); // 작업 표시줄을 뺀 영역

    test('right edge: full height, flush with the right side', () {
      final r = dockedBounds(work, side: DockSide.right, width: 440);
      expect((r.left, r.top, r.width, r.height), (1480.0, 0.0, 440.0, 1040.0));
      expect(r.right, work.right);
    });

    test('left edge: flush with the left side', () {
      final r = dockedBounds(work, side: DockSide.left, width: 440);
      expect((r.left, r.top, r.width, r.height), (0.0, 0.0, 440.0, 1040.0));
    });

    test('keeps the work area origin (second monitor, taskbar on top)', () {
      const second = ui.Rect.fromLTWH(1920, 40, 2560, 1400);
      final r = dockedBounds(second, side: DockSide.right, width: 500);
      expect(r.left, 1920 + 2560 - 500);
      expect(r.top, 40);
      expect(r.height, 1400);
    });

    test('width falls back to the default and is kept within the docking limits', () {
      expect(dockedBounds(work, side: DockSide.right).width, dockDefaultSize.width);
      expect(dockedBounds(work, side: DockSide.right, width: 100).width, dockMinimumSize.width);
      const narrow = ui.Rect.fromLTWH(0, 0, 300, 800);
      expect(dockedBounds(narrow, side: DockSide.left, width: 440).width, 300, reason: 'never wider than the screen');
    });
  });

  group('recent projects', () {
    late Directory root;
    late List<Directory> dirs;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      root = Directory.systemTemp.createTempSync('flutty_recent');
      dirs = [
        for (var i = 0; i < 10; i++)
          Directory('${root.path}/app$i')
            ..createSync()
            ..let((d) => File('${d.path}/pubspec.yaml').writeAsStringSync('name: app$i\ndependencies:\n  flutter:\n    sdk: flutter\n')),
      ];
    });

    tearDown(() => root.deleteSync(recursive: true));

    test('the most recent project comes first; reopening moves it to the front without a duplicate', () async {
      final c = _controller();
      await c.init();
      await c.openProject(dirs[0].path);
      await c.openProject(dirs[1].path);
      await c.openProject(dirs[2].path);
      expect(c.recentProjects, [dirs[2].path, dirs[1].path, dirs[0].path]);
      await c.openProject(dirs[0].path);
      expect(c.recentProjects, [dirs[0].path, dirs[2].path, dirs[1].path]);
    });

    test('the same folder written with other slashes counts once', () async {
      final c = _controller();
      await c.init();
      await c.openProject(dirs[0].path);
      await c.openProject(dirs[0].path.replaceAll('\\', '/'));
      await c.openProject('${dirs[0].path.replaceAll('\\', '/')}/');
      expect(c.recentProjects, hasLength(1));
    });

    test('keeps only the latest ${InstallController.maxRecent}', () async {
      final c = _controller();
      await c.init();
      for (final d in dirs) {
        await c.openProject(d.path);
      }
      expect(c.recentProjects, hasLength(InstallController.maxRecent));
      expect(c.recentProjects.first, dirs.last.path);
      expect(c.recentProjects, isNot(contains(dirs.first.path)));
    });

    test('a folder that is not a Flutter project is not remembered', () async {
      final plain = Directory('${root.path}/plain')..createSync();
      final c = _controller();
      await c.init();
      expect(await c.openProject(plain.path), isFalse);
      expect(c.recentProjects, isEmpty);
    });

    test('the history survives a restart; the project open before the history existed is seeded', () async {
      final c = _controller();
      await c.init();
      await c.openProject(dirs[0].path);
      await c.openProject(dirs[1].path);
      final again = _controller();
      await again.init();
      expect(again.recentProjects, [dirs[1].path, dirs[0].path]);

      SharedPreferences.setMockInitialValues({'last_project': dirs[3].path});
      final old = _controller();
      await old.init();
      expect(old.recentProjects, [dirs[3].path]);
    });
  });

  group('title menu', () {
    late Directory root;
    late Directory a;
    late Directory b;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      root = Directory.systemTemp.createTempSync('flutty_menu');
      Directory make(String n) {
        final d = Directory('${root.path}/$n')..createSync();
        File('${d.path}/pubspec.yaml').writeAsStringSync('name: $n\ndependencies:\n  flutter:\n    sdk: flutter\n');
        return d;
      }

      a = make('alpha');
      b = make('beta');
    });

    tearDown(() => root.deleteSync(recursive: true));

    /// 프로젝트를 여는 일(파일 읽기)은 실제 시계에서 끝낸다.
    Future<InstallController> opened(WidgetTester tester, List<Directory> dirs) async {
      final c = _controller();
      await tester.runAsync(() async {
        await c.init();
        for (final d in dirs) {
          await c.openProject(d.path);
        }
      });
      return c;
    }

    Future<void> pumpMenu(
      WidgetTester tester,
      InstallController c, {
      VoidCallback? onOpenFolder,
      Future<void> Function(DockSide)? onDock,
    }) async {
      tester.view.physicalSize = const Size(440, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final settings = await AppSettings.load();
      await tester.pumpWidget(
        AppSettingsScope(
          settings: settings,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              appBar: AppBar(
                title: ProjectMenuButton(
                  controller: c,
                  onOpenFolder: onOpenFolder ?? () {},
                  onDock: onDock ?? (_) async {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the title is the project name with a dropdown, or the app name without a project', (tester) async {
      await pumpMenu(tester, _controller());
      expect(find.text('Flutty Dock'), findsOneWidget);
      final c = await opened(tester, [a]);
      await pumpMenu(tester, c);
      expect(find.text('alpha'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down_rounded), findsOneWidget);
    });

    testWidgets('lists recent projects, marks the current one, and reopens a project when picked', (tester) async {
      final c = await opened(tester, [a, b]);
      await pumpMenu(tester, c);
      await tester.tap(find.byType(ProjectMenuButton));
      await tester.pumpAndSettle();
      expect(find.text('Recent projects'), findsOneWidget);
      expect(find.text('alpha'), findsOneWidget);
      expect(find.text('beta'), findsNWidgets(2), reason: 'the title and the list entry');
      expect(find.byIcon(Icons.check_rounded), findsOneWidget, reason: 'the open project is checked');

      await tester.tap(find.text('alpha'));
      await tester.pumpAndSettle(); // 메뉴가 닫히면서 선택이 전달된다
      // 선택 처리는 가짜 시계 안에서 시작됐지만 파일 읽기는 실제 시계에서 끝난다 — 번갈아 진행시킨다.
      // (프로젝트를 읽는 파일 작업이 여러 번 이어지므로 넉넉히 돌린다.)
      for (var i = 0; i < 40 && c.project?.name != 'alpha'; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump();
      }
      expect(c.project?.name, 'alpha');
      expect(c.recentProjects.first, a.path, reason: 'the picked project moves to the front');
    });

    testWidgets('folders that no longer exist are left out; an empty history says so', (tester) async {
      final c = await opened(tester, [a, b]);
      b.deleteSync(recursive: true);
      await pumpMenu(tester, c);
      await tester.tap(find.byType(ProjectMenuButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('beta'), findsNWidgets(1), reason: 'only the (stale) title, not the list');

      final fresh = _controller();
      await pumpMenu(tester, fresh);
      await tester.tapAt(const Offset(10, 700)); // 메뉴 닫기
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProjectMenuButton));
      await tester.pumpAndSettle();
      expect(find.text('No project opened yet'), findsOneWidget);
    });

    testWidgets('Open another folder shows the shortcut and calls back', (tester) async {
      var opened = 0;
      await pumpMenu(tester, _controller(), onOpenFolder: () => opened++);
      await tester.tap(find.byType(ProjectMenuButton));
      await tester.pumpAndSettle();
      expect(find.text('Open another folder…'), findsOneWidget);
      expect(find.text(ProjectMenuButton.openShortcutLabel), findsOneWidget);
      await tester.tap(find.text('Open another folder…'));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('docking right and left call back with the side', (tester) async {
      final sides = <DockSide>[];
      await pumpMenu(tester, _controller(), onDock: (s) async => sides.add(s));
      for (final label in ['Dock to the right edge', 'Dock to the left edge']) {
        await tester.tap(find.byType(ProjectMenuButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(sides, [DockSide.right, DockSide.left]);
    });
  });

  testWidgets('Ctrl+O (Cmd+O on macOS) opens the folder picker from anywhere on the home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(440, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var picked = 0;
    final settings = await AppSettings.load();
    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(
            controller: _controller(),
            log: CommandLog(),
            onAbout: () {},
            onDock: (_) async {},
            pickFolder: () async {
              picked++;
              return null;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mac = Platform.isMacOS;
    await tester.sendKeyDownEvent(mac ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(mac ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(picked, 1);
  });
}

extension _Let<T> on T {
  void let(void Function(T) f) => f(this);
}
