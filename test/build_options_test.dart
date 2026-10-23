import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/flutter/flutter_project.dart';
import 'package:flutty_dock/install/build_options.dart';
import 'package:flutty_dock/install/install_controller.dart';
import 'package:flutty_dock/install/install_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _project = FlutterProject(
  path: '/p/app',
  name: 'app',
  hasIos: true,
  hasAndroid: true,
  hasMacos: true,
  hasWindows: true,
  iosBundleId: 'art.zoomon.app',
  androidApplicationId: 'art.zoomon.app',
  macosAppName: 'App',
  windowsBinaryName: 'app',
);

const _galaxy = MobileDevice(id: 'R3CY', name: 'SM S931N', platform: DevicePlatform.android, link: DeviceLink.usb);
const _iphone = MobileDevice(
  id: 'UDID1',
  name: 'My iPhone',
  platform: DevicePlatform.ios,
  link: DeviceLink.usb,
  developerModeOn: true,
);
const _mac = MobileDevice(id: 'macos', name: 'This Mac', platform: DevicePlatform.macos, link: DeviceLink.usb);
const _pc = MobileDevice(id: 'windows', name: 'This PC', platform: DevicePlatform.windows, link: DeviceLink.usb);

const _dev = BuildOptions(
  flavor: 'dev',
  target: 'lib/main_dev.dart',
  defineFile: 'env/dev.json',
  appId: 'art.zoomon.app.dev',
);

InstallPlan _plan(MobileDevice d, BuildMode m, BuildOptions o, {bool mac = true}) =>
    buildInstallPlan(project: _project, device: d, mode: m, teamId: 'TEAM123456', hostIsMac: mac, options: o);

class _NoDevices implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [];
}

