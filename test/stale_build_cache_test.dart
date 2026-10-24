import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/flutter/flutter_project.dart';
import 'package:flutty_dock/install/install_controller.dart';
import 'package:flutty_dock/install/install_plan.dart';
import 'package:flutty_dock/l10n/app_localizations.dart';
import 'package:flutty_dock/ui/banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 실제로 겪은 출력: Visual Studio 2022로 만든 캐시가 남은 프로젝트를 2026이 깔린 PC에서 빌드.
const _staleCache = '''
Launching lib\\main.dart on Windows in debug mode...
Building Windows application...
CMake Error: Error: generator : Visual Studio 18 2026
Does not match the generator used previously: Visual Studio 17 2022
Either remove the CMakeCache.txt file and CMakeFiles directory or choose a different binary directory.
Unable to generate build files
''';

void main() {
  group('explainFailure', () {
    test('a build cache from another Visual Studio version is told apart from a missing Visual Studio', () {
      expect(explainFailure(_staleCache), FailureHint.staleBuildCache);
    });

    test('CMake wraps long lines — the sentence is still found', () {
      expect(
        explainFailure('CMake Error: Error: generator : Visual Studio 18 2026\n  Does not match the generator\n  used previously: Visual Studio 17 2022'),
        FailureHint.staleBuildCache,
      );
    });

    test('merely mentioning Visual Studio no longer means the C++ components are missing', () {
      expect(explainFailure('-- Selecting Windows SDK version 10.0.26100.0 for Visual Studio 18 2026\nerror C2065: undeclared identifier'), isNull);
      expect(explainFailure('CMake Error at CMakeLists.txt:12: Visual Studio generator failed for another reason'), isNull);
    });

    test("Flutter's own messages for a missing toolchain still count", () {
      expect(explainFailure('Unable to find suitable Visual Studio toolchain. Please run `flutter doctor`'), FailureHint.visualStudio);
      expect(
        explainFailure('Visual Studio is missing necessary components. Please re-run the Visual Studio installer for the "Desktop development with C++" workload'),
        FailureHint.visualStudio,
      );
    });

    test('the other hints are unchanged', () {
      expect(explainFailure('Connection reset by peer'), FailureHint.useUsb);
      expect(explainFailure('Error: CocoaPods not installed.'), FailureHint.cocoapods);
    });
  });

  group('banner', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<InstallController> controller(_Runner runner) async {
      final c = InstallController(
        runner: runner,
        deviceService: _NoDevices(),
        hostIsMac: false,
        hostIsWindows: true,
      )
        ..project = const FlutterProject(path: 'D:/p/app', name: 'app', hasIos: false, hasAndroid: false, hasWindows: true)
        ..selectedId = 'windows'
        ..hint = FailureHint.staleBuildCache;
      return c;
    }

    Future<void> pump(WidgetTester tester, InstallController c) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ListenableBuilder(listenable: c, builder: (_, _) => NextStepBanner(controller: c))),
      ),
    );

    testWidgets('explains the stale cache and offers the clean button right there', (tester) async {
      final c = await controller(_Runner());
      await pump(tester, c);
      expect(find.textContaining('build cache from an older Visual Studio'), findsOneWidget);
      expect(find.textContaining('missing'), findsNothing, reason: 'not the misleading "components are missing" text');
      expect(find.widgetWithText(FilledButton, 'Clean & get packages'), findsOneWidget);
    });

    testWidgets('the button runs flutter clean and pub get in the project folder', (tester) async {
      final runner = _Runner();
      final c = await controller(runner);
      await pump(tester, c);
      await tester.tap(find.widgetWithText(FilledButton, 'Clean & get packages'));
      await tester.pump();
      expect(runner.ran, [
        ['flutter', 'clean'],
        ['flutter', 'pub', 'get'],
      ]);
      expect(runner.cwds, everyElement('D:/p/app'));
      expect(c.cleanResult, isTrue);
    });
  });
}

class _NoDevices implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [];
}

class _Runner extends CommandRunner {
  _Runner() : super(CommandLog());
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
    return const CommandResult(0, '', '');
  }
}
