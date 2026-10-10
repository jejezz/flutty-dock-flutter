// From jejezz/application-release-templates common/ @ conventions-v1.
//
// 새 앱의 시작점. 규약이 요구하는 연결을 한곳에 모았다:
//   창 크기(window_manager) · 추가 라이선스 · 설정 로드 · 라이트/다크 ·
//   언어 해석 · macOS 앱 메뉴 About · 앱 바 [테마 | 언어 | 정보] · 빈 상태.
// 기존 앱에는 통째로 덮어쓰지 말고 필요한 부분만 옮긴다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'about/about_dialog.dart';
import 'about/app_menu_bar.dart';
import 'about/extra_licenses.dart';
import 'app_identity.dart';
import 'core/command_log.dart';
import 'core/command_runner.dart';
import 'core/window_bounds.dart';
import 'devices/device_service.dart';
import 'doctor/diagnostics.dart';
import 'install/install_controller.dart';
import 'l10n/app_localizations.dart';
import 'settings/app_settings.dart';
import 'settings/window_prefs.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';
import 'update/update_scope.dart';
import 'update/update_service.dart';

final bool _isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerExtraLicenses();

  if (_isDesktop) {
    await windowManager.ensureInitialized();
    final windowPrefs = await WindowPrefs.load();
    final saved = await restorableWindowBounds(windowPrefs);
    // Windows는 runner(main.cpp)가 첫 크기와 위치를 정한다. Dart 쪽 setSize/center는
    // devicePixelRatio 오차로 창을 화면 오른쪽 밖에 놓을 수 있다.
    final options = WindowOptions(
      size: Platform.isWindows ? null : dockDefaultSize,
      minimumSize: dockMinimumSize,
      title: AppIdentity.displayName,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      // 사용자가 편집기 옆에 맞춰 둔 크기와 위치를 되살린다.
      if (usableBounds(saved)) {
        await windowManager.setBounds(saved);
      } else if (!Platform.isWindows) {
        await windowManager.center();
      }
      await windowManager.show();
      await windowManager.focus();
    });
    windowManager.addListener(WindowBoundsSaver(windowPrefs));
  }

  final settings = await AppSettings.load();
  // 데스크톱이 아니거나 UPDATE_SERVER 가 비어 있으면 null — 업데이트 확인 없음.
  final updates = await UpdateService.create();
  // UpdateScope 는 MaterialApp 위에 둔다 — 정보 창이 이것을 읽어 "업데이트 확인" 단추를 붙인다.
  runApp(
    UpdateScope(
      service: updates,
      child: App(settings: settings, updates: updates),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key, required this.settings, this.updates, this.deviceService, this.diagnosticsService});

  final AppSettings settings;
  final UpdateService? updates;

  /// 기기 목록·점검을 대신할 구현. 기본은 실제 기기와 이 Mac을 읽는다 (README 데모 녹화에서 가짜를 넣는다).
  final DeviceService? deviceService;
  final DiagnosticsService? diagnosticsService;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _log = CommandLog();
  late final _runner = CommandRunner(_log);
  late final _controller = InstallController(
    runner: _runner,
    deviceService: widget.deviceService ?? ProcessDeviceService(_runner),
    diagnosticsService: widget.diagnosticsService ?? ProcessDiagnosticsService(_runner),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_syncWindowBrightness);
    _syncWindowBrightness();
    widget.updates?.startAutomaticCheck(_navigatorKey);
    _controller.init();
  }

  @override
  void dispose() {
    widget.settings.removeListener(_syncWindowBrightness);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // 앱에서 다크를 골라도 OS가 라이트면 제목 표시줄은 밝게 남는다 (theming.md §4).
  @override
  void didChangePlatformBrightness() => _syncWindowBrightness();

  void _syncWindowBrightness() {
    if (!_isDesktop || Platform.isLinux) return;
    final brightness = switch (widget.settings.themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };
    windowManager.setBrightness(brightness);
  }

  void _showAbout() {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final l10n = AppLocalizations.of(context);
    showAppAboutDialog(
      context,
      tagline: l10n.aboutTagline,
      description: l10n.aboutDescription,
      onCheckForUpdates: widget.updates == null ? null : () => widget.updates!.checkManually(context),
    );
  }

  void _checkForUpdates() {
    final context = _navigatorKey.currentContext;
    if (context != null) widget.updates?.checkManually(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: widget.settings,
      child: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => MaterialApp(
          navigatorKey: _navigatorKey,
          title: AppIdentity.displayName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(dense: _isDesktop),
          darkTheme: AppTheme.dark(dense: _isDesktop),
          themeMode: widget.settings.themeMode,
          locale: widget.settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: AppSettings.resolveLocale,
          builder: (context, child) => AppMenuBar(
            onAbout: _showAbout,
            onCheckForUpdates: widget.updates == null ? null : _checkForUpdates,
            child: child!,
          ),
          home: HomeScreen(controller: _controller, log: _log, onAbout: _showAbout),
        ),
      ),
    );
  }
}
