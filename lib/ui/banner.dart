import 'package:flutter/material.dart';

import '../doctor/checks.dart';
import '../install/install_controller.dart';
import '../install/install_plan.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'check_text.dart';
import 'tool_paths_dialog.dart';
import 'widgets.dart';

/// 지금 막힌 것 하나만 알려 주는 배너. 막힌 것이 없으면 아무것도 그리지 않는다.
///
/// 우선순위: 실행 전 막는 이유 → 방금 실패한 원인 → 점검에서 실패한 첫 항목.
class NextStepBanner extends StatelessWidget {
  const NextStepBanner({super.key, required this.controller});

  final InstallController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (controller.running) return const SizedBox.shrink();

    String? text;
    String? steps;
    var toolMissing = false;
    final blockers = controller.plan.blockers;
    if (blockers.isNotEmpty) {
      text = blockerText(l10n, blockers.first);
      steps = blockerSteps(l10n, blockers.first);
    } else if (controller.missingCommand != null) {
      text = l10n.hintMissingCommand(controller.missingCommand!);
      toolMissing = InstallController.configurableTools.contains(controller.missingCommand);
    } else if (controller.hint != null) {
      text = failureHintText(l10n, controller.hint!);
      steps = failureHintSteps(l10n, controller.hint!);
      toolMissing = controller.hint == FailureHint.noAdb;
    } else {
      final problem = firstProblem(controller.checks);
      if (problem != null) {
        text = checkTitle(l10n, problem);
        steps = checkSteps(l10n, problem);
        toolMissing = problem.id == CheckId.flutter;
      }
    }
    if (text == null) return const SizedBox.shrink();

    // ExpansionTile(ListTile)은 가장 가까운 Material에 그리므로 배경색은 Container가 아니라 Material로 준다.
    return Material(
      color: AppColors.warning.withValues(alpha: 0.14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.warning),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.bannerNextStep, style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                        Text(text, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              if (toolMissing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => showToolPathsDialog(context, controller),
                    child: Text(l10n.toolPathsOpen),
                  ),
                ),
              if (steps != null)
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(left: 24, bottom: AppSpacing.sm),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(l10n.bannerShowSteps, style: theme.textTheme.labelMedium),
                    children: [StepsBox(steps)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
