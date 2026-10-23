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
import 'package:flutty_dock/l10n/app_localizations.dart';
import 'package:flutty_dock/settings/app_settings.dart';
import 'package:flutty_dock/ui/doctor_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime.utc(2026, 10, 10);

const _project = FlutterProject(path: 'C:/p/app', name: 'app', hasIos: false, hasAndroid: true, hasWindows: true);
const _pc = MobileDevice(id: 'windows', name: 'This PC', platform: DevicePlatform.windows, link: DeviceLink.usb);
const _galaxy = MobileDevice(id: 'R3CY', name: 'SM S931N', platform: DevicePlatform.android, link: DeviceLink.usb);

Diagnostics _diag({WindowsEnv? windows}) => Diagnostics(
  flutter: const ToolInfo('3.47.1'),
  xcode: const ToolInfo(null),
  adb: const ToolInfo('1.0.41'),
  windows: windows,
  collectedAt: _now,
);

List<CheckItem> _checks(Diagnostics d, MobileDevice? device, {bool windowsHost = true}) => buildChecks(
  diagnostics: d,
  project: _project,
  device: device,
  teamId: null,
  hostIsMac: false,
  hostIsWindows: windowsHost,
  now: _now,
);

CheckItem? _find(List<CheckItem> items, CheckId id) => items.where((i) => i.id == id).firstOrNull;

void main() {
  group('parsing', () {
    test('developer mode is on only for a DWORD of 1', () {
      const on = r'''
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock
    AllowDevelopmentWithoutDevLicense    REG_DWORD    0x1
''';
      expect(parseDeveloperMode(on), isTrue);
      expect(parseDeveloperMode(on.replaceFirst('0x1', '0x0')), isFalse);
      expect(parseDeveloperMode(on.replaceFirst('0x1', '0x10')), isFalse);
      expect(parseDeveloperMode(''), isFalse);
      expect(parseDeveloperMode('ERROR: The system was unable to find the specified registry key or value.'), isFalse);
    });

    test('vswhere: first non-empty line is the version', () {
      expect(parseVsWhereVersion('18.10.12217.157\r\n'), '18.10.12217.157');
      expect(parseVsWhereVersion('\n  \n17.9.1\n'), '17.9.1');
      expect(parseVsWhereVersion(''), isNull);
      expect(parseVsWhereVersion('  \r\n'), isNull);
    });
  });

  group('buildChecks on a Windows host', () {
    test('developer mode on is ok, off is only a warning (never blocks)', () {
      final on = _find(_checks(_diag(windows: const WindowsEnv(developerMode: true)), _galaxy), CheckId.windowsDeveloperMode);
      expect(on?.status, CheckStatus.ok);
      final off = _checks(_diag(windows: const WindowsEnv(developerMode: false)), _galaxy);
      expect(_find(off, CheckId.windowsDeveloperMode)?.status, CheckStatus.warn);
      expect(firstProblem(off), isNull, reason: 'a warning is not a blocker');
    });

    test('an unknown developer mode (reg.exe missing) adds no item', () {
      final items = _checks(_diag(windows: const WindowsEnv()), _galaxy);
      expect(_find(items, CheckId.windowsDeveloperMode), isNull);
    });

    test('Visual Studio matters only when this PC is the target', () {
      const noVs = WindowsEnv(developerMode: true);
      expect(_find(_checks(_diag(windows: noVs), _galaxy), CheckId.visualStudio), isNull);
      expect(_find(_checks(_diag(windows: noVs), null), CheckId.visualStudio), isNull);

      final missing = _checks(_diag(windows: noVs), _pc);
      expect(_find(missing, CheckId.visualStudio)?.status, CheckStatus.fail);
      expect(firstProblem(missing)?.id, CheckId.visualStudio, reason: 'it blocks, so it reaches the banner');

      final found = _checks(_diag(windows: const WindowsEnv(developerMode: true, visualStudio: '18.10.1')), _pc);
      final vs = _find(found, CheckId.visualStudio);
      expect(vs?.status, CheckStatus.ok);
      expect(vs?.params['version'], '18.10.1');
    });

    test('nothing is added off Windows or without Windows data', () {
      final env = _diag(windows: const WindowsEnv(developerMode: false));
      final mac = _checks(env, _pc, windowsHost: false);
      expect(_find(mac, CheckId.windowsDeveloperMode), isNull);
      expect(_find(mac, CheckId.visualStudio), isNull);
      final none = _checks(_diag(), _pc);
      expect(_find(none, CheckId.windowsDeveloperMode), isNull);
    });
  });

  group('controller and tab', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('the Doctor tab lists both items with steps when they are a problem', (tester) async {
      final c = InstallController(
        runner: CommandRunner(CommandLog()),
        deviceService: _NoDevices(),
        diagnosticsService: _Diag(_diag(windows: const WindowsEnv(developerMode: false))),
        hostIsMac: false,
        hostIsWindows: true,
      )
        ..project = _project
        ..selectedId = 'windows';
      await c.runDiagnostics();
      expect(c.checks.map((i) => i.id), containsAll([CheckId.windowsDeveloperMode, CheckId.visualStudio]));

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
            home: Scaffold(body: DoctorTab(controller: c)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Developer Mode is off'), findsOneWidget);
      expect(find.textContaining("'Desktop development with C++' is missing"), findsOneWidget);
    });
  });
}

class _NoDevices implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [];
}

class _Diag implements DiagnosticsService {
  _Diag(this.d);
  final Diagnostics d;
  @override
  Future<Diagnostics> collect(FlutterProject? project) async => d;
}
