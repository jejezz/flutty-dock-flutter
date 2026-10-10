import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/command_log.dart';
import '../core/command_runner.dart';
import '../core/gh_client.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../ui/command_text.dart';
import '../ui/widgets.dart';
import 'release_secrets.dart';

/// macOS 릴리스 서명·공증용 GitHub Actions 시크릿을 `gh`로 등록하는 화면.
///
/// macOS에서만 연다 — Windows 릴리스는 시크릿이 필요 없다.
/// 값은 입력란과 메모리에만 있고 저장하지 않는다. 등록하면 바로 지운다.
class SecretsScreen extends StatefulWidget {
  const SecretsScreen({super.key, this.client, this.log, this.pickEnvFile});

  /// 테스트에서 가짜를 넣는다. 기본은 실제 `gh`.
  final GhClient? client;
  final CommandLog? log;

  /// `.env` 파일을 고른다. 테스트에서 바꾼다. 기본은 파일 선택 창.
  /// 이름을 뽑으려고 내용을 한 번 읽지만 값은 남기지 않는다.
  final Future<({String path, String text})?> Function()? pickEnvFile;

  /// 이 화면을 여는 단추를 보일지.
  static bool get available => Platform.isMacOS;

  @override
  State<SecretsScreen> createState() => _SecretsScreenState();
}

class _SecretsScreenState extends State<SecretsScreen> {
  static const _repoKey = 'secrets_repo';

  late final CommandLog _log = widget.log ?? CommandLog();
  late final GhClient _gh = widget.client ?? ProcessGhClient(CommandRunner(_log));
  final _repo = TextEditingController();
  final _controllers = {
    for (final s in macosReleaseSecrets)
      if (s.kind == SecretKind.password || s.kind == SecretKind.text) s.name: TextEditingController(),
  };
  // 파일·무작위 값은 입력란이 없어 메모리에만 둔다.
  final _values = <String, String>{};
  final _fileNames = <String, String>{};
  final _issues = <String, SecretIssue>{};
  final _busy = <String>{};

