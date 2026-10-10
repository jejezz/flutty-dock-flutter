import 'package:flutter/material.dart';

import '../core/command_log.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'command_text.dart';

/// 기록 탭: 지금까지 실행한 모든 명령과 출력 (최신이 위).
class LogTab extends StatelessWidget {
  const LogTab({super.key, required this.log});

  final CommandLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: log,
      builder: (context, _) {
        final entries = log.entries.reversed.toList();
        if (entries.isEmpty) {
          return Center(child: Text(l10n.logEmpty, style: theme.textTheme.bodySmall));
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: log.clear, child: Text(l10n.logClear)),
            ),
            for (final e in entries)
              Card(
                child: ExpansionTile(
                  dense: true,
                  leading: Icon(
                    e.running
                        ? Icons.hourglass_empty_rounded
                        : e.succeeded
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 16,
                    color: e.running ? null : (e.succeeded ? AppColors.success : theme.colorScheme.error),
                  ),
                  title: Text(
                    e.commandLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.mono.copyWith(fontSize: 11.5),
                  ),
                  subtitle: Text(
                    e.running ? l10n.logRunning : l10n.logExit('${e.exitCode ?? -1}'),
                    style: theme.textTheme.bodySmall,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommandText(e.commandLine),
                    const SizedBox(height: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: SingleChildScrollView(
                        child: SelectableText(e.output.trimRight(), style: AppFonts.mono.copyWith(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
