import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../install/install_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

/// PATH에서 찾지 못하는 도구(flutter, adb)의 위치를 직접 지정하는 창. 지정한 값은 저장된다.
Future<void> showToolPathsDialog(BuildContext context, InstallController controller) => showDialog<void>(
  context: context,
  builder: (_) => _ToolPathsDialog(controller: controller),
);

class _ToolPathsDialog extends StatefulWidget {
  const _ToolPathsDialog({required this.controller});

  final InstallController controller;

  @override
  State<_ToolPathsDialog> createState() => _ToolPathsDialogState();
}

class _ToolPathsDialogState extends State<_ToolPathsDialog> {
  final _found = <String, String?>{};
  bool _loaded = false;

  InstallController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    for (final tool in InstallController.configurableTools) {
      _found[tool] = await c.locateTool(tool);
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _choose(String tool) async {
    final file = await openFile();
    if (file == null) return;
    await c.setToolPath(tool, file.path);
    await _reload();
  }

  Future<void> _reset(String tool) async {
    await c.setToolPath(tool, null);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String label(String tool) => tool == 'adb' ? l10n.toolPathAdb : l10n.toolPathFlutter;
    return AlertDialog(
      title: Text(l10n.toolPathsTitle),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.toolPathsHelp, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            for (final tool in InstallController.configurableTools) ...[
              Row(
                children: [
                  Expanded(child: Text(label(tool), style: theme.textTheme.labelLarge)),
                  InfoChip(c.isCustomTool(tool) ? l10n.toolPathCustom : l10n.toolPathAuto),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                !_loaded ? '…' : (_found[tool] ?? l10n.toolPathNotFound),
                style: AppFonts.mono.copyWith(
                  fontSize: 11.5,
                  color: _loaded && _found[tool] == null ? theme.colorScheme.error : null,
                ),
              ),
              Row(
                children: [
                  TextButton(onPressed: () => _choose(tool), child: Text(l10n.toolPathChoose)),
                  if (c.isCustomTool(tool)) TextButton(onPressed: () => _reset(tool), child: Text(l10n.toolPathAuto)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonClose))],
    );
  }
}
