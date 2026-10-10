import 'dart:io';

import '../core/command_runner.dart';
import 'mobile_device.dart';

/// 연결된 iPhone(macOS 전용)과 Android 기기를 찾는다.
abstract class DeviceService {
  Future<List<MobileDevice>> list();
}

class ProcessDeviceService implements DeviceService {
  ProcessDeviceService(this.runner);

  final CommandRunner runner;

  @override
  Future<List<MobileDevice>> list() async {
    final results = await Future.wait([if (Platform.isMacOS) _ios(), _android()]);
    return [for (final r in results) ...r];
  }

  Future<List<MobileDevice>> _ios() async {
    final dir = await Directory.systemTemp.createTemp('flutty_dock');
    try {
      final file = '${dir.path}/devices.json';
      final r = await runner.run(['xcrun', 'devicectl', 'list', 'devices', '--json-output', file], quiet: true);
      if (!r.ok || !await File(file).exists()) return const [];
      return parseDevicectl(await File(file).readAsString());
    } on FormatException {
      return const [];
    } finally {
      await dir.delete(recursive: true);
    }
  }

  Future<List<MobileDevice>> _android() async {
    final r = await runner.run(['adb', 'devices', '-l'], quiet: true);
    return r.ok ? parseAdbDevices(r.stdout) : const [];
  }
}
