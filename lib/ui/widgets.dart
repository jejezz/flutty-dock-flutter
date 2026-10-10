import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleSmall)),
        ?trailing,
      ],
    ),
  );
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.chip),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11)),
  );
}

/// 번호 붙은 여러 줄 안내를 접었다 펴는 칸.
class StepsBox extends StatelessWidget {
  const StepsBox(this.steps, {super.key});

  final String steps;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: SelectableText(steps, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
  );
}
