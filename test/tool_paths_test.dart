import 'dart:io';

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
import 'package:flutty_dock/settings/app_settings.dart';
import 'package:flutty_dock/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Devices implements DeviceService {
  int calls = 0;
  @override
  Future<List<MobileDevice>> list() async {
    calls++;
    return const [];
  }
}

class _Diag implements DiagnosticsService {
  int calls = 0;
  @override
  Future<Diagnostics> collect(FlutterProject? project) async {
    calls++;
    return Diagnostics(
      flutter: const ToolInfo('3.47.1'),
      xcode: const ToolInfo('27.0'),
      adb: const ToolInfo(null),
      collectedAt: DateTime(2026, 10, 10),
    );
  }
}

void main() {
  group('CommandRunner tool paths', () {
    test('a configured tool replaces the bare name and its folder comes first on PATH', () async {
      final r = CommandRunner(CommandLog())..toolPaths = {'adb': '/opt/sdk/platform-tools/adb'};
      expect(r.executableFor('adb'), '/opt/sdk/platform-tools/adb');
      expect(r.executableFor('flutter'), 'flutter');
      expect((await r.effectivePath).startsWith('/opt/sdk/platform-tools${Platform.isWindows ? ';' : ':'}'), isTrue);
    });

    test('locate: a custom path must exist; otherwise it searches PATH', () async {
      final dir = await Directory.systemTemp.createTemp('flutty_tools');
      addTearDown(() => dir.delete(recursive: true));
      final exe = File('${dir.path}/adb')..writeAsStringSync('#!/bin/sh\n');
      final r = CommandRunner(CommandLog())..toolPaths = {'adb': exe.path};
      expect(await r.locate('adb'), exe.path);
      r.toolPaths = {'adb': '${dir.path}/missing'};
      expect(await r.locate('adb'), isNull);
      r.toolPaths = {};
      expect(await r.locate('definitely-not-a-real-tool-xyz'), isNull);
    });

    test('findExecutable finds a file in a PATH-style list', () async {
      final dir = await Directory.systemTemp.createTemp('flutty_find');
      addTearDown(() => dir.delete(recursive: true));
      File('${dir.path}/mytool${Platform.isWindows ? '.exe' : ''}').writeAsStringSync('x');
      final sep = Platform.isWindows ? ';' : ':';
      expect(findExecutable('mytool', '/nonexistent$sep${dir.path}'), isNotNull);
      expect(findExecutable('other', dir.path), isNull);
    });
  });

  group('InstallController tool paths', () {
    test('saving a path updates the runner, persists, and re-reads devices and diagnostics', () async {
      SharedPreferences.setMockInitialValues({});
      final devices = _Devices();
      final diag = _Diag();
      final c = InstallController(
        runner: CommandRunner(CommandLog()),
        deviceService: devices,
        diagnosticsService: diag,
      );
      await c.init();
      final before = (devices.calls, diag.calls);

      await c.setToolPath('adb', '/opt/sdk/platform-tools/adb');
      expect(c.runner.toolPaths['adb'], '/opt/sdk/platform-tools/adb');
      expect(c.isCustomTool('adb'), isTrue);
      expect(devices.calls, before.$1 + 1);
      expect(diag.calls, before.$2 + 1);
      expect((await SharedPreferences.getInstance()).getString('tool_path_adb'), '/opt/sdk/platform-tools/adb');

      await c.setToolPath('adb', null);
      expect(c.isCustomTool('adb'), isFalse);
      expect((await SharedPreferences.getInstance()).getString('tool_path_adb'), isNull);
    });

    test('a saved path is applied on the next start', () async {
      SharedPreferences.setMockInitialValues({'tool_path_flutter': '/opt/flutter/bin/flutter'});
      final c = InstallController(
        runner: CommandRunner(CommandLog()),
        deviceService: _Devices(),
        diagnosticsService: _Diag(),
      );
      await c.init();
      expect(c.runner.executableFor('flutter'), '/opt/flutter/bin/flutter');
    });
  });

  testWidgets('the Doctor tab opens the tool paths dialog and shows a missing custom path', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(440, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = InstallController(
      runner: CommandRunner(CommandLog(), path: '/usr/bin')..toolPaths = {'adb': '/nope/adb'},
      deviceService: _Devices(),
      diagnosticsService: _Diag(),
    );
    await c.runDiagnostics();
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
    await tester.tap(find.widgetWithText(Tab, 'Doctor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set tool paths…'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Tool paths'), findsOneWidget);
    expect(find.text('adb (Android SDK platform-tools)'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Not found'), findsWidgets);
  });
}
