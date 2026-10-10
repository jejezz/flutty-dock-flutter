import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/doctor/diagnostics.dart';
import 'package:flutty_dock/flutter/flutter_project.dart';
import 'package:flutty_dock/install/install_controller.dart';
import 'package:flutty_dock/l10n/app_localizations.dart';
import 'package:flutty_dock/ui/devices_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Devices implements DeviceService {
  _Devices(this.list_);
  final List<MobileDevice> list_;
  @override
  Future<List<MobileDevice>> list() async => list_;
}

class _Diag implements DiagnosticsService {
  _Diag({this.adb = true, this.xcode = true});
  final bool adb;
  final bool xcode;

  @override
  Future<Diagnostics> collect(FlutterProject? project) async => Diagnostics(
    flutter: const ToolInfo('3.47.1'),
    xcode: ToolInfo(xcode ? '27.0' : null),
    adb: ToolInfo(adb ? '37.0.1' : null),
    collectedAt: DateTime(2026, 10, 10),
  );
}

Future<void> _pump(WidgetTester tester, {List<MobileDevice> devices = const [], _Diag? diag}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(440, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = InstallController(
    runner: CommandRunner(CommandLog(), path: '/usr/bin'),
    deviceService: _Devices(devices),
    diagnosticsService: diag ?? _Diag(),
  );
  await c.init();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: DevicesTab(controller: c)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with no device the tab says how to connect one', (tester) async {
    await _pump(tester);
    expect(find.textContaining('No device is connected over USB'), findsOneWidget);
    expect(find.textContaining('charge-only cable'), findsOneWidget);
    expect(find.text('Possible reasons no device shows up'), findsNothing);
  });

  testWidgets('a missing adb is listed as a likely reason, with the tool paths button', (tester) async {
    await _pump(tester, diag: _Diag(adb: false));
    expect(find.text('Possible reasons no device shows up'), findsOneWidget);
    expect(find.text('adb wasn\'t found (needed to install on Android)'), findsOneWidget);
    expect(find.text('Set tool paths…'), findsOneWidget);
  });

  testWidgets('a missing Xcode is listed too (macOS), without the adb button', (tester) async {
    await _pump(tester, diag: _Diag(xcode: false));
    expect(find.text('Xcode wasn\'t found'), findsOneWidget);
    expect(find.text('Set tool paths…'), findsNothing);
  });

  testWidgets('once a device is listed the reasons and the how-to disappear', (tester) async {
    await _pump(
      tester,
      diag: _Diag(adb: false),
      devices: const [MobileDevice(id: 'A', name: 'Pixel 8', platform: DevicePlatform.android, link: DeviceLink.usb)],
    );
    expect(find.text('Pixel 8'), findsOneWidget);
    expect(find.text('Possible reasons no device shows up'), findsNothing);
    expect(find.textContaining('charge-only cable'), findsNothing);
  });
}
