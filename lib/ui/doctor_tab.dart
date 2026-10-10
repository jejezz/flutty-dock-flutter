import 'package:flutter/material.dart';

import '../doctor/checks.dart';
import '../install/install_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'check_tile.dart';
import 'tool_paths_dialog.dart';

/// 점검 탭: 도구·기기·서명 점검 전체와 다시 점검 버튼.
class DoctorTab extends StatelessWidget {
  const DoctorTab({super.key, required this.controller});

  final InstallController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final checks = controller.checks;
    final at = controller.diagnostics?.collectedAt;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                at == null ? l10n.doctorNever : l10n.doctorCollected(TimeOfDay.fromDateTime(at).format(context)),
                style: theme.textTheme.bodySmall,
              ),
            ),
            FilledButton.tonal(
              onPressed: controller.diagnosing ? null : controller.runDiagnostics,
              child: Text(controller.diagnosing ? l10n.doctorRunning : l10n.doctorRun),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: () => showToolPathsDialog(context, controller), child: Text(l10n.toolPathsOpen)),
        ),
        CheckList(checks),
        if (checks.isNotEmpty && firstProblem(checks) == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(l10n.doctorAllGood, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success)),
          ),
      ],
    );
  }
}
