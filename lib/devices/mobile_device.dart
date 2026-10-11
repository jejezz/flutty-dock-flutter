import 'dart:convert';

import '../flutter/flutter_project.dart';

/// `macos`·`windows`는 이 컴퓨터 자신(데스크톱 빌드). 프로젝트가 그 플랫폼을 이미 지원할 때만 나온다.
enum DevicePlatform { ios, android, macos, windows }

/// `local`은 이 컴퓨터 — 케이블이 필요 없다.
enum DeviceLink { usb, wireless, local }

/// 빌드·설치 대상 하나: USB로 연결된 실기기, 또는 이 컴퓨터(데스크톱).
class MobileDevice {
  const MobileDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.link,
    this.model,
    this.osVersion,
    this.developerModeOn,
    this.authorized = true,
  });

  /// iOS는 UDID, Android는 adb 시리얼 — 명령의 `--device`/`-s`에 그대로 쓴다.
  final String id;
  final String name;
  final DevicePlatform platform;
  final DeviceLink link;
  final String? model;
  final String? osVersion;

  /// iOS만: 개발자 모드가 켜져 있는지. 알 수 없으면 null.
  final bool? developerModeOn;

  /// Android만: 이 컴퓨터의 USB 디버깅을 승인했는지.
  final bool authorized;

  bool get isUsb => link == DeviceLink.usb;

  /// 이 컴퓨터의 데스크톱 빌드인지.
  bool get isDesktop => platform == DevicePlatform.macos || platform == DevicePlatform.windows;
}

/// `xcrun devicectl list devices --json-output`의 결과에서 **실기기**만 읽는다.
/// 시뮬레이터(`reality: simulated`)는 뺀다. `transportType`이 `wired`면 USB다.
List<MobileDevice> parseDevicectl(String json) {
  final root = jsonDecode(json) as Map<String, dynamic>;
  final devices = ((root['result'] as Map<String, dynamic>?)?['devices'] as List<dynamic>?) ?? const [];
  final out = <MobileDevice>[];
  for (final d in devices.cast<Map<String, dynamic>>()) {
    final hw = (d['hardwareProperties'] as Map<String, dynamic>?) ?? const {};
    if (hw['reality'] != 'physical' || hw['platform'] != 'iOS') continue;
    final props = (d['deviceProperties'] as Map<String, dynamic>?) ?? const {};
    final conn = (d['connectionProperties'] as Map<String, dynamic>?) ?? const {};
    final mode = props['developerModeStatus'];
    out.add(
      MobileDevice(
        id: (hw['udid'] ?? d['identifier']) as String,
        name: (props['name'] ?? hw['marketingName'] ?? 'iPhone') as String,
        model: hw['marketingName'] as String?,
        osVersion: props['osVersionNumber'] as String?,
        platform: DevicePlatform.ios,
        link: conn['transportType'] == 'wired' ? DeviceLink.usb : DeviceLink.wireless,
        developerModeOn: mode == null ? null : mode == 'enabled',
      ),
    );
  }
  return out;
}

/// `adb devices -l`를 읽는다. 시리얼에 `:`나 `_adb-tls`가 있으면 무선 연결이다.
List<MobileDevice> parseAdbDevices(String text) {
  final out = <MobileDevice>[];
  for (final line in const LineSplitter().convert(text)) {
    final m = RegExp(r'^(\S+)\s+(device|unauthorized|offline)\b(.*)$').firstMatch(line.trim());
    if (m == null) continue;
    final serial = m[1]!;
    final model = RegExp(r'model:(\S+)').firstMatch(m[3]!)?[1]?.replaceAll('_', ' ');
    out.add(
      MobileDevice(
        id: serial,
        name: model ?? serial,
        model: model,
        platform: DevicePlatform.android,
        link: serial.contains(':') || serial.contains('_adb-tls') ? DeviceLink.wireless : DeviceLink.usb,
        authorized: m[2] == 'device',
      ),
    );
  }
  return out;
}

/// 이 컴퓨터를 대상으로 쓸 수 있으면 그 "기기". **프로젝트가 이 OS의 데스크톱을 이미 지원할 때만**
/// (macOS면 `macos/`, Windows면 `windows/` 폴더가 있을 때) 돌려준다 — 없는 플랫폼을 만들어 주지는 않는다.
MobileDevice? hostDesktopDevice(FlutterProject? project, {required bool isMac, required bool isWindows}) {
  if (project == null) return null;
  if (isMac && project.hasMacos) {
    return const MobileDevice(id: 'macos', name: 'macOS', platform: DevicePlatform.macos, link: DeviceLink.local);
  }
  if (isWindows && project.hasWindows) {
    return const MobileDevice(id: 'windows', name: 'Windows', platform: DevicePlatform.windows, link: DeviceLink.local);
  }
  return null;
}
