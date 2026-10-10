import 'dart:io';

import 'package:flutter/material.dart';

import '../doctor/checks.dart';
import '../doctor/signing_info.dart';
import '../install/install_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'check_tile.dart';
import 'widgets.dart';

/// 서명 탭: iOS 인증서·Team·프로파일(macOS)과 Android 릴리스 서명 방식.
class SigningTab extends StatelessWidget {
  const SigningTab({super.key, required this.controller});

  final InstallController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = controller.diagnostics;
    final now = DateTime.now();
    final bundle = controller.project?.iosBundleId;
    final profiles = d == null || bundle == null
        ? <ProfileInfo>[]
        : d.profiles.where((p) => p.matches(bundle)).toList();
    final checks = controller.checks;

    String days(int? n) => n == null ? '' : (n < 0 ? l10n.signingExpired : l10n.signingDaysLeft('$n'));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (!Platform.isMacOS)
          Text(l10n.signingMacOnly, style: theme.textTheme.bodySmall)
        else ...[
          SectionTitle(l10n.signingTeams),
          Text(l10n.signingTeamsHelp, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          if (d == null || d.usableTeams.isEmpty)
            Text(l10n.signingNoTeams, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error))
          else
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final t in d.usableTeams)
                  ChoiceChip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    selected: controller.effectiveTeamId == t,
                    onSelected: controller.running ? null : (_) => controller.setTeamId(t),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          SectionTitle(l10n.signingCerts),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (d == null || d.certs.isEmpty)
                    Text(l10n.signingNoTeams, style: theme.textTheme.bodySmall)
                  else
                    for (final c in d.certs)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(child: Text(c.name, style: const TextStyle(fontSize: 12.5))),
                            if (!c.hasPrivateKey) InfoChip(l10n.signingNoKey),
                            const SizedBox(width: AppSpacing.xs),
                            Text(days(c.daysLeft(now)), style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          if (bundle != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionTitle(l10n.signingProfiles),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profiles.isEmpty)
                      Text(l10n.signingNoProfiles, style: theme.textTheme.bodySmall)
                    else
                      for (final p in profiles)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(child: Text(p.name, style: const TextStyle(fontSize: 12.5))),
                              if (p.isShortLived) InfoChip(l10n.signingShortLived),
                              const SizedBox(width: AppSpacing.xs),
                              Text(days(p.daysLeft(now)), style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          CheckList(only(checks, {CheckId.certificate, CheckId.certificateExpiry, CheckId.team, CheckId.profile})),
        ],
        if (controller.diagnostics?.androidSigning != null) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionTitle(l10n.signingAndroid),
          CheckList(only(checks, {CheckId.androidSigning})),
        ],
      ],
    );
  }
}
