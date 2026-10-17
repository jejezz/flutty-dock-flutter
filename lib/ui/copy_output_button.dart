import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// 명령 출력 전체를 클립보드에 복사하는 버튼. 스크롤 위치나 선택과 무관하게 전체를 복사한다.
class CopyOutputButton extends StatelessWidget {
  const CopyOutputButton({super.key, required this.text});

  /// 복사할 때마다 읽는다 (출력이 계속 늘어나므로).
  final String Function() text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.outputCopyAll,
      visualDensity: VisualDensity.compact,
      iconSize: 16,
      icon: const Icon(Icons.copy_rounded),
      onPressed: () async {
        final messenger = ScaffoldMessenger.maybeOf(context);
        await Clipboard.setData(ClipboardData(text: text()));
        messenger?.showSnackBar(SnackBar(content: Text(l10n.outputCopied), duration: const Duration(seconds: 1)));
      },
    );
  }
}
