import '../devices/mobile_device.dart';
import '../flutter/flutter_project.dart';
import 'diagnostics.dart';

enum CheckStatus { ok, warn, fail, info }

enum CheckId {
  flutter,
  xcode,
  adb,
  connection,
  developerMode,
  androidAuth,
  certificate,
  certificateExpiry,
  team,
  profile,
  androidSigning,
}

/// 점검 결과 한 줄. 문구는 화면이 [id]와 [params]로 만든다.
class CheckItem {
  const CheckItem(this.id, this.status, [this.params = const {}]);

  final CheckId id;
  final CheckStatus status;
  final Map<String, String> params;
}

/// 환경 정보와 선택한 프로젝트·기기에서 점검 목록을 만든다. 실행하지 않고 판단만 한다.
List<CheckItem> buildChecks({
  required Diagnostics? diagnostics,
  required FlutterProject? project,
  required MobileDevice? device,
  required String? teamId,
  required bool hostIsMac,
  required DateTime now,
}) {
  final d = diagnostics;
  if (d == null) return const [];
  final items = <CheckItem>[
    CheckItem(CheckId.flutter, d.flutter.found ? CheckStatus.ok : CheckStatus.fail, {
      'version': d.flutter.version ?? '',
    }),
    if (hostIsMac)
      CheckItem(CheckId.xcode, d.xcode.found ? CheckStatus.ok : CheckStatus.fail, {'version': d.xcode.version ?? ''}),
    CheckItem(CheckId.adb, d.adb.found ? CheckStatus.ok : CheckStatus.warn, {'version': d.adb.version ?? ''}),
  ];

  if (device != null) {
    items.add(CheckItem(CheckId.connection, device.isUsb ? CheckStatus.ok : CheckStatus.fail, {'name': device.name}));
    if (device.platform == DevicePlatform.ios && device.developerModeOn != null) {
      items.add(CheckItem(CheckId.developerMode, device.developerModeOn! ? CheckStatus.ok : CheckStatus.fail));
    }
    if (device.platform == DevicePlatform.android) {
      items.add(CheckItem(CheckId.androidAuth, device.authorized ? CheckStatus.ok : CheckStatus.fail));
    }
  }

  if (hostIsMac) {
    final usable = d.distinctCerts.where((c) => c.hasPrivateKey).toList();
    items.add(
      CheckItem(CheckId.certificate, usable.isNotEmpty ? CheckStatus.ok : CheckStatus.fail, {
        'count': '${usable.length}',
      }),
    );
    for (final c in usable) {
      final days = c.daysLeft(now);
      if (days == null) continue;
      items.add(
        CheckItem(
          CheckId.certificateExpiry,
          days < 0 ? CheckStatus.fail : (days <= 30 ? CheckStatus.warn : CheckStatus.ok),
          {'name': c.name, 'days': '$days'},
        ),
      );
    }
    final team = teamId ?? project?.iosTeamId;
    final teamKnown = team != null && team.isNotEmpty;
    items.add(
      CheckItem(
        CheckId.team,
        !teamKnown
            ? CheckStatus.fail
            : (d.usableTeams.isEmpty || d.usableTeams.contains(team) ? CheckStatus.ok : CheckStatus.warn),
        {'team': team ?? ''},
      ),
    );
    final bundle = project?.iosBundleId;
    if (project != null && project.hasIos && bundle != null) {
      final matching = d.profiles.where((p) => p.matches(bundle) && (!teamKnown || p.teamId == team)).toList()
        ..sort((a, b) => (b.expires ?? DateTime(0)).compareTo(a.expires ?? DateTime(0)));
      if (matching.isEmpty) {
        // 자동 서명은 첫 빌드에서 프로파일을 만든다 — 실패가 아니라 안내다.
        items.add(CheckItem(CheckId.profile, CheckStatus.info, {'bundle': bundle}));
      } else {
        final p = matching.first;
        final days = p.daysLeft(now);
        items.add(
          CheckItem(
            CheckId.profile,
            days == null || days > 2 ? CheckStatus.ok : (days < 0 ? CheckStatus.fail : CheckStatus.warn),
            {'bundle': bundle, 'days': '${days ?? ''}', 'short': '${p.isShortLived}'},
          ),
        );
      }
    }
  }

  if (d.androidSigning != null) {
    items.add(
      CheckItem(
        CheckId.androidSigning,
        switch (d.androidSigning!) {
          AndroidSigning.keystore => CheckStatus.ok,
          AndroidSigning.debugKey => CheckStatus.info,
          AndroidSigning.keystoreMissing => CheckStatus.fail,
        },
        {'mode': d.androidSigning!.name},
      ),
    );
  }
  return items;
}

/// 한 번에 하나만 보여 주는 "지금 할 일": 막힌 것 중 가장 앞선 항목.
CheckItem? firstProblem(List<CheckItem> items) {
  for (final i in items) {
    if (i.status == CheckStatus.fail) return i;
  }
  return null;
}
