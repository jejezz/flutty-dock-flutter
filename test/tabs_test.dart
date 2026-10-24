import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/command_runner.dart';
import 'package:flutty_dock/devices/device_service.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/install/install_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoDevices implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [];
}

Future<InstallController> _init(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  final c = InstallController(runner: CommandRunner(CommandLog()), deviceService: _NoDevices());
  await c.init();
  return c;
}

int _indexOf(String id) => InstallController.tabIds.indexOf(id);

void main() {
  test('the tab order', () {
    expect(InstallController.tabIds, ['run', 'git', 'devices', 'signing', 'doctor', 'log']);
  });

  group('saved tab', () {
    test('nothing saved opens the first tab', () async {
      final c = await _init({});
      expect(c.tabIndex, 0);
      expect(c.tabLoaded, isTrue);
    });

    test('the old number-based value still points at the same tab after the Git tab was added', () async {
      // 예전 순서: 0 실행 · 1 기기 · 2 서명 · 3 점검 · 4 기록
      expect((await _init({'last_tab': 0})).tabIndex, _indexOf('run'));
      expect((await _init({'last_tab': 1})).tabIndex, _indexOf('devices'));
      expect((await _init({'last_tab': 2})).tabIndex, _indexOf('signing'));
      expect((await _init({'last_tab': 3})).tabIndex, _indexOf('doctor'));
      expect((await _init({'last_tab': 4})).tabIndex, _indexOf('log'));
    });

    test('an out-of-range old number or an unknown name falls back to the first tab', () async {
      expect((await _init({'last_tab': 9})).tabIndex, 0);
      expect((await _init({'last_tab': -1})).tabIndex, 0);
      expect((await _init({'last_tab_id': 'nope'})).tabIndex, 0);
    });

    test('the name-based value wins over the old number', () async {
      final c = await _init({'last_tab': 3, 'last_tab_id': 'git'});
      expect(c.tabIndex, _indexOf('git'));
    });

    test('choosing a tab saves its name, and it is restored by name', () async {
      final c = await _init({});
      c.setTab(_indexOf('signing'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_tab_id'), 'signing');

      final again = InstallController(runner: CommandRunner(CommandLog()), deviceService: _NoDevices());
      await again.init();
      expect(again.tabIndex, _indexOf('signing'));
    });

    test('setTab ignores numbers outside the tabs', () async {
      final c = await _init({});
      c.setTab(99);
      c.setTab(-1);
      expect(c.tabIndex, 0);
    });
  });
}
