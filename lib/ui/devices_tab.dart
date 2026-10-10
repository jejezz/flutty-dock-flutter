import 'package:flutter/material.dart';

import '../devices/mobile_device.dart';
import '../doctor/checks.dart';
import '../install/install_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'check_tile.dart';
import 'widgets.dart';

/// 기기 탭: 연결된 기기 목록과 선택한 기기의 연결 점검.
class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key, required this.controller});

  final InstallController controller;

  @override
  Widget build(BuildContext context) {
    final deviceChecks = only(controller.checks, {CheckId.connection, CheckId.developerMode, CheckId.androidAuth});
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _DeviceList(controller: controller),
        if (deviceChecks.isNotEmpty) ...[const SizedBox(height: AppSpacing.lg), CheckList(deviceChecks)],
      ],
    );
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.controller});

  final InstallController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          l10n.homeDevicesTitle,
          trailing: controller.loadingDevices
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  tooltip: l10n.homeDevicesRefresh,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: controller.refreshDevices,
                ),
        ),
        if (controller.devices.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.homeDevicesNone, style: theme.textTheme.bodySmall),
            ),
          )
        else
          Card(
            child: RadioGroup<String>(
              groupValue: controller.selectedId,
              onChanged: (id) {
                final d = controller.devices.where((d) => d.id == id).firstOrNull;
                if (d != null) controller.select(d);
              },
              child: Column(
                children: [
                  for (final d in controller.devices)
                    RadioListTile<String>(
                      value: d.id,
                      dense: true,
                      title: Text(d.name, style: AppFonts.userContent),
                      subtitle: Text(
                        [
                          d.platform == DevicePlatform.ios ? l10n.homePlatformIos : l10n.homePlatformAndroid,
                          if (d.osVersion != null) d.osVersion!,
                          if (d.model != null && d.model != d.name) d.model!,
                        ].join(' · '),
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: InfoChip(d.isUsb ? l10n.homeLinkUsb : l10n.homeLinkWireless),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
