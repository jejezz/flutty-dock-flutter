import 'package:flutter/material.dart';

import '../doctor/checks.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'check_text.dart';
import 'widgets.dart';

IconData _icon(CheckStatus s) => switch (s) {
  CheckStatus.ok => Icons.check_circle_rounded,
  CheckStatus.warn => Icons.warning_amber_rounded,
  CheckStatus.fail => Icons.error_rounded,
  CheckStatus.info => Icons.info_outline_rounded,
};

Color _color(CheckStatus s, ThemeData t) => switch (s) {
  CheckStatus.ok => AppColors.success,
  CheckStatus.warn => AppColors.warning,
  CheckStatus.fail => t.colorScheme.error,
  CheckStatus.info => t.hintColor,
};

/// 점검 결과 한 줄 — 문제가 있으면 해결 단계를 펼쳐 볼 수 있다.
class CheckTile extends StatelessWidget {
  const CheckTile(this.item, {super.key});

  final CheckItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final steps = checkSteps(l10n, item);
    final note = checkNote(l10n, item);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(_icon(item.status), size: 16, color: _color(item.status, theme)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(checkTitle(l10n, item), style: theme.textTheme.bodyMedium),
              if (note != null) Text(note, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
      ],
    );
    if (steps == null) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: row);
    }
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 24, bottom: AppSpacing.sm),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        dense: true,
        title: row,
        children: [StepsBox(steps)],
      ),
    );
  }
}

/// 같은 종류의 점검 항목을 카드 하나로 묶는다.
class CheckList extends StatelessWidget {
  const CheckList(this.items, {super.key});

  final List<CheckItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Column(children: [for (final i in items) CheckTile(i)]),
      ),
    );
  }
}

/// 이 탭에서 보여 줄 항목만 골라 낸다.
List<CheckItem> only(List<CheckItem> all, Set<CheckId> ids) => [
  for (final i in all)
    if (ids.contains(i.id)) i,
];

/// 단계 안내가 없는 곳에서 쓰는 빈 섹션 제목 도우미.
Widget titled(String title, Widget child) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SectionTitle(title), child]);
