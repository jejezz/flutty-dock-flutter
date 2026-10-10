// README 데모 GIF를 만들 때 쓰는 장면 스크립트 (macOS).
//
//   flutter test integration_test/readme_demo_test.dart -d macos \
//     --dart-define=DEMO_ROOT=$PWD --dart-define=DEMO_PROJECT=/tmp/hello_app
//
// 앱 창을 진짜로 조작하는 동안 `tool/readme/capture.sh record`가 창을 녹화한다. 끝나면
// `tool/readme/capture.sh gif`로 docs/screenshots/demo.gif를 만든다.
//
// 기기와 점검 결과는 **가짜**다 — 내 기기 시리얼, 인증서 이름, Team ID가 화면에 나오지 않게 한다.
// 프로젝트는 진짜(DEMO_PROJECT)이고, Build & install의 첫 단계는 실제 명령으로 실행된다.
//
// DEMO_PROJECT의 ios/Runner.xcodeproj에서 DEVELOPMENT_TEAM 줄을 지워 두어야 실제 Team이 보이지 않는다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/doctor/diagnostics.dart';
import 'package:flutty_dock/doctor/signing_info.dart';
import 'package:flutty_dock/flutter/flutter_project.dart';
import 'package:flutty_dock/main.dart';
import 'package:flutty_dock/settings/app_settings.dart';
import 'package:flutty_dock/update/update_scope.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

const _root = String.fromEnvironment('DEMO_ROOT');
const _project = String.fromEnvironment('DEMO_PROJECT', defaultValue: '/tmp/hello_app');
const _recordSeconds = 26;

class _DemoDevices implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [
    MobileDevice(
      id: 'DEMO0PIXEL8',
      name: 'Pixel 8',
      model: 'Pixel 8',
      osVersion: '16',
      platform: DevicePlatform.android,
      link: DeviceLink.usb,
    ),
    MobileDevice(
      id: '00008130-000A1B2C3D4E5F67',
      name: 'Demo iPhone',
      model: 'iPhone 15 Pro',
      osVersion: '26.0',
      platform: DevicePlatform.ios,
      link: DeviceLink.usb,
      developerModeOn: true,
    ),
  ];
}

class _DemoDiagnostics implements DiagnosticsService {
  @override
  Future<Diagnostics> collect(FlutterProject? project) async {
    final now = DateTime.now();
    return Diagnostics(
      flutter: const ToolInfo('3.47.1'),
      xcode: const ToolInfo('27.0'),
      adb: const ToolInfo('37.0.1'),
      certs: [
        SigningCert(
          name: 'Apple Development: Jane Appleseed',
          teamId: 'ABCDE12345',
          expires: now.add(const Duration(days: 300)),
          hasPrivateKey: true,
        ),
      ],
      profiles: [
        ProfileInfo(
          name: 'iOS Team Provisioning Profile: hello_app',
          appId: 'ABCDE12345.*',
          teamId: 'ABCDE12345',
          created: now.subtract(const Duration(days: 5)),
          expires: now.add(const Duration(days: 360)),
          deviceCount: 3,
        ),
      ],
      androidSigning: AndroidSigning.debugKey,
      collectedAt: now,
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('README demo', (tester) async {
    expect(_root, isNotEmpty, reason: 'pass --dart-define=DEMO_ROOT=<repository root>');
    SharedPreferences.setMockInitialValues({
      'last_project': _project,
      'last_tab': 0,
      'theme_mode': 'light',
      'app_locale': 'en',
      'build_mode': 'release',
    });
    await windowManager.ensureInitialized();
    await windowManager.setSize(const Size(440, 900));
    await windowManager.center();
    await windowManager.focus();

    final settings = await AppSettings.load();
    await tester.pumpWidget(
      UpdateScope(
        service: null,
        child: App(settings: settings, deviceService: _DemoDevices(), diagnosticsService: _DemoDiagnostics()),
      ),
    );

    // 실제 시간이 흐르게 하면서 화면을 계속 그린다 (진행 표시가 도는 것도 녹화된다).
    Future<void> hold(double seconds) async {
      final end = DateTime.now().add(Duration(milliseconds: (seconds * 1000).round()));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 50));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    Future<void> tap(Finder f, double after) async {
      await tester.tap(f.first);
      await hold(after);
    }

    Finder tab(String t) => find.widgetWithText(Tab, t);

    // 앱이 프로젝트와 기기를 읽을 때까지.
    await hold(3);

    final recorder = await Process.start('bash', ['$_root/tool/readme/capture.sh', 'record', '$_recordSeconds'],
        workingDirectory: _root);
    recorder.stdout.drain<void>();
    recorder.stderr.drain<void>();
    await hold(5.5); // 녹화 시작 전 3초 안내 + 창 찾기

    // 1. 프로젝트와 실행할 명령 (Android, Release)
    await hold(2.2);
    await tap(find.text('Debug'), 1.6);
    await tap(find.text('Release'), 1.0);

    // 2. 기기를 iPhone으로 바꾸면 iOS 명령(서명 포함)으로 바뀐다
    await tap(tab('Devices'), 1.4);
    await tap(find.text('Demo iPhone'), 1.2);
    await tap(tab('Install'), 3.0);

    // 3. 점검 탭과 서명 탭
    await tap(tab('Doctor'), 2.6);
    await tap(tab('Signing'), 2.2);

    // 4. Android로 돌아가 빌드 & 설치를 시작한다
    await tap(tab('Devices'), 1.0);
    await tap(find.text('Pixel 8'), 0.8);
    await tap(tab('Install'), 1.2);
    await tap(find.text('Build & install'), 5.0);
    await tap(find.text('Cancel'), 1.0);

    await recorder.exitCode.timeout(const Duration(seconds: 30), onTimeout: () => -1);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
