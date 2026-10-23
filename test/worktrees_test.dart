import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
import 'package:flutty_dock/core/git_client.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/install/install_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoDevices implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [];
}

/// 저장소 상태와 worktree를 정해 둔 가짜 git.
class _StubGit extends GitClient {
  _StubGit({this.state, this.installed = true, this.trees = const []}) : super(CommandRunner(CommandLog()));
  GitState? state;
  bool installed;
  List<GitWorktree> trees;

  @override
  Future<GitState?> status(String directory) async => state;

  @override
  Future<bool> available() async => installed;

  @override
  Future<List<GitWorktree>> worktrees(String directory) async => trees;
}

class _Runner extends CommandRunner {
  _Runner(this.respond) : super(CommandLog());
  final CommandResult Function(List<String> args) respond;
  final ran = <List<String>>[];
  final cwds = <String?>[];

  @override
  Future<CommandResult> run(
    List<String> args, {
    String? workingDirectory,
    Map<String, String> environment = const {},
    bool quiet = false,
    String? stdin,
    RunHandle? handle,
    bool keepStdinOpen = false,
    void Function(String chunk)? onOutput,
  }) async {
    ran.add(args);
    cwds.add(workingDirectory);
    return respond(args);
  }
}

const _porcelain = '''
worktree D:/work/app
HEAD 1111111111111111111111111111111111111111
branch refs/heads/main

worktree D:/work/app-feature
HEAD 2222222222222222222222222222222222222222
branch refs/heads/feature/login

worktree D:/work/app-detached
HEAD 3333333333333333333333333333333333333333
detached

worktree D:/work/app.git
bare

worktree D:/work/gone
HEAD 4444444444444444444444444444444444444444
branch refs/heads/old
prunable gitdir file points to non-existent location
''';

