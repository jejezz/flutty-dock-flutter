// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutTooltip => 'About';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get aboutOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get aboutRepository => 'GitHub';

  @override
  String get commonClose => 'Close';

  @override
  String aboutMenuItem(String appName) {
    return 'About $appName';
  }

  @override
  String get themeMenuTooltip => 'Theme';

  @override
  String get themeSystem => 'Follow System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageMenuTooltip => 'Language';

  @override
  String get languageSystem => 'System / 시스템 설정 따르기';

  @override
  String get languageSystemShort => 'System';

  @override
  String get aboutTagline =>
      'A docked helper for putting Flutter apps on real devices over USB';

  @override
  String get aboutDescription =>
      'Dock it beside your editor to build and install a Flutter project on an iPhone or Android phone in debug or release. Every button shows the command it runs, and signing problems come with the cause and the steps to fix them.';

  @override
  String get homeEmptyTitle => 'Drop a Flutter project folder to get started';

  @override
  String get homeEmptyAction => 'Open project';

  @override
  String get updateCheckMenuItem => 'Check for Updates';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateAvailableTitle => 'A new version is available';

  @override
  String updateAvailableBody(String appName, String current, String latest) {
    return '$appName $latest is available. You have $current.';
  }

  @override
  String get updateReleaseNotes => 'What\'s new';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get updateSkipVersion => 'Skip this version';

  @override
  String get updateDownloading => 'Downloading…';

  @override
  String get updateVerifying => 'Verifying the file…';

  @override
  String updateDownloadProgress(String received, String total) {
    return '$received / $total';
  }

  @override
  String get updateCancel => 'Cancel';

  @override
  String get updateFailedTitle => 'Couldn\'t update';

  @override
  String get updateCheckFailedTitle => 'Couldn\'t check for updates';

  @override
  String get updateErrorNetwork =>
      'Couldn\'t reach the update server. Check your internet connection and try again.';

  @override
  String get updateErrorChecksum =>
      'The downloaded file didn\'t pass verification, so it was not installed. Please try again later.';

  @override
  String get updateErrorInstall => 'Couldn\'t start the installation.';

  @override
  String get updateErrorGeneric =>
      'The update server sent an unexpected response. Please try again later.';

  @override
  String get updateUpToDateTitle => 'You\'re up to date';

  @override
  String updateUpToDateBody(String version) {
    return 'You\'re using version $version.';
  }

  @override
  String get updateUnavailableTitle => 'Install it manually';

  @override
  String updateUnavailableBody(String latest) {
    return 'Version $latest is available, but the app can\'t install it automatically. Please download it from the release page.';
  }

  @override
  String get updateOpenReleasePage => 'Open release page';

  @override
  String get updateMacosOpenedTitle => 'The installer window is open';

  @override
  String updateMacosOpenedBody(String appName) {
    return 'In the window that opened, drag $appName to the Applications folder. If it\'s running, quit it first and replace the old copy.';
  }

  @override
  String get updateWindowsInstallTitle => 'The installer is open';

  @override
  String updateWindowsInstallBody(String appName) {
    return '$appName must quit before it can be updated. Follow the installer\'s instructions.';
  }

  @override
  String updateQuitApp(String appName) {
    return 'Quit $appName';
  }

  @override
  String get updateLinuxInstallTitle => 'Ready to install';

  @override
  String updateLinuxInstallBody(String appName) {
    return '$appName will quit and install the update, then start again automatically.';
  }

  @override
  String get updateQuitAndInstall => 'Quit and install';

  @override
  String get updateBusyTitle => 'Can\'t update right now';

  @override
  String get updateBusyBody =>
      'A task is in progress. Please try again when it has finished.';

  @override
  String get secretsTooltip => 'Release secrets';

  @override
  String get secretsTitle => 'Register release secrets';

  @override
  String get secretsIntro =>
      'Registers the GitHub Actions secrets that the macOS release workflow uses for signing and notarization, through gh. Values are not stored in this app.';

  @override
  String get secretsRepoLabel => 'Repository (owner/repo)';

  @override
  String get secretsPickFolder => 'Read from a project folder';

  @override
  String get secretsRefresh => 'Refresh registration status';

  @override
  String get secretsRepoInvalid => 'Use the owner/repo form';

  @override
  String get secretsFolderNoRemote =>
      'No GitHub remote (origin) found in that folder';

  @override
  String get secretsGhMissing =>
      'GitHub CLI (gh) isn\'t installed. Install it in a terminal with:';

  @override
  String get secretsGhNotLoggedIn =>
      'gh isn\'t signed in. Run this in a terminal:';

  @override
  String get secretsListFailed =>
      'Couldn\'t read the registration status. Check the repository name and your access';

  @override
  String secretStatusRegistered(String date) {
    return 'Registered · $date';
  }

  @override
  String get secretStatusMissing => 'Not registered';

  @override
  String get secretStatusUnknown => 'Unknown';

  @override
  String get secretSet => 'Register';

  @override
  String get secretOverwrite => 'Overwrite';

  @override
  String get secretPickFile => 'Choose file…';

  @override
  String get secretNoFile => 'No file chosen';

  @override
  String secretFileLoaded(String name, int bytes) {
    return '$name · $bytes bytes';
  }

  @override
  String get secretGenerate => 'Generate';

  @override
  String get secretGenerated => 'A random value was generated (not shown)';

  @override
  String get secretViaStdin =>
      'The value is passed on standard input, not as a command argument, so it never appears in the command log.';

  @override
  String get secretIssueEmpty => 'Enter a value';

  @override
  String get secretIssueEmail => 'Not an email address';

  @override
  String get secretIssueTeamId => 'A Team ID is 10 uppercase letters or digits';

  @override
  String secretSaved(String name) {
    return 'Registered $name';
  }

  @override
  String secretFailed(String name) {
    return 'Couldn\'t register $name';
  }

  @override
  String secretOverwriteTitle(String name) {
    return 'Overwrite $name?';
  }

  @override
  String get secretOverwriteBody =>
      'This replaces the registered value with the new one. It can\'t be undone.';

  @override
  String get secretHelpP12 =>
      'Choose the \'Developer ID Application\' certificate exported as .p12 from Keychain Access. The app registers it as base64.';

  @override
  String get secretHelpP12Password =>
      'The password you set when exporting the .p12.';

  @override
  String get secretHelpKeychain =>
      'A temporary keychain password CI uses only during the build. Any value works, so it can be generated for you.';

  @override
  String get secretHelpAppleId => 'The Apple ID email used for notarization.';

  @override
  String get secretHelpApplePassword =>
      'An app-specific password, not your account password.';

  @override
  String get secretHelpTeamId =>
      'The 10-character Team ID from Membership details at developer.apple.com/account.';

  @override
  String get secretOpenAppleId => 'Open appleid.apple.com';

  @override
  String get secretOpenDeveloper => 'Open developer.apple.com/account';

  @override
  String get commandBarEmpty => 'No commands run yet';

  @override
  String get commonCancel => 'Cancel';
}
