import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../install/build_options.dart';
import '../install/install_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Flutter 공식 문서: flavor 설정(Android). iOS·macOS·Windows·Linux 문서는 같은 Deployment 목록에 있다.
final flavorDocsUrl = Uri.parse('https://docs.flutter.dev/deployment/flavors');

/// "빌드" 섹션 안의 접히는 빌드 옵션: flavor, 진입 파일, dart-define 파일, 앱 ID, 추가 인자.
/// 프로젝트마다 따로 저장되고, 입력한 옵션은 "실행할 명령"의 명령에 그대로 보인다.
///
/// 프로젝트가 바뀌면 새로 만들어야 한다 — 호출하는 쪽이 프로젝트 경로로 `key`를 준다.
class BuildOptionsSection extends StatefulWidget {
  const BuildOptionsSection({super.key, required this.controller});

  final InstallController controller;

  @override
  State<BuildOptionsSection> createState() => _BuildOptionsSectionState();
}

class _BuildOptionsSectionState extends State<BuildOptionsSection> {
  late final _flavor = TextEditingController(text: o.flavor);
  late final _target = TextEditingController(text: o.target);
  late final _defineFile = TextEditingController(text: o.defineFile);
  late final _appId = TextEditingController(text: o.appId);
  late final _extra = TextEditingController(text: o.extraArgs);

  InstallController get c => widget.controller;
  BuildOptions get o => c.options;

  @override
  void dispose() {
    _flavor.dispose();
    _target.dispose();
    _defineFile.dispose();
    _appId.dispose();
    _extra.dispose();
    super.dispose();
  }

  /// 프로젝트 안의 파일은 프로젝트 기준 상대 경로(`/` 구분)로, 밖의 파일은 그대로.
  String _display(String picked) {
    final root = c.project?.path;
    if (root == null) return picked;
    final normalizedRoot = root.replaceAll('\\', '/');
    final normalized = picked.replaceAll('\\', '/');
    final prefix = normalizedRoot.endsWith('/') ? normalizedRoot : '$normalizedRoot/';
    return normalized.startsWith(prefix) ? normalized.substring(prefix.length) : picked;
  }

  Future<void> _pick(TextEditingController field, {required String? folder, required bool dartOnly}) async {
    final root = c.project?.path;
    final file = await openFile(
      initialDirectory: root == null || folder == null ? root : '$root/$folder',
      acceptedTypeGroups: dartOnly ? const [XTypeGroup(label: 'Dart', extensions: ['dart'])] : const [],
    );
    if (file == null) return;
    field.text = _display(file.path);
    _push();
  }

  void _push() => c.setOptions(
    BuildOptions(
      flavor: _flavor.text,
      target: _target.text,
      defineFile: _defineFile.text,
      appId: _appId.text,
      extraArgs: _extra.text,
    ),
  );

  void _clear() {
    for (final f in [_flavor, _target, _defineFile, _appId, _extra]) {
      f.clear();
    }
    _push();
  }

  /// 입력한 dart-define 파일이 있는지 (상대 경로는 프로젝트 기준).
  bool _defineFileMissing() {
    final text = _defineFile.text.trim();
    if (text.isEmpty) return false;
    final root = c.project?.path ?? '';
    final isAbsolute = text.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(text);
    return !File(isAbsolute ? text : '$root/$text').existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locked = c.running;
    final summary = o.isEmpty ? l10n.optDefault : o.flutterArgs(flavorSupported: true).join(' ');

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        initiallyExpanded: !o.isEmpty,
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Row(
          children: [
            Flexible(child: Text(l10n.optTitle, style: theme.textTheme.labelLarge)),
            // 펼치지 않아도 바로 열 수 있게 제목 옆에 둔다.
            IconButton(
              tooltip: l10n.optHelpLink,
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => launchUrl(flavorDocsUrl, mode: LaunchMode.externalApplication),
            ),
          ],
        ),
        subtitle: Text(
          summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.mono.copyWith(fontSize: 11, color: theme.hintColor),
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _flavor,
            enabled: !locked,
            decoration: InputDecoration(
              labelText: l10n.optFlavor,
              helperText: l10n.optFlavorHelp,
              helperMaxLines: 2,
              errorText: o.flavorInvalid ? l10n.optFlavorInvalid : null,
              isDense: true,
            ),
            onChanged: (_) => _push(),
          ),
          const SizedBox(height: AppSpacing.md),
          _pickerField(
            _target,
            enabled: !locked,
            label: l10n.optTarget,
            help: l10n.optTargetHelp,
            pickTooltip: l10n.optPick,
            onPick: () => _pick(_target, folder: 'lib', dartOnly: true),
          ),
          const SizedBox(height: AppSpacing.md),
          _pickerField(
            _defineFile,
            enabled: !locked,
            label: l10n.optDefineFile,
            help: l10n.optDefineFileHelp,
            error: _defineFileMissing() ? l10n.optFileMissing : null,
            pickTooltip: l10n.optPick,
            onPick: () => _pick(_defineFile, folder: null, dartOnly: false),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _appId,
            enabled: !locked,
            decoration: InputDecoration(
              labelText: l10n.optAppId,
              helperText: l10n.optAppIdHelp,
              helperMaxLines: 3,
              isDense: true,
            ),
            onChanged: (_) => _push(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _extra,
            enabled: !locked,
            decoration: InputDecoration(
              labelText: l10n.optExtra,
              helperText: l10n.optExtraHelp,
              helperMaxLines: 2,
              isDense: true,
            ),
            onChanged: (_) => _push(),
          ),
          if (!o.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: locked ? null : _clear, child: Text(l10n.optClear)),
            ),
        ],
      ),
    );
  }

  Widget _pickerField(
    TextEditingController controller, {
    required bool enabled,
    required String label,
    required String help,
    required String pickTooltip,
    required VoidCallback onPick,
    String? error,
  }) => TextField(
    controller: controller,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: label,
      helperText: help,
      helperMaxLines: 3,
      errorText: error,
      isDense: true,
      suffixIcon: IconButton(
        tooltip: pickTooltip,
        icon: const Icon(Icons.folder_open_rounded, size: 18),
        onPressed: enabled ? onPick : null,
      ),
    ),
    onChanged: (_) => _push(),
  );
}
