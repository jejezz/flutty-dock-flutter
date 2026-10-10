import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 복사할 수 있는 명령 한 줄 — 버튼이 실행하는 명령을 그대로 보여 준다.
class CommandText extends StatelessWidget {
  const CommandText(this.command, {super.key});

  final String command;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: SelectableText(command, style: AppFonts.mono.copyWith(fontSize: 11.5))),
      Tooltip(
        message: AppLocalizations.of(context).homeCopyCommand,
        child: InkWell(
          onTap: () => Clipboard.setData(ClipboardData(text: command)),
          child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.copy_rounded, size: 14)),
        ),
      ),
    ],
  );
}
