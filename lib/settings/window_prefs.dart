import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

/// 창 크기·위치 저장 (편집기 옆에 맞춰 둔 자리를 다음 실행에 되살린다).
///
/// macOS는 논리 좌표로, Windows는 배율이 다른 모니터 사이에서도 어긋나지 않도록 물리 픽셀로 저장한다.
class WindowPrefs {
  WindowPrefs(this._prefs);

  static const boundsKey = 'window_bounds';
  static const pixelBoundsKey = 'window_pixel_bounds';

  final SharedPreferences _prefs;

  static Future<WindowPrefs> load() async => WindowPrefs(await SharedPreferences.getInstance());

  Rect? get bounds => _read(boundsKey);

  Rect? get pixelBounds => _read(pixelBoundsKey);

  Future<void> setBounds(Rect r) => _write(boundsKey, r);

  Future<void> setPixelBounds(Rect r) => _write(pixelBoundsKey, r);

  Rect? _read(String key) {
    final v = _prefs.getStringList(key);
    if (v == null || v.length != 4) return null;
    final n = v.map(double.tryParse).toList();
    if (n.contains(null)) return null;
    return Rect.fromLTWH(n[0]!, n[1]!, n[2]!, n[3]!);
  }

  Future<void> _write(String key, Rect r) =>
      _prefs.setStringList(key, [r.left, r.top, r.width, r.height].map((d) => d.toStringAsFixed(0)).toList());
}
