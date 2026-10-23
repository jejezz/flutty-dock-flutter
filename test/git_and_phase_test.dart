import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
import 'package:flutty_dock/core/git_client.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/flutter/flutter_project.dart';
import 'package:flutty_dock/install/install_controller.dart';
import 'package:flutty_dock/install/install_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _project = FlutterProject(
  path: '/p/app',
  name: 'app',
  hasIos: true,
  hasAndroid: true,
  hasWindows: true,
  iosBundleId: 'art.zoomon.app',
  androidApplicationId: 'art.zoomon.app',
  windowsBinaryName: 'app',
);

const _galaxy = MobileDevice(id: 'R3CY', name: 'SM S931N', platform: DevicePlatform.android, link: DeviceLink.usb);

class _FakeRunner extends CommandRunner {
  _FakeRunner(this.respond) : super(CommandLog());
  final CommandResult Function(List<String> args) respond;
  final ran = <List<String>>[];
  final cwds = <String?>[];
  final envs = <Map<String, String>>[];

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
    envs.add(environment);
    return respond(args);
  }
}

class _OneDevice implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [_galaxy];
}

const _clean = '''
# branch.oid 0123456789abcdef
# branch.head main
# branch.upstream origin/main
# branch.ab +0 -0
''';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('git status parsing', () {
    test('clean branch tracking its upstream', () {
      final g = parseGitStatus(_clean, remoteUrl: 'git@github.com:o/r.git');
      expect(g.branch, 'main');
      expect(g.upstream, 'origin/main');
      expect((g.ahead, g.behind, g.dirty), (0, 0, false));
      expect(g.remoteWebUrl, 'https://github.com/o/r');
      expect(g.pullBlock, GitPullBlock.upToDate);
      expect(g.canPull, isFalse);
    });

    test('behind and clean can be pulled', () {
      final g = parseGitStatus(_clean.replaceFirst('+0 -0', '+0 -3'));
      expect(g.behind, 3);
      expect(g.canPull, isTrue);
      expect(g.pullBlock, isNull);
    });

    test('tracked changes block the pull; so does a diverged history', () {
      const dirty = '# branch.head main\n# branch.upstream origin/main\n# branch.ab +0 -2\n1 .M N... 100644 100644 100644 a b lib/x.dart\n';
      final d = parseGitStatus(dirty);
      expect(d.dirty, isTrue);
      expect(d.pullBlock, GitPullBlock.dirty);

      final diverged = parseGitStatus(_clean.replaceFirst('+0 -0', '+1 -2'));
      expect(diverged.pullBlock, GitPullBlock.diverged);
    });

    test('no upstream and detached HEAD', () {
      final g = parseGitStatus('# branch.oid abc\n# branch.head (detached)\n');
      expect(g.detached, isTrue);
      expect(g.hasUpstream, isFalse);
      expect(g.pullBlock, GitPullBlock.noUpstream);
    });
  });

  group('remote web url', () {
    test('https, scp-style and ssh remotes', () {
      expect(remoteWebUrlOf('https://github.com/o/r.git'), 'https://github.com/o/r');
      expect(remoteWebUrlOf('https://github.com/o/r'), 'https://github.com/o/r');
      expect(remoteWebUrlOf('git@github.com:o/r.git'), 'https://github.com/o/r');
      expect(remoteWebUrlOf('ssh://git@gitlab.example.com:2222/team/sub/r.git'), 'https://gitlab.example.com/team/sub/r');
    });

    test('credentials in the url are dropped', () {
      expect(remoteWebUrlOf('https://user:ghp_secret@github.com/o/r.git'), 'https://github.com/o/r');
    });

    test('local paths are not links', () {
      expect(remoteWebUrlOf(r'C:\repos\app'), isNull);
      expect(remoteWebUrlOf('/srv/git/app.git'), isNull);
    });
  });

  group('GitClient', () {
    test('status reads quietly in the project folder and never prompts for credentials', () async {
      final runner = _FakeRunner(
        (a) => a[1] == 'status' ? CommandResult(0, _clean, '') : const CommandResult(0, 'https://github.com/o/r.git\n', ''),
      );
      final g = await GitClient(runner).status('/p/app');
      expect(g?.remoteWebUrl, 'https://github.com/o/r');
      expect(runner.cwds, everyElement('/p/app'));
      expect(runner.envs, everyElement(containsPair('GIT_TERMINAL_PROMPT', '0')));
    });

    test('not a repository gives null', () async {
      final runner = _FakeRunner((_) => const CommandResult(128, '', 'fatal: not a git repository'));
      expect(await GitClient(runner).status('/p/app'), isNull);
    });

    test('fetch prunes and pull is fast-forward only', () async {
      final runner = _FakeRunner((_) => const CommandResult(0, '', ''));
      final git = GitClient(runner);
      await git.fetch('/p/app');
      await git.pull('/p/app');
      expect(runner.ran, [
        ['git', 'fetch', '--prune'],
        ['git', 'pull', '--ff-only'],
      ]);
    });
  });

  group('controller git actions', () {
    InstallController make(_FakeRunner runner) {
      final c = InstallController(runner: runner, deviceService: _OneDevice(), hostIsMac: false, hostIsWindows: true);
      c.project = _project;
      return c;
    }

    test('pull only runs when the branch can be fast-forwarded', () async {
      final runner = _FakeRunner(
        (a) => a[1] == 'status' ? CommandResult(0, _clean, '') : const CommandResult(0, 'git@github.com:o/r.git', ''),
      );
      final c = make(runner);
      await c.refreshGit();
      expect(await c.gitPull(), isFalse, reason: 'up to date');
      expect(runner.ran.any((a) => a.contains('pull')), isFalse);
    });

    test('a successful pull refreshes the state and reports success', () async {
      var behind = 2;
      final runner = _FakeRunner((a) {
        if (a[1] == 'status') return CommandResult(0, _clean.replaceFirst('+0 -0', '+0 -$behind'), '');
        if (a[1] == 'pull') {
          behind = 0;
          return const CommandResult(0, 'Fast-forward', '');
        }
        return const CommandResult(0, 'git@github.com:o/r.git', '');
      });
      final c = make(runner);
      await c.refreshGit();
      expect(c.gitState!.canPull, isTrue);
      expect(await c.gitPull(), isTrue);
      expect(c.lastGitAction, GitAction.pull);
      expect(c.lastGitOk, isTrue);
      expect(c.gitState!.behind, 0);
    });

    test('a failed fetch is reported and git missing is flagged', () async {
      final runner = _FakeRunner((a) => a[1] == 'fetch' ? const CommandResult(127, '', 'not found') : CommandResult(0, _clean, ''));
      final c = make(runner);
      await c.refreshGit();
      expect(await c.gitFetch(), isFalse);
      expect(c.lastGitOk, isFalse);
      expect(c.missingCommand, 'git');
    });
  });

  group('build and run phases', () {
    InstallPlan plan(MobileDevice d, BuildMode m) =>
        buildInstallPlan(project: _project, device: d, mode: m, teamId: 'T', hostIsMac: false);

    test('android release splits into build and run', () {
      final p = plan(_galaxy, BuildMode.release);
      expect(p.splittable, isTrue);
      expect(p.indicesOf(RunPhase.build), [0]);
      expect(p.indicesOf(RunPhase.run), [1, 2]);
      expect(p.indicesOf(RunPhase.all), [0, 1, 2]);
      expect(p.artifact, '/p/app/build/app/outputs/flutter-apk/app-release.apk');
    });

    test('debug is a single run step and cannot be split', () {
      final p = plan(_galaxy, BuildMode.debug);
      expect(p.splittable, isFalse);
      expect(p.indicesOf(RunPhase.build), isEmpty);
      expect(p.artifact, isNull);
    });

    test('windows release artifact is the exe', () {
      final p = buildInstallPlan(
        project: _project,
        device: const MobileDevice(id: 'windows', name: 'This PC', platform: DevicePlatform.windows, link: DeviceLink.usb),
        mode: BuildMode.release,
        teamId: null,
        hostIsMac: false,
        windowsArch: 'x64',
      );
      expect(p.artifact, r'/p/app\build\windows\x64\runner\Release\app.exe');
      expect(p.indicesOf(RunPhase.run), [1]);
    });

    test('start(build) runs only the build steps; start(run) only the rest, keeping earlier checks', () async {
      final runner = _FakeRunner((_) => const CommandResult(0, '', ''));
      final c = InstallController(runner: runner, deviceService: _OneDevice(), hostIsMac: false, hostIsWindows: false);
      c.project = _project;
      c.devices = const [_galaxy];
      c.selectedId = _galaxy.id;
      c.mode = BuildMode.release;

      await c.start(phase: RunPhase.build);
      expect(runner.ran.map((a) => a.first), ['flutter']);
      expect(c.statuses, [StepStatus.done, StepStatus.pending, StepStatus.pending]);

      runner.ran.clear();
      await c.start(phase: RunPhase.run);
      expect(runner.ran.map((a) => a.first), ['adb', 'adb']);
      expect(c.statuses, [StepStatus.done, StepStatus.done, StepStatus.done]);

      runner.ran.clear();
      await c.start();
      expect(runner.ran.length, 3);
    });
  });
}
