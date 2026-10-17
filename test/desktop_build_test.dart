import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/doctor/checks.dart';
import 'package:flutty_dock/doctor/diagnostics.dart';
import 'package:flutty_dock/flutter/flutter_project.dart';
import 'package:flutty_dock/install/install_controller.dart';
import 'package:flutty_dock/install/install_plan.dart';
import 'package:flutty_dock/l10n/app_localizations.dart';
import 'package:flutty_dock/ui/banner.dart';
import 'package:flutty_dock/ui/devices_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _both = FlutterProject(
  path: '/p/app',
  name: 'app',
  hasIos: true,
  hasAndroid: true,
  hasMacos: true,
  hasWindows: true,
  macosAppName: 'My App',
  windowsBinaryName: 'my_app',
);
const _mobileOnly = FlutterProject(path: '/p/app', name: 'app', hasIos: true, hasAndroid: true);

const _mac = MobileDevice(id: 'macos', name: 'macOS', platform: DevicePlatform.macos, link: DeviceLink.local);
const _win = MobileDevice(id: 'windows', name: 'Windows', platform: DevicePlatform.windows, link: DeviceLink.local);
const _pixel = MobileDevice(id: 'PX', name: 'Pixel 8', platform: DevicePlatform.android, link: DeviceLink.usb);

InstallPlan _plan(MobileDevice d, BuildMode m, {FlutterProject p = _both, String arch = 'x64'}) =>
    buildInstallPlan(project: p, device: d, mode: m, teamId: null, hostIsMac: true, windowsArch: arch);

class _Devices implements DeviceService {
  _Devices(this.list_);
  final List<MobileDevice> list_;
  @override
  Future<List<MobileDevice>> list() async => list_;
}

class _Diag implements DiagnosticsService {
  @override
  Future<Diagnostics> collect(FlutterProject? project) async => Diagnostics(
    flutter: const ToolInfo('3.47.1'),
    xcode: const ToolInfo('27.0'),
    adb: const ToolInfo(null),
    collectedAt: DateTime(2026, 10, 10),
  );
}

InstallController _controller({
  List<MobileDevice> devices = const [],
  FlutterProject? project,
  bool mac = true,
  bool windows = false,
}) {
  SharedPreferences.setMockInitialValues({});
  return InstallController(
      runner: CommandRunner(CommandLog(), path: '/usr/bin'),
      deviceService: _Devices(devices),
      diagnosticsService: _Diag(),
      hostIsMac: mac,
      hostIsWindows: windows,
    )
    ..project = project
    ..devices = devices;
}