void main() {
  group('splitArgs', () {
    test('splits on whitespace and keeps quoted parts together', () {
      expect(splitArgs('--obfuscate --split-debug-info=build/symbols'), ['--obfuscate', '--split-debug-info=build/symbols']);
      expect(splitArgs('--a "x y" \'z w\' b'), ['--a', 'x y', 'z w', 'b']);
      expect(splitArgs('   '), isEmpty);
      expect(splitArgs(''), isEmpty);
    });

    test('keeps backslashes (Windows paths) and an unclosed quote runs to the end', () {
      expect(splitArgs(r'--file C:\env\dev.json'), ['--file', r'C:\env\dev.json']);
      expect(splitArgs('--x "a b'), ['--x', 'a b']);
      expect(splitArgs('a"b c"d'), ['ab cd']);
    });
  });

  group('BuildOptions', () {
    test('flutterArgs order: flavor, target, define file, extra', () {
      const o = BuildOptions(flavor: 'dev', target: 'lib/m.dart', defineFile: 'e.json', extraArgs: '--obfuscate');
      expect(o.flutterArgs(flavorSupported: true), ['--flavor', 'dev', '-t', 'lib/m.dart', '--dart-define-from-file=e.json', '--obfuscate']);
      expect(o.flutterArgs(flavorSupported: false), ['-t', 'lib/m.dart', '--dart-define-from-file=e.json', '--obfuscate']);
      expect(const BuildOptions().flutterArgs(flavorSupported: true), isEmpty);
    });

    test('a flavor that is not a plain name is ignored and flagged', () {
      const bad = BuildOptions(flavor: 'dev; rm -rf');
      expect(bad.flavorInvalid, isTrue);
      expect(bad.flutterArgs(flavorSupported: true), isEmpty);
      expect(isValidFlavor('dev-2_x'), isTrue);
      expect(isValidFlavor('2dev'), isFalse);
    });

    test('round-trips and survives garbage', () {
      expect(BuildOptions.decode(_dev.encode()), _dev);
      expect(BuildOptions.decode(null), const BuildOptions());
      expect(BuildOptions.decode('not json'), const BuildOptions());
      expect(BuildOptions.decode('[1,2]'), const BuildOptions());
      expect(const BuildOptions().isEmpty, isTrue);
      expect(_dev.isEmpty, isFalse);
    });
  });

  group('plan with options', () {
    test('default options change nothing', () {
      expect(_plan(_galaxy, BuildMode.release, const BuildOptions()).steps.first.args, ['flutter', 'build', 'apk', '--release']);
      expect(_plan(_galaxy, BuildMode.debug, const BuildOptions()).steps.first.args, ['flutter', 'run', '-d', 'R3CY', '--debug']);
    });

    test('android release: flags on the build, flavored apk path and the overridden app id', () {
      final p = _plan(_galaxy, BuildMode.release, _dev);
      expect(p.steps[0].args, [
        'flutter', 'build', 'apk', '--release',
        '--flavor', 'dev', '-t', 'lib/main_dev.dart', '--dart-define-from-file=env/dev.json',
      ]);
      const apk = '/p/app/build/app/outputs/flutter-apk/app-dev-release.apk';
      expect(p.artifact, apk);
      expect(p.steps[1].args.last, apk);
      expect(p.steps[2].args, contains('art.zoomon.app.dev'));
      expect(p.steps[2].args, isNot(contains('art.zoomon.app')));
    });

    test('android debug gets the flags too', () {
      expect(_plan(_galaxy, BuildMode.debug, _dev).steps.single.args, [
        'flutter', 'run', '-d', 'R3CY', '--debug',
        '--flavor', 'dev', '-t', 'lib/main_dev.dart', '--dart-define-from-file=env/dev.json',
      ]);
    });

    test('ios release: flags on the prepare step, scheme and Release-<flavor> configuration', () {
      final p = _plan(_iphone, BuildMode.release, _dev);
      expect(p.steps[0].args, containsAllInOrder(['--config-only', '--no-codesign', '--flavor', 'dev', '-t', 'lib/main_dev.dart']));
      final xcode = p.steps[1].args;
      expect(xcode[xcode.indexOf('-scheme') + 1], 'dev');
      expect(xcode[xcode.indexOf('-configuration') + 1], 'Release-dev');
      expect(p.artifact, '/p/app/build/ios_dd/Build/Products/Release-dev-iphoneos/Runner.app');
      expect(p.steps[2].args.last, p.artifact);
      expect(p.steps[3].args.last, 'art.zoomon.app.dev');
    });

    test('ios release without a flavor keeps Runner and Release', () {
      final p = _plan(_iphone, BuildMode.release, const BuildOptions(target: 'lib/m.dart'));
      final xcode = p.steps[1].args;
      expect(xcode[xcode.indexOf('-scheme') + 1], 'Runner');
      expect(xcode[xcode.indexOf('-configuration') + 1], 'Release');
      expect(p.steps[0].args.last, 'lib/m.dart');
      expect(p.steps[3].args.last, 'art.zoomon.app');
    });

    test('macos release: flavored products folder', () {
      final p = _plan(_mac, BuildMode.release, const BuildOptions(flavor: 'dev'));
      expect(p.steps[0].args, ['flutter', 'build', 'macos', '--release', '--flavor', 'dev']);
      expect(p.artifact, '/p/app/build/macos/Build/Products/Release-dev/App.app');
      expect(p.steps[1].args, ['open', '/p/app/build/macos/Build/Products/Release-dev/App.app']);
    });

    test('windows ignores the flavor but keeps the other options', () {
      final p = _plan(_pc, BuildMode.release, _dev, mac: false);
      expect(p.steps[0].args, ['flutter', 'build', 'windows', '--release', '-t', 'lib/main_dev.dart', '--dart-define-from-file=env/dev.json']);
      expect(p.artifact, contains(r'runner\Release\app.exe'));
      final debug = _plan(_pc, BuildMode.debug, _dev, mac: false).steps.single.args;
      expect(debug, isNot(contains('--flavor')));
      expect(debug, contains('-t'));
    });

    test('options do not touch the commands that are not flutter run/build', () {
      final p = _plan(_galaxy, BuildMode.release, _dev);
      expect(p.steps[1].args.first, 'adb');
      expect(p.steps[1].args, isNot(contains('--flavor')));
    });
  });

  group('controller storage', () {
    late Directory a;
    late Directory b;

    Directory flutterProject(String name) {
      final d = Directory.systemTemp.createTempSync('flutty_opts_$name');
      File('${d.path}/pubspec.yaml').writeAsStringSync('name: $name\ndependencies:\n  flutter:\n    sdk: flutter\n');
      return d;
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      a = flutterProject('a');
      b = flutterProject('b');
    });

    tearDown(() {
      a.deleteSync(recursive: true);
      b.deleteSync(recursive: true);
    });

    InstallController make() => InstallController(
      runner: CommandRunner(CommandLog()),
      deviceService: _NoDevices(),
      hostIsMac: false,
      hostIsWindows: false,
    );

    test('options are kept per project and come back when the project is opened again', () async {
      final c = make();
      await c.init();
      await c.openProject(a.path);
      c.setOptions(const BuildOptions(flavor: 'dev', target: 'lib/main_dev.dart'));
      await c.openProject(b.path);
      expect(c.options.isEmpty, isTrue, reason: 'b has its own options');
      c.setOptions(const BuildOptions(flavor: 'prod'));
      await c.openProject(a.path);
      expect(c.options.flavor, 'dev');
      expect(c.options.target, 'lib/main_dev.dart');
      await c.openProject(b.path);
      expect(c.options.flavor, 'prod');
    });

    test('a new controller (app restart) restores the last project options; clearing forgets them', () async {
      final c = make();
      await c.init();
      await c.openProject(a.path);
      c.setOptions(const BuildOptions(flavor: 'dev'));

      final again = make();
      await again.init();
      expect(again.project?.path, a.path);
      expect(again.options.flavor, 'dev');

      again.setOptions(const BuildOptions());
      final third = make();
      await third.init();
      expect(third.options.isEmpty, isTrue);
      expect((await SharedPreferences.getInstance()).getKeys().where((k) => k.startsWith('build_options:')), isEmpty);
    });

    test('options cannot change while a run is in progress', () async {
      final c = make();
      await c.init();
      await c.openProject(a.path);
      c.running = true;
      c.setOptions(const BuildOptions(flavor: 'dev'));
      expect(c.options.isEmpty, isTrue);
    });

    test('the controller plan uses the options', () async {
      final c = make();
      await c.init();
      await c.openProject(a.path);
      c.project = FlutterProject(path: a.path, name: 'a', hasIos: false, hasAndroid: true, androidApplicationId: 'x.y');
      c.devices = const [_galaxy];
      c.selectedId = _galaxy.id;
      c.mode = BuildMode.release;
      c.setOptions(const BuildOptions(flavor: 'dev'));
      expect(c.plan.steps.first.args, containsAllInOrder(['--release', '--flavor', 'dev']));
    });
  });
}
