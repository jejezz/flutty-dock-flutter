import 'dart:io' show Platform;

import '../doctor/checks.dart';
import '../install/install_plan.dart';
import '../l10n/app_localizations.dart';

/// 점검 항목([CheckItem])을 화면 문구로 바꾼다 — 판단은 `doctor/checks.dart`, 문구는 여기.
String checkTitle(AppLocalizations l, CheckItem c) {
  final p = c.params;
  final s = c.status;
  return switch (c.id) {
    CheckId.flutter =>
      s == CheckStatus.ok
          ? l.checkFlutterOk(p['version']!)
          : p['error'] != null
          ? l.checkFlutterRunFail(p['error']!)
          : l.checkFlutterFail,
    CheckId.xcode => s == CheckStatus.ok ? l.checkXcodeOk(p['version']!) : l.checkXcodeFail,
    CheckId.adb => s == CheckStatus.ok ? l.checkAdbOk(p['version']!) : l.checkAdbWarn,
    CheckId.connection => s == CheckStatus.ok ? l.checkConnectionOk(p['name']!) : l.checkConnectionFail(p['name']!),
    CheckId.developerMode => s == CheckStatus.ok ? l.checkDeveloperModeOk : l.checkDeveloperModeFail,
    CheckId.androidAuth => s == CheckStatus.ok ? l.checkAndroidAuthOk : l.checkAndroidAuthFail,
    CheckId.certificate => s == CheckStatus.ok ? l.checkCertificateOk(p['count']!) : l.checkCertificateFail,
    CheckId.certificateExpiry => switch (s) {
      CheckStatus.ok => l.checkCertExpiryOk(p['name']!, p['days']!),
      CheckStatus.warn => l.checkCertExpiryWarn(p['name']!, p['days']!),
      _ => l.checkCertExpiryFail(p['name']!),
    },
    CheckId.team => switch (s) {
      CheckStatus.ok => l.checkTeamOk(p['team']!),
      CheckStatus.warn => l.checkTeamWarn(p['team']!),
      _ => l.checkTeamFail,
    },
    CheckId.profile => switch (s) {
      CheckStatus.ok => l.checkProfileOk(p['bundle']!, p['days']!),
      CheckStatus.warn => l.checkProfileWarn(p['bundle']!, p['days']!),
      CheckStatus.fail => l.checkProfileFail(p['bundle']!),
      CheckStatus.info => l.checkProfileInfo(p['bundle']!),
    },
    CheckId.windowsDeveloperMode => s == CheckStatus.ok ? l.checkWindowsDevModeOk : l.checkWindowsDevModeWarn,
    CheckId.visualStudio => s == CheckStatus.ok ? l.checkVisualStudioOk(p['version']!) : l.checkVisualStudioFail,
    CheckId.androidSigning => switch (p['mode']) {
      'keystore' => l.checkAndroidSigningKeystore,
      'keystoreMissing' => l.checkAndroidSigningMissing,
      _ => l.checkAndroidSigningDebugKey,
    },
  };
}

/// 덧붙일 한 줄 설명. 없으면 null.
String? checkNote(AppLocalizations l, CheckItem c) =>
    c.id == CheckId.profile && c.params['short'] == 'true' ? l.checkProfileShort : null;

/// 문제 항목을 고치는 단계별 안내(번호 붙은 여러 줄). 해결할 것이 없으면 null.
String? checkSteps(AppLocalizations l, CheckItem c) {
  if (c.status == CheckStatus.ok || c.status == CheckStatus.info) return null;
  return switch (c.id) {
    CheckId.flutter => Platform.isWindows ? l.stepsFlutterMissingWindows : l.stepsFlutterMissing,
    CheckId.xcode => l.stepsXcodeMissing,
    CheckId.adb => l.stepsAdbMissing,
    CheckId.connection => l.stepsWireless,
    CheckId.developerMode => l.stepsDeveloperMode,
    CheckId.androidAuth => l.stepsAndroidAuth,
    CheckId.certificate => l.stepsCertificate,
    CheckId.certificateExpiry || CheckId.profile => l.stepsCertExpiry,
    CheckId.team => l.stepsTeamId,
    CheckId.androidSigning => l.stepsAndroidKeystore,
    CheckId.windowsDeveloperMode => l.stepsWindowsDevMode,
    CheckId.visualStudio => l.stepsVisualStudio,
  };
}

String blockerText(AppLocalizations l, Blocker b) => switch (b) {
  Blocker.noProject => l.blockerNoProject,
  Blocker.noDevice => l.blockerNoDevice,
  Blocker.platformMissing => l.blockerPlatformMissing,
  Blocker.iosNeedsMac => l.blockerIosNeedsMac,
  Blocker.wireless => l.blockerWireless,
  Blocker.developerModeOff => l.blockerDeveloperModeOff,
  Blocker.androidUnauthorized => l.blockerAndroidUnauthorized,
  Blocker.needsTeamId => l.blockerNeedsTeamId,
};

String? blockerSteps(AppLocalizations l, Blocker b) => switch (b) {
  Blocker.wireless => l.stepsWireless,
  Blocker.developerModeOff => l.stepsDeveloperMode,
  Blocker.androidUnauthorized => l.stepsAndroidAuth,
  Blocker.needsTeamId => l.stepsTeamId,
  _ => null,
};

String failureHintText(AppLocalizations l, FailureHint h) => switch (h) {
  FailureHint.useUsb => l.hintUseUsb,
  FailureHint.unlockDevice => l.hintUnlockDevice,
  FailureHint.developerMode => l.hintDeveloperMode,
  FailureHint.signing => l.hintSigning,
  FailureHint.trustComputer => l.hintTrustComputer,
  FailureHint.noAdb => l.hintNoAdb,
  FailureHint.cocoapods => l.hintCocoapods,
  FailureHint.visualStudio => l.hintVisualStudio,
  FailureHint.restartApp => l.hintRestartApp,
  FailureHint.staleBuildCache => l.hintStaleBuildCache,
};

String? failureHintSteps(AppLocalizations l, FailureHint h) => switch (h) {
  FailureHint.useUsb || FailureHint.trustComputer => l.stepsWireless,
  FailureHint.developerMode => l.stepsDeveloperMode,
  FailureHint.signing => l.stepsTeamId,
  FailureHint.noAdb => l.stepsAdbMissing,
  FailureHint.cocoapods => l.stepsCocoapods,
  FailureHint.visualStudio => l.stepsVisualStudio,
  FailureHint.staleBuildCache => l.stepsStaleBuildCache,
  _ => null,
};