void main() {
  group('project detection', () {
    test('parsers read the macOS product name and the Windows binary name', () {
      expect(parseMacosProductName('// c\nPRODUCT_NAME = Flutty Dock\nOTHER = 1\n'), 'Flutty Dock');
      expect(parseMacosProductName('OTHER = 1'), isNull);
      expect(parseWindowsBinaryName('set(BINARY_NAME "flutty_dock")\n'), 'flutty_dock');
      expect(parseWindowsBinaryName('project(x)'), isNull);
    });

    test('detect() sees macos/ and windows/ only when the project already has them', () async {
      final dir = await Directory.systemTemp.createTemp('flutty_desktop');
      addTearDown(() => dir.delete(recursive: true));
      File('${dir.path}/pubspec.yaml').writeAsStringSync('name: demo\ndependencies:\n  flutter:\n    sdk: flutter\n');
      var p = await FlutterProject.detect(dir.path);
      expect(p!.hasMacos, isFalse);
      expect(p.hasWindows, isFalse);

      Directory('${dir.path}/macos/Runner.xcodeproj').createSync(recursive: true);
      File('${dir.path}/macos/Runner.xcodeproj/project.pbxproj').writeAsStringSync('');
      Directory('${dir.path}/macos/Runner/Configs').createSync(recursive: true);
      File('${dir.path}/macos/Runner/Configs/AppInfo.xcconfig').writeAsStringSync('PRODUCT_NAME = Demo App\n');
      Directory('${dir.path}/windows').createSync();
      File('${dir.path}/windows/CMakeLists.txt').writeAsStringSync('set(BINARY_NAME "demo_app")\n');
      p = await FlutterProject.detect(dir.path);
      expect(p!.hasMacos, isTrue);
      expect(p.macosAppName, 'Demo App');
      expect(p.hasWindows, isTrue);
      expect(p.windowsBinaryName, 'demo_app');
    });
  });

  group('hostDesktopDevice', () {
    test('only the host OS, and only when the project already supports it', () {
      expect(hostDesktopDevice(_both, isMac: true, isWindows: false)?.platform, DevicePlatform.macos);
      expect(hostDesktopDevice(_both, isMac: false, isWindows: true)?.platform, DevicePlatform.windows);
      expect(hostDesktopDevice(_both, isMac: false, isWindows: false), isNull); // Linux 등
      expect(hostDesktopDevice(_mobileOnly, isMac: true, isWindows: false), isNull);
      expect(hostDesktopDevice(null, isMac: true, isWindows: false), isNull);
      const macOnly = FlutterProject(path: '/p', name: 'a', hasIos: false, hasAndroid: false, hasMacos: true);
      expect(hostDesktopDevice(macOnly, isMac: false, isWindows: true), isNull); // Windows PC에서는 macos/만 있어도 못 만든다
    });
  });

  group('install plan: this computer', () {
    test('macOS debug runs flutter run -d macos; release builds then opens the app bundle', () {
      expect(_plan(_mac, BuildMode.debug).steps.single.args, ['flutter', 'run', '-d', 'macos', '--debug']);
      final p = _plan(_mac, BuildMode.release);
      expect(p.runnable, isTrue);
      expect(p.steps.map((s) => s.kind), [StepKind.build, StepKind.launch]);
      expect(p.steps[0].args, ['flutter', 'build', 'macos', '--release']);
      expect(p.steps[1].args, ['open', '/p/app/build/macos/Build/Products/Release/My App.app']);
    });

    test('Windows release builds then starts the exe; the path follows the architecture', () {
      final p = _plan(_win, BuildMode.release);
      expect(p.steps[0].args, ['flutter', 'build', 'windows', '--release']);
      expect(p.steps[1].args, ['explorer.exe', r'/p/app\build\windows\x64\runner\Release\my_app.exe']);
      expect(_plan(_win, BuildMode.release, arch: 'arm64').steps[1].args.last, contains(r'\arm64\'));
      expect(_plan(_win, BuildMode.debug).steps.single.args, ['flutter', 'run', '-d', 'windows', '--debug']);
    });

    test('no launch step when the app name is unknown; no signing team or iOS/Android blockers', () {
      const unnamed = FlutterProject(path: '/p/app', name: 'a', hasIos: false, hasAndroid: false, hasMacos: true);
      final p = _plan(_mac, BuildMode.release, p: unnamed);
      expect(p.steps.map((s) => s.kind), [StepKind.build]);
      expect(p.blockers, isEmpty); // 팀 ID가 없어도 막지 않는다
    });

    test('a project without the platform folder is blocked', () {
      expect(_plan(_mac, BuildMode.release, p: _mobileOnly).blockers, [Blocker.platformMissing]);
      expect(_plan(_win, BuildMode.release, p: _mobileOnly).blockers, [Blocker.platformMissing]);
    });

    test('build-tool failures are explained', () {
      expect(explainFailure('Error: CocoaPods not installed. Skipping pod install.'), FailureHint.cocoapods);
      expect(explainFailure('Unable to find suitable Visual Studio toolchain.'), FailureHint.visualStudio);
    });

    test('missing plugin symlinks on the first build ask for an app restart', () {
      // CMake가 긴 줄을 접어 쓴 실제 출력.
      const output = '''
CMake Error at flutter/generated_plugins.cmake:23 (add_subdirectory):
  add_subdirectory given source
  "flutter/ephemeral/.plugin_symlinks/desktop_drop/windows" which is not an
  existing directory.
Error: Unable to generate build files''';
      expect(explainFailure(output), FailureHint.restartApp);
      expect(explainFailure('flutter/ephemeral/.plugin_symlinks/x/windows exists'), isNull);
    });
  });

  group('InstallController with this computer', () {
    test('it is listed after the phones and only when the project supports it', () {
      expect(_controller(devices: [_pixel], project: _both).visibleDevices.map((d) => d.id), ['PX', 'macos']);
      expect(_controller(devices: [_pixel], project: _mobileOnly).visibleDevices.map((d) => d.id), ['PX']);
      expect(
        _controller(devices: [_pixel], project: _both, mac: false, windows: true).visibleDevices.last.id,
        'windows',
      );
    });

    test('a USB phone is the default, this computer is when there is no phone', () async {
      final withPhone = _controller(devices: [_pixel], project: _both);
      await withPhone.refreshDevices();
      expect(withPhone.selectedId, 'PX');
      final noPhone = _controller(project: _both);
      await noPhone.refreshDevices();
      expect(noPhone.selectedId, 'macos');
      expect(noPhone.plan.runnable, isTrue);
    });

    test('the default prefers a target the project supports over a USB phone it cannot build for', () async {
      const iosPhone = MobileDevice(
        id: 'IP',
        name: 'iPhone',
        platform: DevicePlatform.ios,
        link: DeviceLink.usb,
        developerModeOn: true,
      );
      const macOnly = FlutterProject(path: '/p/app', name: 'a', hasIos: false, hasAndroid: false, hasMacos: true);
      final c = _controller(devices: [iosPhone], project: macOnly);
      await c.refreshDevices();
      expect(c.selectedId, 'macos');
      // 지원하는 폰이 있으면 그 폰이 먼저다.
      final both = _controller(devices: [iosPhone], project: _both);
      await both.refreshDevices();
      expect(both.selectedId, 'IP');
    });

    test('opening a project that lacks the selected platform picks another target', () async {
      final dir = await Directory.systemTemp.createTemp('flutty_noMac');
      addTearDown(() => dir.delete(recursive: true));
      File('${dir.path}/pubspec.yaml').writeAsStringSync('name: demo\ndependencies:\n  flutter:\n    sdk: flutter\n');
      final c = _controller(devices: [_pixel], project: _both)..selectedId = 'macos';
      expect(c.device?.platform, DevicePlatform.macos);
      await c.openProject(dir.path);
      expect(c.device?.platform, DevicePlatform.android);
      expect(c.selectedId, 'PX');
    });

    test('desktop targets skip the cable and permission checks', () {
      final c = _controller(project: _both)..selectedId = 'macos';
      c.diagnostics = Diagnostics(
        flutter: const ToolInfo('3.47.1'),
        xcode: const ToolInfo('27.0'),
        adb: const ToolInfo(null),
        collectedAt: DateTime(2026, 10, 10),
      );
      final ids = c.checks.map((i) => i.id).toSet();
      expect(ids, isNot(contains(CheckId.connection)));
      expect(ids, isNot(contains(CheckId.developerMode)));
      expect(ids, isNot(contains(CheckId.androidAuth)));
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: home),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the Devices tab lists "This Mac" with the local badge', (tester) async {
      final c = _controller(devices: [_pixel], project: _both)..selectedId = 'macos';
      await pump(tester, DevicesTab(controller: c));
      expect(find.text('This Mac'), findsOneWidget);
      expect(find.text('This computer'), findsOneWidget);
      expect(find.text('Pixel 8'), findsOneWidget);
    });

    testWidgets('a missing adb is not nagged about while a desktop target is selected', (tester) async {
      final c = _controller(project: _both)..selectedId = 'macos';
      await c.runDiagnostics();
      await pump(tester, NextStepBanner(controller: c));
      expect(find.textContaining('adb wasn'), findsNothing);
    });
  });
}
