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

/// 창을 붙일 화면 가장자리.
enum DockSide { left, right }

/// [workArea](작업 표시줄을 뺀 화면 영역)의 [side] 가장자리에 세로로 꽉 차게 붙인 창 자리.
/// 너비는 [width]를 쓰되 도킹 창의 최소 너비와 작업 영역 너비 사이로 맞춘다 (없으면 기본 너비).
ui.Rect dockedBounds(ui.Rect workArea, {required DockSide side, double? width}) {
  // 작업 영역이 최소 너비보다 좁아도(아주 작은 화면) 영역을 넘지 않게 맞춘다.
  final minWidth = dockMinimumSize.width < workArea.width ? dockMinimumSize.width : workArea.width;
  final w = (width ?? dockDefaultSize.width).clamp(minWidth, workArea.width).toDouble();
  final left = side == DockSide.left ? workArea.left : workArea.right - w;
  return ui.Rect.fromLTWH(left, workArea.top, w, workArea.height);
}

/// 창이 놓인 모니터(겹치는 면적이 가장 큰 것)의 작업 영역과 그 배율. 모니터 정보를 못 읽으면 null.
/// 영역은 [windowRect]와 같은 좌표계(물리 픽셀: Windows, 논리: 그 밖)로 돌려준다.
Future<({ui.Rect area, double scale})?> _workAreaFor(ui.Rect windowRect) async {
  try {
    ({ui.Rect area, double scale})? best;
    var bestOverlap = -1.0;
    for (final d in await screenRetriever.getAllDisplays()) {
      final scale = Platform.isWindows ? (d.scaleFactor ?? 1.0).toDouble() : 1.0;
      final pos = d.visiblePosition ?? ui.Offset.zero;
      final size = d.visibleSize ?? d.size;
      final area = ui.Rect.fromLTWH(pos.dx * scale, pos.dy * scale, size.width * scale, size.height * scale);
      final o = area.intersect(windowRect);
      final overlap = o.width <= 0 || o.height <= 0 ? 0.0 : o.width * o.height;
      if (overlap > bestOverlap) {
        bestOverlap = overlap;
        best = (area: area, scale: scale);
      }
    }
    return best;
  } on Object {
    return null;
  }
}

/// 창을 지금 있는 모니터의 [side] 가장자리에 붙인다 (작업 표시줄은 가리지 않고, 높이는 가득).
/// 좌표 변환은 저장한 자리를 되살릴 때와 같다: Windows는 물리 픽셀로 계산해 논리로 되돌린다.
Future<void> dockWindow(DockSide side) async {
  if (await windowManager.isMaximized()) await windowManager.unmaximize();
  final b = await windowManager.getBounds();
  final dpr = Platform.isWindows ? _devicePixelRatio() : 1.0;
  final physical = ui.Rect.fromLTWH(b.left * dpr, b.top * dpr, b.width * dpr, b.height * dpr);
  final found = await _workAreaFor(physical);
  if (found == null) return;
  final target = dockedBounds(found.area, side: side, width: physical.width);
  await windowManager.setBounds(
    ui.Rect.fromLTWH(target.left / dpr, target.top / dpr, target.width / dpr, target.height / dpr),
  );
}

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
