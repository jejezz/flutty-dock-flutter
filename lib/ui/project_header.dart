import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/git_client.dart';
import '../core/vscode.dart';
import '../install/install_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

/// 탭 위에 늘 보이는 프로젝트 배너. 어느 탭을 보고 있어도 지금 어느 프로젝트인지, 어느 브랜치인지,
/// 원격과 같은지를 알 수 있다.
///
/// 브랜치·상태·플랫폼 칩(좁으면 줄바꿈)과 버튼 / 버전·경로. 프로젝트 이름은 타이틀 바에 있다. 프로젝트를 아직 안 열었으면 열기 안내를 보여 준다.
class ProjectHeader extends StatelessWidget {
  const ProjectHeader({super.key, required this.controller, required this.onOpen});

  final InstallController controller;
  final VoidCallback onOpen;

  Future<void> _openInVsCode(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.openInVsCode();
    if (result == VsCodeResult.opened) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(result == VsCodeResult.notFound ? l10n.vscodeNotFound : l10n.vscodeOpenFailed),
        action: result == VsCodeResult.notFound
            ? SnackBarAction(label: l10n.vscodeDownload, onPressed: () => launchUrl(vscodeDownloadUrl))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = controller.project;
    final git = controller.gitState;

    // 카드가 아니라 화면 폭을 가득 쓰는 납작한 배너 (Branch Dock처럼). 위의 타이틀 바에 프로젝트 이름이 있으니
    // 여기서는 되풀이하지 않고, 브랜치·상태·플랫폼 칩과 버전·경로를 보여 준다.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        child: p == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.homeProjectDrop, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(onPressed: onOpen, child: Text(l10n.homeProjectOpen)),
                  if (controller.projectError != null) _error(l10n, theme),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (git != null) ..._gitChips(context, git),
                              if (p.hasIos) InfoChip(l10n.homePlatformIos),
                              if (p.hasAndroid) InfoChip(l10n.homePlatformAndroid),
                              if (p.hasMacos) InfoChip(l10n.homePlatformMacos),
                              if (p.hasWindows) InfoChip(l10n.homePlatformWindows),
                            ],
                          ),
                        ),
                      ),
                      _iconButton(Icons.refresh_rounded, l10n.homeProjectReload, () => controller.openProject(p.path)),
                      _iconButton(Icons.code_rounded, l10n.homeOpenVsCode, () => _openInVsCode(context)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Tooltip(
                      message: p.path,
                      child: Text(
                        p.version == null ? p.path : '${p.version}  ·  ${p.path}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.userContent.copyWith(fontSize: 12, color: theme.hintColor),
                      ),
                    ),
                  ),
                  if (controller.projectError != null)
                    Padding(padding: const EdgeInsets.only(right: AppSpacing.sm), child: _error(l10n, theme)),
                ],
              ),
      ),
    );
  }

  Widget _error(AppLocalizations l10n, ThemeData theme) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Text(
      l10n.homeProjectNotFlutter(controller.projectError!),
      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
    ),
  );

  Widget _iconButton(IconData icon, String tooltip, VoidCallback onPressed) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    iconSize: 20,
    icon: Icon(icon),
    onPressed: onPressed,
  );
}

/// 브랜치 알약과, 원격과의 관계를 글자로 알려 주는 칩: `main` `✓ 최신` / `↓ 2개 받을 수 있음` / `● 변경 있음`.
List<Widget> _gitChips(BuildContext context, GitState git) {
  final l10n = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  final warn = AppColors.warning.withValues(alpha: 0.2);
  return [
    _Chip(
      label: git.branch ?? l10n.gitDetached,
      icon: Icons.account_tree_outlined,
      mono: true,
      color: scheme.surfaceContainerHighest,
      maxWidth: 190,
    ),
    if (!git.hasUpstream)
      _Chip(label: l10n.gitChipNoUpstream, tooltip: l10n.gitNoUpstream, color: scheme.surfaceContainerHighest)
    else if (git.ahead == 0 && git.behind == 0)
      _Chip(label: l10n.gitChipUpToDate, tooltip: l10n.gitUpToDate, color: AppColors.success.withValues(alpha: 0.18))
    else ...[
      if (git.behind > 0) _Chip(label: l10n.gitChipBehind(git.behind), tooltip: l10n.gitBehind(git.behind), color: warn),
      if (git.ahead > 0)
        _Chip(label: l10n.gitChipAhead(git.ahead), tooltip: l10n.gitAhead(git.ahead), color: scheme.surfaceContainerHighest),
    ],
    if (git.dirty) _Chip(label: l10n.gitChipDirty, tooltip: l10n.gitDirty, color: warn),
  ];
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.tooltip, this.icon, this.mono = false, this.maxWidth});

  final String label;
  final Color color;
  final String? tooltip;
  final IconData? icon;
  final bool mono;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (mono ? AppFonts.mono : const TextStyle()).copyWith(fontSize: 11.5),
    );
    final chip = Container(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12), const SizedBox(width: 4)],
          Flexible(child: text),
        ],
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}
