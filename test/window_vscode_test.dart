import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
import 'package:flutty_dock/core/window_bounds.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/flutter/flutter_project.dart';
import 'package:flutty_dock/install/install_controller.dart';
import 'package:flutty_dock/settings/window_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Runner extends CommandRunner {
  _Runner(this.exitCode) : super(CommandLog());
  final int exitCode;
  final ran = <List<String>>[];

  @override
  Future<String> get path async => '/usr/bin';

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
    return CommandResult(exitCode, '', '');
  }
}

class _NoDevices implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [];
}

const _project = FlutterProject(path: '/p/my app', name: 'app', hasIos: true, hasAndroid: true);

void main() {
  group('WindowPrefs', () {
    test('saves and restores bounds, rounded to whole pixels', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await WindowPrefs.load();
      expect(prefs.bounds, isNull);
      await prefs.setBounds(const Rect.fromLTWH(1200.4, 80, 440, 960));
      await prefs.setPixelBounds(const Rect.fromLTWH(2400, 160, 880, 1920));
      final again = await WindowPrefs.load();
      expect(again.bounds, const Rect.fromLTWH(1200, 80, 440, 960));
      expect(again.pixelBounds, const Rect.fromLTWH(2400, 160, 880, 1920));
    });

    test('ignores malformed stored values', () async {
      SharedPreferences.setMockInitialValues({
        WindowPrefs.boundsKey: ['1', '2', 'x', '4'],
        WindowPrefs.pixelBoundsKey: ['1', '2'],
      });
      final prefs = await WindowPrefs.load();
      expect(prefs.bounds, isNull);
      expect(prefs.pixelBounds, isNull);
    });

    test('a saved size smaller than the dock minimum is not restored', () {
      expect(usableBounds(null), isFalse);
      expect(usableBounds(const Rect.fromLTWH(0, 0, 300, 960)), isFalse);
      expect(usableBounds(const Rect.fromLTWH(0, 0, 440, 400)), isFalse);
      expect(usableBounds(const Rect.fromLTWH(0, 0, 380, 560)), isTrue);
    });
  });

  group('open in VS Code', () {
    InstallController make(_Runner r, List<String>? command) => InstallController(
      runner: r,
      deviceService: _NoDevices(),
      vscodeCommand: (dir, {required path}) async => command == null ? null : [...command, dir],
    )..project = _project;

    test('runs the found command with the project folder and logs it', () async {
      final r = _Runner(0);
      final result = await make(r, ['open', '-b', 'com.microsoft.VSCode']).openInVsCode();
      expect(result, VsCodeResult.opened);
      expect(r.ran.single, ['open', '-b', 'com.microsoft.VSCode', '/p/my app']);
    });

    test('reports VS Code missing without running anything', () async {
      final r = _Runner(0);
      expect(await make(r, null).openInVsCode(), VsCodeResult.notFound);
      expect(r.ran, isEmpty);
    });

    test('reports a failing command', () async {
      expect(await make(_Runner(1), ['code']).openInVsCode(), VsCodeResult.failed);
    });

    test('does nothing without a project', () async {
      final r = _Runner(0);
      final c = make(r, ['code'])..project = null;
      expect(await c.openInVsCode(), VsCodeResult.notFound);
      expect(r.ran, isEmpty);
    });
  });
}