  GhStatus? _ghStatus;
  Map<String, DateTime?>? _registered;
  bool _listFailed = false;
  String? _envPath;
  List<String> _envNames = const [];
  String? _repoError;
  String? _message;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _repo.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _repo.text = prefs.getString(_repoKey) ?? '';
    } on Object {
      // 저장소 이름 기억은 편의일 뿐이다.
    }
    final status = await _gh.status();
    if (!mounted) return;
    setState(() => _ghStatus = status);
    if (status == GhStatus.ready && isValidRepo(_repo.text)) await _refresh();
  }

  String get _repoName => _repo.text.trim();

  Future<void> _refresh() async {
    final l10n = AppLocalizations.of(context);
    if (!isValidRepo(_repoName)) {
      setState(() {
        _repoError = l10n.secretsRepoInvalid;
        _registered = null;
        _listFailed = false;
      });
      return;
    }
    setState(() => _repoError = null);
    try {
      (await SharedPreferences.getInstance()).setString(_repoKey, _repoName);
    } on Object {
      // 위와 같다.
    }
    final list = await _gh.listSecrets(_repoName);
    if (!mounted) return;
    setState(() {
      _registered = list;
      _listFailed = list == null;
    });
  }

  Future<void> _pickFolder() async {
    final l10n = AppLocalizations.of(context);
    final dir = await getDirectoryPath();
    if (dir == null) return;
    final repo = await _gh.repoFromFolder(dir);
    if (!mounted) return;
    if (repo == null) {
      setState(() => _repoError = l10n.secretsFolderNoRemote);
      return;
    }
    _repo.text = repo;
    await _refresh();
  }

  Future<({String path, String text})?> _defaultPickEnv() async {
    final file = await openFile();
    if (file == null) return null;
    return (path: file.path, text: await file.readAsString());
  }

  Future<void> _pickEnv() async {
    final picked = await (widget.pickEnvFile ?? _defaultPickEnv)();
    if (picked == null || !mounted) return;
    setState(() {
      _envPath = picked.path;
      _envNames = parseDotenvNames(picked.text);
    });
  }

  Future<void> _registerFromFile() async {
    final l10n = AppLocalizations.of(context);
    final path = _envPath;
    if (path == null || _envNames.isEmpty) return;
    if (!isValidRepo(_repoName)) {
      setState(() => _repoError = l10n.secretsRepoInvalid);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.secretFileConfirmTitle(_envNames.length)),
        content: Text(_envNames.join('\n'), style: AppFonts.mono.copyWith(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.secretSet)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy.add('@file'));
    final result = await _gh.setSecretsFromFile(_repoName, path);
    if (!mounted) return;
    setState(() {
      _busy.remove('@file');
      _message = result.ok
          ? l10n.secretFileSaved(_envNames.length)
          : '${l10n.secretFileFailed}\n${result.combined.trim()}';
    });
    if (result.ok) await _refresh();
  }

  Future<void> _pickFile(SecretSpec spec) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'p12', extensions: ['p12', 'pfx']),
      ],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _values[spec.name] = base64Encode(bytes);
      _fileNames[spec.name] = '${file.name} · ${bytes.length}';
      _issues.remove(spec.name);
    });
  }

  void _generate(SecretSpec spec) => setState(() {
    _values[spec.name] = generatePassword();
    _issues.remove(spec.name);
  });

  String _valueOf(SecretSpec spec) => _controllers[spec.name]?.text ?? _values[spec.name] ?? '';

  Future<void> _register(SecretSpec spec) async {
    final l10n = AppLocalizations.of(context);
    if (!isValidRepo(_repoName)) {
      setState(() => _repoError = l10n.secretsRepoInvalid);
      return;
    }
    final value = _valueOf(spec);
    final issue = validateSecret(spec, value);
    if (issue != null) {
      setState(() => _issues[spec.name] = issue);
      return;
    }
    if (_registered?.containsKey(spec.name) ?? false) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.secretOverwriteTitle(spec.name)),
          content: Text(l10n.secretOverwriteBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.secretOverwrite)),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      _busy.add(spec.name);
      _issues.remove(spec.name);
    });
    final result = await _gh.setSecret(_repoName, spec.name, value.trim());
    if (!mounted) return;
    setState(() {
      _busy.remove(spec.name);
      if (result.ok) {
        _controllers[spec.name]?.clear();
        _values.remove(spec.name);
        _fileNames.remove(spec.name);
      }
      _message = result.ok ? l10n.secretSaved(spec.name) : '${l10n.secretFailed(spec.name)}\n${result.combined.trim()}';
    });
    if (result.ok) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.secretsTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(l10n.secretsIntro, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                _repoRow(l10n),
                if (_ghStatus != null && _ghStatus != GhStatus.ready) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ghBanner(l10n, _ghStatus!),
                ],
                if (_listFailed) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.secretsListFailed, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                _fileCard(l10n, theme),
                const SizedBox(height: AppSpacing.md),
                for (final spec in macosReleaseSecrets) ...[
                  _secretCard(l10n, theme, spec),
                  const SizedBox(height: AppSpacing.md),
                ],
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse('https://appleid.apple.com')),
                      child: Text(l10n.secretOpenAppleId),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse('https://developer.apple.com/account')),
                      child: Text(l10n.secretOpenDeveloper),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _commandBar(l10n, theme),
        ],
      ),
    );
  }

  /// `.env` 파일로 한 번에 등록 — `gh secret set -f`.
  Widget _fileCard(AppLocalizations l10n, ThemeData theme) {
    final known = macosReleaseSecrets.map((s) => s.name).toSet();
    final unknown = _envNames.where((n) => !known.contains(n)).toList();
    final missing = macosReleaseSecrets.map((s) => s.name).where((n) => !_envNames.contains(n)).toList();
    final busy = _busy.contains('@file');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.secretFileTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.secretFileHelp, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                OutlinedButton(onPressed: _pickEnv, child: Text(l10n.secretPickFile)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _envPath ?? l10n.secretNoFile,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.userContent.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (_envPath != null) ...[
              const SizedBox(height: AppSpacing.sm),
              if (_envNames.isEmpty)
                Text(l10n.secretFileEmpty, style: TextStyle(color: theme.colorScheme.error, fontSize: 12))
              else ...[
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final n in _envNames)
                      InfoChip(n, color: known.contains(n) ? null : AppColors.warning.withValues(alpha: 0.3)),
                  ],
                ),
                if (unknown.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(l10n.secretFileUnknown(unknown.join(', ')), style: theme.textTheme.bodySmall),
                  ),
                if (missing.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(l10n.secretFileMissing(missing.join(', ')), style: theme.textTheme.bodySmall),
                  ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: CommandText(
                      formatCommandLine(
                        secretSetFileArgs(isValidRepo(_repoName) ? _repoName : 'owner/repo', _envPath!),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: busy || _envNames.isEmpty ? null : _registerFromFile,
                    child: busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.secretFileRegister),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _repoRow(AppLocalizations l10n) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: TextField(
          controller: _repo,
          decoration: InputDecoration(labelText: l10n.secretsRepoLabel, errorText: _repoError),
          onSubmitted: (_) => _refresh(),
        ),
      ),
      IconButton(tooltip: l10n.secretsPickFolder, icon: const Icon(Icons.folder_open_rounded), onPressed: _pickFolder),
      IconButton(tooltip: l10n.secretsRefresh, icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
    ],
  );

  Widget _ghBanner(AppLocalizations l10n, GhStatus status) {
    final (text, command) = switch (status) {
      GhStatus.notInstalled => (l10n.secretsGhMissing, 'brew install gh'),
      _ => (l10n.secretsGhNotLoggedIn, 'gh auth login'),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            const SizedBox(height: AppSpacing.sm),
            CommandText(command),
          ],
        ),
      ),
    );
  }

  String _helpFor(AppLocalizations l10n, String name) => switch (name) {
    'MACOS_CERTIFICATE_P12_BASE64' => l10n.secretHelpP12,
    'MACOS_CERTIFICATE_PASSWORD' => l10n.secretHelpP12Password,
    'MACOS_KEYCHAIN_PASSWORD' => l10n.secretHelpKeychain,
    'APPLE_ID' => l10n.secretHelpAppleId,
    'APPLE_ID_PASSWORD' => l10n.secretHelpApplePassword,
    _ => l10n.secretHelpTeamId,
  };

  String _issueText(AppLocalizations l10n, SecretIssue issue) => switch (issue) {
    SecretIssue.empty => l10n.secretIssueEmpty,
    SecretIssue.notEmail => l10n.secretIssueEmail,
    SecretIssue.badTeamId => l10n.secretIssueTeamId,
  };

  Widget _secretCard(AppLocalizations l10n, ThemeData theme, SecretSpec spec) {
    final date = _registered?[spec.name];
    final registered = _registered?.containsKey(spec.name) ?? false;
    final status = _registered == null
        ? l10n.secretStatusUnknown
        : registered
        ? l10n.secretStatusRegistered(date == null ? '' : MaterialLocalizations.of(context).formatShortDate(date))
        : l10n.secretStatusMissing;
    final issue = _issues[spec.name];
    final busy = _busy.contains(spec.name);
    final input = switch (spec.kind) {
      SecretKind.file => Row(
        children: [
          OutlinedButton(onPressed: () => _pickFile(spec), child: Text(l10n.secretPickFile)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _fileNames[spec.name] == null ? l10n.secretNoFile : _fileLabel(l10n, _fileNames[spec.name]!),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
      SecretKind.generated => Row(
        children: [
          OutlinedButton(onPressed: () => _generate(spec), child: Text(l10n.secretGenerate)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(_values.containsKey(spec.name) ? l10n.secretGenerated : '', style: theme.textTheme.bodySmall),
          ),
        ],
      ),
      _ => TextField(
        controller: _controllers[spec.name],
        obscureText: spec.kind == SecretKind.password,
        enableSuggestions: false,
        autocorrect: false,
        decoration: const InputDecoration(isDense: true),
        onChanged: (_) {
          if (_issues.containsKey(spec.name)) setState(() => _issues.remove(spec.name));
        },
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(spec.name, style: AppFonts.mono.copyWith(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
                Text(status, style: theme.textTheme.bodySmall?.copyWith(color: registered ? AppColors.success : null)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(_helpFor(l10n, spec.name), style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            input,
            if (issue != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(_issueText(l10n, issue), style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: CommandText(
                    formatCommandLine(secretSetArgs(isValidRepo(_repoName) ? _repoName : 'owner/repo', spec.name)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: busy ? null : () => _register(spec),
                  child: busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(registered ? l10n.secretOverwrite : l10n.secretSet),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.secretViaStdin, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // "이름 · 바이트" 로 저장해 둔 값을 현지화된 문구로 바꾼다.
  String _fileLabel(AppLocalizations l10n, String stored) {
    final i = stored.lastIndexOf(' · ');
    return l10n.secretFileLoaded(stored.substring(0, i), int.tryParse(stored.substring(i + 3)) ?? 0);
  }

  /// 마지막으로 실행한 명령과 결과 — 값은 인자가 아니라 로그에 없다.
  Widget _commandBar(AppLocalizations l10n, ThemeData theme) => ListenableBuilder(
    listenable: _log,
    builder: (context, _) {
      final last = _log.last;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (last == null)
              Text(l10n.commandBarEmpty, style: theme.textTheme.bodySmall)
            else
              Row(
                children: [
                  Icon(
                    last.running
                        ? Icons.hourglass_empty_rounded
                        : last.succeeded
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 16,
                    color: last.running ? null : (last.succeeded ? AppColors.success : theme.colorScheme.error),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SelectableText(r'$ ' + last.commandLine, style: AppFonts.mono.copyWith(fontSize: 12)),
                  ),
                ],
              ),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(_message!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      );
    },
  );
}
