import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../settings/window_prefs.dart';

/// 편집기 옆에 세워 두는 도킹형 세로 창.
const dockDefaultSize = ui.Size(440, 960);
const dockMinimumSize = ui.Size(380, 560);

double _devicePixelRatio() => ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1.0;

/// 저장한 창 자리를 되살릴 수 있으면 window_manager 좌표(논리)로 돌려주고, 아니면 null.
///
/// Windows는 저장한 물리 픽셀 위치가 지금 연결된 모니터 안에 있을 때만 쓴다.
/// 보조 모니터에서 종료한 뒤 그 모니터가 없거나 배율이 다르면 null → runner가 정한 기본 위치를 쓴다.
Future<ui.Rect?> restorableWindowBounds(WindowPrefs prefs) async {
  if (!Platform.isWindows) return prefs.bounds;
  final px = prefs.pixelBounds;
  if (px == null) return null;
  final dpr = _devicePixelRatio();
  final logical = ui.Rect.fromLTWH(px.left / dpr, px.top / dpr, px.width / dpr, px.height / dpr);
  if (logical.width < dockMinimumSize.width || logical.height < dockMinimumSize.height) return null;
  try {
    for (final d in await screenRetriever.getAllDisplays()) {
      final scale = (d.scaleFactor ?? 1.0).toDouble();
      final pos = d.visiblePosition ?? ui.Offset.zero;
      final size = d.visibleSize ?? d.size;
      final area = ui.Rect.fromLTWH(pos.dx * scale, pos.dy * scale, size.width * scale, size.height * scale);
      final overlap = area.intersect(px);
      if (overlap.width >= 100 && overlap.height >= 100) return logical;
    }
  } on Object {
    // 모니터 정보를 못 읽으면 기본 위치를 쓴다.
  }
  return null;
}

/// 저장한 자리가 도킹 창으로 쓸 만한 크기인지.
bool usableBounds(ui.Rect? r) => r != null && r.width >= dockMinimumSize.width && r.height >= dockMinimumSize.height;

/// 창을 옮기거나 크기를 바꾸면 잠시 뒤 저장한다.
class WindowBoundsSaver with WindowListener {
  WindowBoundsSaver(this.prefs);

  final WindowPrefs prefs;
  Timer? _timer;

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () async {
      final b = await windowManager.getBounds();
      if (Platform.isWindows) {
        final dpr = _devicePixelRatio();
        await prefs.setPixelBounds(ui.Rect.fromLTWH(b.left * dpr, b.top * dpr, b.width * dpr, b.height * dpr));
      } else {
        await prefs.setBounds(b);
      }
    });
  }

  @override
  void onWindowResized() => _schedule();

  @override
  void onWindowMoved() => _schedule();
}
