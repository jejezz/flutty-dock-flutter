import 'dart:io' show Platform;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/command_log.dart';
import '../core/window_bounds.dart';
import '../devices/mobile_device.dart';
import '../install/install_controller.dart';
import '../install/install_plan.dart';
import '../l10n/app_localizations.dart';
import '../secrets/secrets_screen.dart';
import '../settings/settings_menus.dart';
import '../theme/app_theme.dart';
import 'banner.dart';
import 'build_options_section.dart';
import 'command_text.dart';
import 'check_text.dart';
import 'copy_output_button.dart';
import 'devices_tab.dart';
import 'doctor_tab.dart';
import 'git_section.dart';
import 'log_tab.dart';
import 'project_header.dart';
import 'project_menu.dart';
import 'output_viewer.dart';
import 'signing_tab.dart';
import 'widgets.dart';
import '../window/focus_tint.dart';

/// VS Code 옆에 세워 두는 화면: 위에 프로젝트 카드, 아래에 탭(실행 · Git · 기기 · 서명 · 점검 · 기록).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.log,
    required this.onAbout,
    this.onDock = dockWindow,
    this.pickFolder = getDirectoryPath,
  });

  final InstallController controller;
  final CommandLog log;
  final VoidCallback onAbout;

  /// 창을 화면 가장자리에 붙인다. 테스트에서 바꾼다.
  final Future<void> Function(DockSide side) onDock;

  /// 폴더 고르기 창. 테스트에서 바꾼다.
  final Future<String?> Function() pickFolder;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: InstallController.tabIds.length, vsync: this, initialIndex: widget.controller.tabIndex);

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

  Tab _tab(IconData icon, String text) =>
      Tab(height: 54, iconMargin: const EdgeInsets.only(bottom: 2), icon: Icon(icon, size: 20), text: text);

  Future<void> _open() async {
    final dir = await widget.pickFolder();
    if (dir != null) await controller.openProject(dir);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mac = Platform.isMacOS;
    return CallbackShortcuts(
      bindings: {SingleActivator(LogicalKeyboardKey.keyO, control: !mac, meta: mac): _open},
      child: Focus(
        autofocus: true,
        child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          flexibleSpace: const FocusTint(),
          // 프로젝트 이름을 누르면 최근 프로젝트 · 폴더 열기 · 창 붙이기 메뉴가 열린다.
          title: ProjectMenuButton(controller: controller, onOpenFolder: _open, onDock: widget.onDock),
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
                // 프로젝트는 모든 탭의 기준이라 탭 위에 고정해 둔다.
                ProjectHeader(controller: controller, onOpen: _open),
                NextStepBanner(controller: controller),
                TabBar(
                  controller: _tabs,
                  // 도킹 폭(380~440)에서 여섯 탭이 한 줄에 균등하게 들어간다. 아이콘 위에 글자를 얹어 폭을 아낀다.
                  labelPadding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: [
                    _tab(Icons.play_circle_outline_rounded, l10n.tabInstall),
                    _tab(Icons.account_tree_outlined, l10n.tabGit),
                    _tab(Icons.smartphone_rounded, l10n.tabDevices),
                    _tab(Icons.verified_outlined, l10n.tabSigning),
                    _tab(Icons.health_and_safety_outlined, l10n.tabDoctor),
                    _tab(Icons.history_rounded, l10n.tabLog),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          _BuildSection(controller: controller),
                          const SizedBox(height: AppSpacing.lg),
                          _OutputSection(log: log),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [GitSection(controller: controller)],
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
    ),
      ),
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

  /// `flutter clean` → `flutter pub get`을 지금 실행하는 단추와 마지막 결과.
  Widget _cleanButton(InstallController c, AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              style: TextStyle(fontSize: 12, color: c.cleanResult! ? AppColors.success : theme.colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _runOnlyButton(InstallController c, AppLocalizations l10n, InstallPlan plan) {
    final ready = plan.runnable && c.artifactReady;
    final button = OutlinedButton(
      onPressed: ready ? () => c.start(phase: RunPhase.run) : null,
      child: Text((c.device?.isDesktop ?? false) ? l10n.homeActionRunOnly : l10n.homeActionInstallOnly),
    );
    // 결과물이 없어서 눌 수 없을 때만 이유를 알려 준다.
    return plan.runnable && !c.artifactReady ? Tooltip(message: l10n.homeRunOnlyNeedsBuild, child: button) : button;
  }

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
        if (c.project != null) ...[
          const SizedBox(height: AppSpacing.xs),
          // 프로젝트마다 입력 칸을 새로 만든다 (저장된 옵션이 그 프로젝트 것으로 채워지게).
          BuildOptionsSection(key: ValueKey(c.project!.path), controller: c),
        ],
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
                  // 빌드 전에 하는 일이라 목록 맨 위에 둔다. 누르면 바로 실행하고, 안 눌러도 빌드는 된다.
                  _cleanButton(c, l10n, theme),
                  const Divider(height: AppSpacing.xl),
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
                      // 데스크톱(이 컴퓨터)은 바로 실행하고, 폰은 설치한다.
                      child: Text(
                        interactive
                            ? l10n.homeActionRun
                            : (c.device?.isDesktop ?? false)
                            ? l10n.homeActionBuildRun
                            : l10n.homeActionInstall,
                      ),
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
        // release: 빌드와 실행을 따로 할 수 있다. 실행만은 이미 만든 결과물이 있을 때 쓴다.
        if (plan.splittable && !c.running) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: plan.runnable ? () => c.start(phase: RunPhase.build) : null,
                  child: Text(l10n.homeActionBuildOnly),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _runOnlyButton(c, l10n, plan)),
            ],
          ),
        ],
        // 실행할 명령이 없을 때(기기를 아직 못 골랐을 때 등)는 카드가 없으므로 정리 단추만 따로 둔다.
        if (c.project != null && plan.steps.isEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _cleanButton(c, l10n, theme),
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
            Row(
              children: [
                Expanded(child: SectionTitle(l10n.homeOutputTitle)),
                IconButton(
                  tooltip: l10n.outputViewer,
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  icon: const Icon(Icons.open_in_full_rounded),
                  onPressed: () => OutputViewerScreen.open(context, log, last),
                ),
                CopyOutputButton(text: () => '\$ ${last.commandLine}\n${last.output.trimRight()}'),
              ],
            ),
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