void main() {
  group('worktree list parsing', () {
    test('main, branch, detached; bare and prunable entries are left out', () {
      final list = parseWorktrees(_porcelain);
      expect(list, [
        const GitWorktree(path: 'D:/work/app', branch: 'main'),
        const GitWorktree(path: 'D:/work/app-feature', branch: 'feature/login'),
        const GitWorktree(path: 'D:/work/app-detached', detached: true),
      ]);
      expect(list.first.folderName, 'app');
      expect(list[1].folderName, 'app-feature');
    });

    test('empty and garbage input give an empty list; a missing trailing blank line is fine', () {
      expect(parseWorktrees(''), isEmpty);
      expect(parseWorktrees('nonsense\n'), isEmpty);
      expect(parseWorktrees('worktree /a\nbranch refs/heads/x'), [const GitWorktree(path: '/a', branch: 'x')]);
    });
  });

  group('which worktree a project is in, and where it moves to', () {
    const main = GitWorktree(path: 'D:/work/app', branch: 'main');
    const feature = GitWorktree(path: 'D:/work/app-feature', branch: 'feature/login');
    const nested = GitWorktree(path: 'D:/work/app/packages/tool', branch: 'tool');

    test('windows paths and letter case do not matter', () {
      expect(worktreeContaining([main, feature], r'D:\work\app'), main);
      expect(worktreeContaining([main, feature], r'd:\WORK\app-feature\'), feature);
      expect(worktreeContaining([main, feature], 'D:/other/app'), isNull);
    });

    test('app-feature is not inside app (prefix is not enough)', () {
      expect(worktreeContaining([main, feature], 'D:/work/app-feature/lib'), feature);
    });

    test('the deepest worktree wins', () {
      expect(worktreeContaining([main, nested], 'D:/work/app/packages/tool/x'), nested);
      expect(worktreeContaining([main, nested], 'D:/work/app/other'), main);
    });

    test('a repo-root project moves to the other worktree root; a sub-project keeps its subfolder', () {
      expect(projectPathIn(main, feature, r'D:\work\app'), 'D:/work/app-feature');
      expect(projectPathIn(main, feature, 'D:/work/app/mobile'), 'D:/work/app-feature/mobile');
      expect(projectPathIn(main, feature, r'D:\work\app\apps\mobile\'), 'D:/work/app-feature/apps/mobile');
    });
  });

  group('GitClient', () {
    test('available is false when git is missing and true when it runs', () async {
      expect(await GitClient(_Runner((_) => const CommandResult(127, '', 'not found'))).available(), isFalse);
      expect(await GitClient(_Runner((_) => const CommandResult(0, 'git version 2.50', ''))).available(), isTrue);
    });

    test('worktrees runs the porcelain list in the project folder', () async {
      final runner = _Runner((_) => const CommandResult(0, _porcelain, ''));
      final list = await GitClient(runner).worktrees('/p/app');
      expect(list, hasLength(3));
      expect(runner.ran.single, ['git', 'worktree', 'list', '--porcelain']);
      expect(runner.cwds.single, '/p/app');
      expect(await GitClient(_Runner((_) => const CommandResult(128, '', 'fatal'))).worktrees('/x'), isEmpty);
    });
  });

  group('controller', () {
    late Directory root;
    late Directory main;
    late Directory feature;

    Directory flutterProject(Directory parent, String name, {String? sub}) {
      final d = Directory('${parent.path}/$name${sub == null ? '' : '/$sub'}')..createSync(recursive: true);
      File('${d.path}/pubspec.yaml').writeAsStringSync('name: app\ndependencies:\n  flutter:\n    sdk: flutter\n');
      return d;
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      root = Directory.systemTemp.createTempSync('flutty_wt');
      main = flutterProject(root, 'app');
      feature = flutterProject(root, 'app-feature');
    });

    tearDown(() => root.deleteSync(recursive: true));

    String slash(String p) => p.replaceAll('\\', '/');

    InstallController make(_StubGit git) => InstallController(
      runner: CommandRunner(CommandLog()),
      deviceService: _NoDevices(),
      gitClient: git,
      hostIsMac: false,
      hostIsWindows: false,
    );

    test('git missing is told apart from "not a repository"', () async {
      final noGit = make(_StubGit(installed: false));
      await noGit.init();
      await noGit.openProject(main.path);
      expect(noGit.gitState, isNull);
      expect(noGit.gitMissing, isTrue);

      final plain = make(_StubGit());
      await plain.init();
      await plain.openProject(main.path);
      expect(plain.gitState, isNull);
      expect(plain.gitMissing, isFalse);
      expect(plain.worktrees, isEmpty);
    });

    test('switching opens the same project in the other worktree and keeps options separate', () async {
      final git = _StubGit(
        state: const GitState(branch: 'main', upstream: 'origin/main'),
        trees: [
          GitWorktree(path: slash(main.path), branch: 'main'),
          GitWorktree(path: slash(feature.path), branch: 'feature/login'),
        ],
      );
      final c = make(git);
      await c.init();
      await c.openProject(main.path);
      expect(c.currentWorktree?.branch, 'main');
      expect(c.worktrees, hasLength(2));

      expect(await c.switchWorktree(c.worktrees[1]), isTrue);
      expect(slash(c.project!.path), slash(feature.path));
      expect(c.currentWorktree?.branch, 'feature/login');
      // 마지막으로 연 프로젝트로 저장된다 — 다음 실행에서도 이 worktree가 열린다.
      final again = make(git);
      await again.init();
      expect(slash(again.project!.path), slash(feature.path));
    });

    test('a sub-project keeps its subfolder in the other worktree', () async {
      final mainSub = flutterProject(root, 'mono', sub: 'mobile');
      final otherSub = flutterProject(root, 'mono-feature', sub: 'mobile');
      final git = _StubGit(
        state: const GitState(branch: 'main'),
        trees: [
          GitWorktree(path: slash('${root.path}/mono'), branch: 'main'),
          GitWorktree(path: slash('${root.path}/mono-feature'), branch: 'feature'),
        ],
      );
      final c = make(git);
      await c.init();
      await c.openProject(mainSub.path);
      expect(await c.switchWorktree(c.worktrees[1]), isTrue);
      expect(slash(c.project!.path), slash(otherSub.path));
    });

    test('a worktree without that project is refused and the current project stays', () async {
      final bare = Directory('${root.path}/empty')..createSync();
      final git = _StubGit(
        state: const GitState(branch: 'main'),
        trees: [
          GitWorktree(path: slash(main.path), branch: 'main'),
          GitWorktree(path: slash(bare.path), branch: 'docs'),
        ],
      );
      final c = make(git);
      await c.init();
      await c.openProject(main.path);
      expect(await c.switchWorktree(c.worktrees[1]), isFalse);
      expect(slash(c.project!.path), slash(main.path));
      expect(c.projectError, isNotNull);
      expect(c.gitState, isNotNull, reason: 'the Git card stays for the project that is still open');
    });

    test('no switching to the current worktree or while running', () async {
      final git = _StubGit(
        state: const GitState(branch: 'main'),
        trees: [
          GitWorktree(path: slash(main.path), branch: 'main'),
          GitWorktree(path: slash(feature.path), branch: 'feature/login'),
        ],
      );
      final c = make(git);
      await c.init();
      await c.openProject(main.path);
      expect(await c.switchWorktree(c.worktrees[0]), isFalse);
      c.running = true;
      expect(await c.switchWorktree(c.worktrees[1]), isFalse);
      expect(slash(c.project!.path), slash(main.path));
    });
  });
}
