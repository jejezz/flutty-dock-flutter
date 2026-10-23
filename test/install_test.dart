import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
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
  iosBundleId: 'art.zoomon.app',
  androidApplicationId: 'art.zoomon.app',
);

const _iphone = MobileDevice(
  id: 'UDID1',
  name: 'My iPhone',
  platform: DevicePlatform.ios,
  link: DeviceLink.usb,
  developerModeOn: true,
);
const _galaxy = MobileDevice(id: 'R3CY', name: 'SM S931N', platform: DevicePlatform.android, link: DeviceLink.usb);

InstallPlan _plan(MobileDevice? d, BuildMode m, {String? team = 'TEAM123456', FlutterProject? project = _project}) =>
    buildInstallPlan(project: project, device: d, mode: m, teamId: team, hostIsMac: true);

class _FakeRunner extends CommandRunner {
  _FakeRunner(this.results) : super(CommandLog());
  final List<CommandResult> results;
  final ran = <List<String>>[];

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
    return results.removeAt(0);
  }
}

class _NoDevices implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [];
}

void main() {
  group('project parsing', () {
    test('pubspec fields and flutter detection', () {
      const pubspec = '''
name: flutty_dock
description: "x"
version: 0.1.0-rc.1+1
dependencies:
  flutter:
    sdk: flutter
''';
      expect(isFlutterPubspec(pubspec), isTrue);
      expect(isFlutterPubspec('name: x\ndependencies:\n  path: any\n'), isFalse);
      expect(parsePubspecField(pubspec, 'name'), 'flutty_dock');
      expect(parsePubspecField(pubspec, 'version'), '0.1.0-rc.1+1');
    });

    test('ios bundle id skips RunnerTests and variables; team id', () {
      const pbx = '''
PRODUCT_BUNDLE_IDENTIFIER = art.zoomon.app.RunnerTests;
PRODUCT_BUNDLE_IDENTIFIER = "art.zoomon.app";
DEVELOPMENT_TEAM = 6N35L95QS4;
''';
      expect(parseIosBundleId(pbx), 'art.zoomon.app');
      expect(parseIosBundleId(r'PRODUCT_BUNDLE_IDENTIFIER = $(APP_ID);'), isNull);
      expect(parseIosTeamId(pbx), '6N35L95QS4');
    });

    test('android application id from kts and groovy', () {
      expect(parseAndroidApplicationId('    applicationId = "art.zoomon.app"'), 'art.zoomon.app');
      expect(parseAndroidApplicationId("    applicationId 'com.x.y'"), 'com.x.y');
    });
  });

  group('device parsing', () {
    test('devicectl: keeps physical iPhones only; wired is USB', () {
      const json = '''
{"result":{"devices":[
 {"identifier":"A","connectionProperties":{"transportType":"wired"},
  "deviceProperties":{"name":"JY iPhone","osVersionNumber":"26.6","developerModeStatus":"enabled"},
  "hardwareProperties":{"reality":"physical","platform":"iOS","udid":"UDID-A","marketingName":"iPhone 12 mini"}},
 {"identifier":"B","connectionProperties":{"transportType":"localNetwork"},
  "deviceProperties":{"name":"Other","developerModeStatus":"disabled"},
  "hardwareProperties":{"reality":"physical","platform":"iOS","udid":"UDID-B"}},
 {"identifier":"C","connectionProperties":{"transportType":"sameMachine"},
  "deviceProperties":{"name":"Simulator"},
  "hardwareProperties":{"reality":"simulated","platform":"iOS","udid":"UDID-C"}}
]}}''';
      final d = parseDevicectl(json);
      expect(d.map((e) => e.id), ['UDID-A', 'UDID-B']);
      expect(d[0].isUsb, isTrue);
      expect(d[0].developerModeOn, isTrue);
      expect(d[1].isUsb, isFalse);
      expect(d[1].developerModeOn, isFalse);
    });

    test('adb: model name, authorization and wireless serials', () {
      const out = '''
List of devices attached
R3CY20TKESK            device usb:1048576X product:pa1qksx model:SM_S931N device:pa1q transport_id:3
192.168.0.5:5555       device product:x model:Pixel_8 device:y transport_id:4
ZZZ                    unauthorized usb:1 transport_id:5
''';
      final d = parseAdbDevices(out);
      expect(d.map((e) => e.id), ['R3CY20TKESK', '192.168.0.5:5555', 'ZZZ']);
      expect(d[0].name, 'SM S931N');
      expect(d[0].isUsb, isTrue);
      expect(d[1].isUsb, isFalse);
      expect(d[2].authorized, isFalse);
    });
  });

  group('install plan', () {
    test('ios release is the four verified steps with team injected as a build argument', () {
      final p = _plan(_iphone, BuildMode.release);
      expect(p.runnable, isTrue);
      expect(p.steps.map((s) => s.kind), [StepKind.prepare, StepKind.build, StepKind.install, StepKind.launch]);
      expect(p.steps[1].args, containsAll(['-allowProvisioningUpdates', 'DEVELOPMENT_TEAM=TEAM123456']));
      expect(p.steps[1].workingDirectory, '/p/app/ios');
      expect(p.steps[2].args.last, '/p/app/build/ios_dd/Build/Products/Release-iphoneos/Runner.app');
      expect(p.steps[3].args.last, 'art.zoomon.app');
    });

    test('android release builds, installs and launches', () {
      final p = _plan(_galaxy, BuildMode.release);
      expect(p.steps.map((s) => s.kind), [StepKind.build, StepKind.install, StepKind.launch]);
      expect(p.steps[1].args, [
        'adb',
        '-s',
        'R3CY',
        'install',
        '-r',
        '/p/app/build/app/outputs/flutter-apk/app-release.apk',
      ]);
    });

    test('debug is a single interactive flutter run', () {
      final p = _plan(_galaxy, BuildMode.debug);
      expect(p.steps.single.interactive, isTrue);
      expect(p.steps.single.args, ['flutter', 'run', '-d', 'R3CY', '--debug']);
    });

    test('ios debug passes the team through FLUTTER_XCODE_ variables, shown in the command', () {
      final p = _plan(_iphone, BuildMode.debug);
      final step = p.steps.single;
      expect(step.environment, {
        'FLUTTER_XCODE_DEVELOPMENT_TEAM': 'TEAM123456',
        'FLUTTER_XCODE_CODE_SIGN_STYLE': 'Automatic',
      });
      expect(
        step.commandLine,
        'FLUTTER_XCODE_DEVELOPMENT_TEAM=TEAM123456 FLUTTER_XCODE_CODE_SIGN_STYLE=Automatic flutter run -d UDID1 --debug',
      );
      expect(_plan(_galaxy, BuildMode.debug).steps.single.environment, isEmpty);
    });

    test('blockers', () {
      expect(_plan(_iphone, BuildMode.release, project: null).blockers, [Blocker.noProject]);
      expect(_plan(null, BuildMode.release).blockers, [Blocker.noDevice]);
      expect(_plan(_iphone, BuildMode.release, team: null).blockers, [Blocker.needsTeamId]);
      const wireless = MobileDevice(id: 'W', name: 'W', platform: DevicePlatform.ios, link: DeviceLink.wireless);
      expect(_plan(wireless, BuildMode.release).blockers, contains(Blocker.wireless));
      const noDev = MobileDevice(
        id: 'N',
        name: 'N',
        platform: DevicePlatform.ios,
        link: DeviceLink.usb,
        developerModeOn: false,
      );
      expect(_plan(noDev, BuildMode.release).blockers, contains(Blocker.developerModeOff));
      const unauth = MobileDevice(
        id: 'U',
        name: 'U',
        platform: DevicePlatform.android,
        link: DeviceLink.usb,
        authorized: false,
      );
      expect(_plan(unauth, BuildMode.release).blockers, contains(Blocker.androidUnauthorized));
      expect(_plan(_iphone, BuildMode.release).blockers, isEmpty);
    });

    test('a project team id is enough; the user team wins', () {
      const withTeam = FlutterProject(path: '/p', name: 'a', hasIos: true, hasAndroid: false, iosTeamId: 'PROJTEAM12');
      expect(_plan(_iphone, BuildMode.release, team: null, project: withTeam).blockers, isEmpty);
      expect(
        _plan(_iphone, BuildMode.release, project: withTeam).steps[1].args,
        contains('DEVELOPMENT_TEAM=TEAM123456'),
      );
    });

    test('failure hints', () {
      expect(explainFailure('Connection reset by peer'), FailureHint.useUsb);
      expect(explainFailure('The device is locked.'), FailureHint.unlockDevice);
      expect(explainFailure('No profiles for art.zoomon.app were found'), FailureHint.signing);
      expect(explainFailure('something unknown'), isNull);
    });
  });

  group('InstallController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    InstallController make(_FakeRunner r) => InstallController(runner: r, deviceService: _NoDevices())
      ..project = _project
      ..devices = [_galaxy]
      ..selectedId = _galaxy.id;

    test('runs every step in order and marks them done', () async {
      final r = _FakeRunner(List.generate(3, (_) => const CommandResult(0, '', '')));
      final c = make(r);
      await c.start();
      expect(r.ran.map((a) => a.first), ['flutter', 'adb', 'adb']);
      expect(c.statuses, [StepStatus.done, StepStatus.done, StepStatus.done]);
      expect(c.running, isFalse);
    });

    test('stops at the first failure, explains it and leaves the rest pending', () async {
      final r = _FakeRunner([const CommandResult(0, '', ''), const CommandResult(1, '', 'Connection reset by peer')]);
      final c = make(r);
      await c.start();
      expect(c.statuses, [StepStatus.done, StepStatus.failed, StepStatus.pending]);
      expect(c.hint, FailureHint.useUsb);
      expect(r.ran, hasLength(2));
    });

    test('reports a missing command', () async {
      final c = make(_FakeRunner([const CommandResult(127, '', 'not found')]));
      await c.start();
      expect(c.missingCommand, 'flutter');
    });

    test('the optional clean step goes in front of the build and turns itself off once it ran', () async {
      final r = _FakeRunner(List.generate(5, (_) => const CommandResult(0, '', '')));
      final c = make(r)
        ..mode = BuildMode.release
        ..setCleanFirst(true);
      expect(c.plan.steps.map((s) => s.kind), [
        StepKind.clean,
        StepKind.pubGet,
        StepKind.build,
        StepKind.install,
        StepKind.launch,
      ]);
      expect(c.plan.cleanCount, 2);
      expect(c.plan.splittable, isTrue);

      await c.start();
      expect(r.ran.take(2), [
        ['flutter', 'clean'],
        ['flutter', 'pub', 'get'],
      ]);
      expect(r.ran, hasLength(5));
      // 정리 단계를 끝내면 선택이 꺼지고, 남은 단계의 체크 표시가 새 계획(3단계)과 맞는다.
      expect(c.cleanFirst, isFalse);
      expect(c.plan.steps, hasLength(3));
      expect(c.statuses, [StepStatus.done, StepStatus.done, StepStatus.done]);
    });

    test('a failed clean keeps the option on and never reaches the build', () async {
      final r = _FakeRunner([const CommandResult(1, '', 'boom')]);
      final c = make(r)
        ..mode = BuildMode.release
        ..setCleanFirst(true);
      await c.start();
      expect(r.ran, hasLength(1));
      expect(c.cleanFirst, isTrue);
      expect(c.statuses.first, StepStatus.failed);
    });

    test('build only includes the clean step, run only does not', () async {
      final r = _FakeRunner(List.generate(3, (_) => const CommandResult(0, '', '')));
      final c = make(r)
        ..mode = BuildMode.release
        ..setCleanFirst(true);
      expect(c.plan.indicesOf(RunPhase.build), [0, 1, 2]);
      expect(c.plan.indicesOf(RunPhase.run), [3, 4]);
      await c.start(phase: RunPhase.build);
      expect(r.ran.map((a) => a.take(2).join(' ')), ['flutter clean', 'flutter pub', 'flutter build']);
    });

    test('debug with clean is still one interactive run, not a build/run split', () {
      final c = make(_FakeRunner([]))
        ..mode = BuildMode.debug
        ..setCleanFirst(true);
      expect(c.plan.steps.map((s) => s.kind), [StepKind.clean, StepKind.pubGet, StepKind.run]);
      expect(c.plan.splittable, isFalse);
      expect(c.plan.steps.any((s) => s.interactive), isTrue);
    });

    test('does nothing while blocked', () async {
      final r = _FakeRunner([]);
      final c = make(r)..selectedId = null;
      await c.start();
      expect(r.ran, isEmpty);
    });
  });
}
