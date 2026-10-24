import 'dart:io';

import 'package:flutter/material.dart';

import '../app_identity.dart';
import '../core/window_bounds.dart';
import '../install/install_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 타이틀 바의 프로젝트 이름 단추. 누르면 메뉴가 열린다 (Branch Dock과 같은 방식):
/// 최근 프로젝트 · 다른 폴더 열기 · 화면 오른쪽/왼쪽에 붙이기.
class ProjectMenuButton extends StatelessWidget {
  const ProjectMenuButton({
    super.key,
    required this.controller,
    required this.onOpenFolder,
    this.onDock = dockWindow,
  });

  final InstallController controller;

  /// "다른 폴더 열기…" — 폴더 고르기 창을 띄운다.
  final VoidCallback onOpenFolder;

  /// 창을 화면 가장자리에 붙인다. 테스트에서 바꾼다.
  final Future<void> Function(DockSide side) onDock;

  /// 단축키 이름: macOS는 ⌘, 그 밖은 Ctrl.
  static String get openShortcutLabel => Platform.isMacOS ? '⌘O' : 'Ctrl+O';

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: controller, builder: (context, _) => _menu(context));

  /// 지워졌거나 옮겨진 폴더는 뺀 최근 프로젝트. 메뉴를 열 때마다 새로 읽는다.
  List<String> _recents() => [
    for (final p in controller.recentProjects)
      if (Directory(p).existsSync()) p,
  ];

  Widget _menu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopupMenuButton<Object>(
      tooltip: l10n.titleMenuTooltip,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
      onSelected: (value) {
        if (value is String) {
          controller.openProject(value);
        } else if (value is DockSide) {
          onDock(value);
        } else {
          onOpenFolder();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<Object>(
          enabled: false,
          height: 28,
          child: Text(l10n.menuRecent, style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
        ),
        if (_recents().isEmpty)
          PopupMenuItem<Object>(enabled: false, child: Text(l10n.menuRecentEmpty, style: theme.textTheme.bodySmall))
        else
          for (final p in _recents())
            PopupMenuItem<Object>(
              value: p,
              height: 48,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: _isCurrent(p) ? const Icon(Icons.check_rounded, size: 18) : null,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_folderName(p), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          p,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.userContent.copyWith(fontSize: 11, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        const PopupMenuDivider(),
        PopupMenuItem<Object>(
          value: _openFolder,
          child: Row(
            children: [
              const Icon(Icons.folder_open_rounded, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.menuOpenFolder, overflow: TextOverflow.ellipsis)),
              Text(openShortcutLabel, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<Object>(
          value: DockSide.right,
          child: Row(
            children: [
              const Icon(Icons.align_horizontal_right_rounded, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.menuDockRight, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        PopupMenuItem<Object>(
          value: DockSide.left,
          child: Row(
            children: [
              const Icon(Icons.align_horizontal_left_rounded, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.menuDockLeft, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_rounded, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                controller.project?.name ?? AppIdentity.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }

  bool _isCurrent(String p) {
    final current = controller.project?.path;
    return current != null && samePath(p, current);
  }

  static const _openFolder = Object();

  /// 경로의 마지막 폴더 이름.
  static String _folderName(String path) {
    final parts = path.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }
}
