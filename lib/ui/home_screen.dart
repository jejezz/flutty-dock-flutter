import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_identity.dart';
import '../core/command_log.dart';
import '../core/vscode.dart';
import '../devices/mobile_device.dart';
import '../install/install_controller.dart';
import '../install/install_plan.dart';
import '../l10n/app_localizations.dart';
import '../secrets/secrets_screen.dart';
import '../settings/settings_menus.dart';
import '../theme/app_theme.dart';
import 'banner.dart';
import 'command_text.dart';
import 'check_text.dart';
import 'devices_tab.dart';
import 'doctor_tab.dart';
import 'log_tab.dart';
import 'signing_tab.dart';
import 'widgets.dart';
import '../window/focus_tint.dart';

/// VS Code 옆에 세워 두는 화면: 프로젝트 → 기기 → 빌드 → 실행할 명령과 진행.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller, required this.log, required this.onAbout});

  final InstallController controller;
  final CommandLog log;
  final VoidCallback onAbout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this, initialIndex: widget.controller.tabIndex);

  InstallController get controller => widget.controller;
  CommandLog get log => widget.log;
  VoidCallback get onAbout => widget.onAbout;

  @override
  void initState() {
    super.initState();
    // 마지막으로 보던 탭: 저장된 값은 비동기로 읽히므로 도착하면 한 번 옮기고, 이후 바뀔 때마다 저장한다.
    controller.addListener(_restoreTab);
    _restored = controller.tabLoaded;
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) controller.setTab(_tabs.index);
    });
  }

  bool _restored = false;

  void _restoreTab() {
    if (_restored || !controller.tabLoaded) return;
    _restored = true;
    if (_tabs.index != controller.tabIndex) _tabs.index = controller.tabIndex;
  }

  @override
  void dispose() {
    controller.removeListener(_restoreTab);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final dir = await getDirectoryPath();
    if (dir != null) await controller.openProject(dir);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          flexibleSpace: const FocusTint(),
          title: const Text(AppIdentity.displayName),
          actions: [
            // macOS 릴리스 서명용 시크릿 — Windows 릴리스는 시크릿이 필요 없어 숨긴다.
            if (SecretsScreen.available)
              IconButton(
                tooltip: l10n.secretsTooltip,
                icon: const Icon(Icons.key_rounded),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SecretsScreen())),
              ),
            const ThemeMenuButton(),
            const LanguageMenuButton(),
            IconButton(tooltip: l10n.aboutTooltip, icon: const Icon(Icons.info_outline_rounded), onPressed: onAbout),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: DropTarget(
          onDragDone: (d) {
            if (d.files.isNotEmpty) controller.openProject(d.files.first.path);
          },
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Column(
              children: [
                NextStepBanner(controller: controller),
                TabBar(
                  controller: _tabs,
                  // 도킹 폭(380~440)에서 다섯 탭이 한 줄에 균등하게 들어간다.
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    Tab(text: l10n.tabInstall),
                    Tab(text: l10n.tabDevices),
                    Tab(text: l10n.tabSigning),
                    Tab(text: l10n.tabDoctor),
                    Tab(text: l10n.tabLog),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          _ProjectSection(controller: controller, onOpen: _open),
                          const SizedBox(height: AppSpacing.lg),
                          _BuildSection(controller: controller),
                          const SizedBox(height: AppSpacing.lg),
                          _OutputSection(log: log),
                        ],
                      ),
                      DevicesTab(controller: controller),
                      SigningTab(controller: controller),
                      DoctorTab(controller: controller),
                      LogTab(log: log),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectSection extends StatelessWidget {
  const _ProjectSection({required this.controller, required this.onOpen});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(l10n.homeProjectTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: p == null
                ? Column(
                    children: [
                      Text(l10n.homeProjectDrop, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(onPressed: onOpen, child: Text(l10n.homeProjectOpen)),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.version == null ? p.name : '${p.name}  ${p.version}',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              p.path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.userContent.copyWith(fontSize: 12, color: theme.hintColor),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.xs,
                              children: [
                                if (p.hasIos) InfoChip(l10n.homePlatformIos),
                                if (p.hasAndroid) InfoChip(l10n.homePlatformAndroid),
                                if (p.hasMacos) InfoChip(l10n.homePlatformMacos),
                                if (p.hasWindows) InfoChip(l10n.homePlatformWindows),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(onPressed: onOpen, child: Text(l10n.homeProjectChange)),
                              IconButton(
                                tooltip: l10n.homeProjectReload,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.refresh_rounded, size: 20),
                                onPressed: () => controller.openProject(p.path),
                              ),
                            ],
                          ),
                          TextButton(onPressed: () => _openInVsCode(context), child: Text(l10n.homeOpenVsCode)),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        if (controller.projectError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.homeProjectNotFlutter(controller.projectError!),
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _BuildSection extends StatefulWidget {
  const _BuildSection({required this.controller});

  final InstallController controller;

  @override
  State<_BuildSection> createState() => _BuildSectionState();
}

class _BuildSectionState extends State<_BuildSection> {
  late final _team = TextEditingController(text: widget.controller.teamId ?? '');

  @override
  void dispose() {
    _team.dispose();
    super.dispose();
  }

  String _stepLabel(AppLocalizations l10n, StepKind k) => switch (k) {
    StepKind.prepare => l10n.homeStepPrepare,
    StepKind.build => l10n.homeStepBuild,
    StepKind.install => l10n.homeStepInstall,
    StepKind.launch => l10n.homeStepLaunch,
    StepKind.run => l10n.homeStepRun,
  };

  Widget _statusIcon(StepStatus? s, ThemeData theme) => switch (s) {
    StepStatus.running => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
    StepStatus.done => const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
    StepStatus.failed => Icon(Icons.error_rounded, size: 16, color: theme.colorScheme.error),
    StepStatus.cancelled => Icon(Icons.cancel_rounded, size: 16, color: theme.hintColor),
    _ => Icon(Icons.radio_button_unchecked_rounded, size: 16, color: theme.hintColor),
  };

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = c.plan;
    final isIos = c.device?.platform == DevicePlatform.ios;
    final interactive = plan.steps.isNotEmpty && plan.steps.first.interactive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(l10n.homeBuildTitle),
        SegmentedButton<BuildMode>(
          segments: [
            ButtonSegment(value: BuildMode.debug, label: Text(l10n.homeModeDebug)),
            ButtonSegment(value: BuildMode.release, label: Text(l10n.homeModeRelease)),
          ],
          selected: {c.mode},
          onSelectionChanged: c.running ? null : (s) => c.setMode(s.first),
        ),
        if (isIos) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _team,
            enabled: !c.running,
            decoration: InputDecoration(
              labelText: l10n.homeTeamLabel,
              hintText: c.project?.iosTeamId,
              helperText: l10n.homeTeamHelp,
              helperMaxLines: 3,
              isDense: true,
            ),
            onChanged: c.setTeamId,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (plan.steps.isNotEmpty) ...[
          SectionTitle(l10n.homeStepsTitle),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < plan.steps.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == plan.steps.length - 1 ? 0 : AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: _statusIcon(i < c.statuses.length ? c.statuses[i] : null, theme),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}. ${_stepLabel(l10n, plan.steps[i].kind)}',
                                  style: theme.textTheme.labelLarge,
                                ),
                                CommandText(plan.steps[i].commandLine),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: c.running
                  ? OutlinedButton(
                      onPressed: c.cancel,
                      child: Text(interactive ? l10n.homeActionStop : l10n.homeActionCancel),
                    )
                  : FilledButton(
                      onPressed: plan.runnable ? c.start : null,
                      child: Text(interactive ? l10n.homeActionRun : l10n.homeActionInstall),
                    ),
            ),
            if (c.running && interactive) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton.outlined(
                tooltip: l10n.homeHotReload,
                icon: const Icon(Icons.bolt_rounded),
                onPressed: () => c.sendKey('r'),
              ),
              IconButton.outlined(
                tooltip: l10n.homeHotRestart,
                icon: const Icon(Icons.restart_alt_rounded),
                onPressed: () => c.sendKey('R'),
              ),
            ],
          ],
        ),
        if (c.project != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Tooltip(
            message: l10n.homeCleanHelp,
            child: OutlinedButton.icon(
              onPressed: c.running || c.cleaning ? null : c.cleanProject,
              icon: c.cleaning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cleaning_services_rounded, size: 18),
              label: Text(l10n.homeActionClean),
            ),
          ),
          if (c.cleanResult != null && !c.cleaning)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                c.cleanResult! ? l10n.homeCleanDone : l10n.homeCleanFailed,
                style: TextStyle(
                  fontSize: 12,
                  color: c.cleanResult! ? AppColors.success : theme.colorScheme.error,
                ),
              ),
            ),
        ],
        if (c.missingCommand != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(l10n.hintMissingCommand(c.missingCommand!), style: TextStyle(color: theme.colorScheme.error)),
          )
        else if (c.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(failureHintText(l10n, c.hint!), style: TextStyle(color: theme.colorScheme.error)),
          ),
      ],
    );
  }
}

class _OutputSection extends StatelessWidget {
  const _OutputSection({required this.log});

  final CommandLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: log,
      builder: (context, _) {
        final last = log.last;
        if (last == null) return const SizedBox.shrink();
        final lines = last.output.trimRight().split('\n');
        final tail = lines.length > 60 ? lines.sublist(lines.length - 60) : lines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(l10n.homeOutputTitle),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 260),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: SelectableText(
                  '\$ ${last.commandLine}\n${tail.join('\n')}',
                  style: AppFonts.mono.copyWith(fontSize: 11.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
