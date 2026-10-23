import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/git_client.dart';
import '../install/install_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

/// 프로젝트 폴더의 git 상태(브랜치·원격과의 차이·변경)와 원격 주소, fetch·pull 단추.
/// git 저장소가 아니면 아무것도 그리지 않는다. push는 일부러 두지 않았다.
class GitSection extends StatelessWidget {
  const GitSection({super.key, required this.controller});

  final InstallController controller;

  String _blockText(AppLocalizations l10n, GitPullBlock b) => switch (b) {
    GitPullBlock.noUpstream => l10n.gitPullBlockedNoUpstream,
    GitPullBlock.dirty => l10n.gitPullBlockedDirty,
    GitPullBlock.diverged => l10n.gitPullBlockedDiverged,
    GitPullBlock.upToDate => l10n.gitPullBlockedUpToDate,
  };

  @override
  Widget build(BuildContext context) {
    final g = controller.gitState;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (controller.project != null && g == null && controller.gitMissing) {
      // git 저장소가 아닌 폴더는 카드를 숨기지만, git이 없는 PC는 이유를 알려 준다.
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(l10n.gitTitle),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.warning),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(l10n.hintMissingCommand('git'), style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (controller.project == null || g == null) return const SizedBox.shrink();
    final busy = controller.gitBusy;
    final locked = busy || controller.running || controller.cleaning;
    final web = g.remoteWebUrl;
    final remote = g.remoteUrl;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            l10n.gitTitle,
            trailing: IconButton(
              tooltip: l10n.homeProjectReload,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: locked ? null : controller.refreshGit,
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_tree_outlined, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          g.branch ?? l10n.gitDetached,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.mono.copyWith(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                  // worktree가 둘 이상이면 고르는 칸. 고르면 그 폴더의 같은 프로젝트를 연다 (파일은 바꾸지 않는다).
                  if (controller.worktrees.length > 1) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Tooltip(
                      message: l10n.gitWorktreeHelp,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.gitWorktree,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<GitWorktree>(
                            isExpanded: true,
                            isDense: true,
                            value: controller.currentWorktree,
                            items: [
                              for (final w in controller.worktrees)
                                DropdownMenuItem(
                                  value: w,
                                  child: Text(
                                    '${w.branch ?? l10n.gitDetached}  ·  ${w.folderName}',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.mono.copyWith(fontSize: 12),
                                  ),
                                ),
                            ],
                            onChanged: locked ? null : (w) => w == null ? null : controller.switchWorktree(w),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (!g.hasUpstream)
                        InfoChip(l10n.gitNoUpstream)
                      else if (g.ahead == 0 && g.behind == 0)
                        InfoChip(l10n.gitUpToDate, color: AppColors.success.withValues(alpha: 0.18))
                      else ...[
                        if (g.ahead > 0) InfoChip(l10n.gitAhead(g.ahead)),
                        if (g.behind > 0) InfoChip(l10n.gitBehind(g.behind), color: AppColors.warning.withValues(alpha: 0.2)),
                      ],
                      if (g.dirty) InfoChip(l10n.gitDirty, color: AppColors.warning.withValues(alpha: 0.2)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (remote == null)
                    Text(l10n.gitNoRemote, style: theme.textTheme.bodySmall)
                  else if (web != null)
                    Tooltip(
                      message: l10n.gitOpenRemote,
                      child: InkWell(
                        onTap: () => launchUrl(Uri.parse(web), mode: LaunchMode.externalApplication),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                web.replaceFirst('https://', ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.userContent.copyWith(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(Icons.open_in_new_rounded, size: 14, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    )
                  else
                    SelectableText(remote, style: AppFonts.userContent.copyWith(fontSize: 12, color: theme.hintColor)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: locked || remote == null ? null : controller.gitFetch,
                          icon: busy && controller.lastGitAction == null
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.cloud_download_outlined, size: 18),
                          label: Text(l10n.gitFetch),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Tooltip(
                          message: g.pullBlock == null ? l10n.gitPullHelp : _blockText(l10n, g.pullBlock!),
                          child: FilledButton.tonalIcon(
                            onPressed: locked || !g.canPull ? null : controller.gitPull,
                            icon: const Icon(Icons.call_received_rounded, size: 18),
                            label: Text(l10n.gitPull),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (g.pullBlock != null && g.hasUpstream && (g.behind > 0 || g.dirty))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(_blockText(l10n, g.pullBlock!), style: theme.textTheme.bodySmall),
                    ),
                  if (controller.lastGitOk != null && !busy)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        controller.lastGitOk!
                            ? (controller.lastGitAction == GitAction.pull ? l10n.gitPullDone : l10n.gitFetchDone)
                            : l10n.gitFailed,
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.lastGitOk! ? AppColors.success : theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
