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
  String get aboutTagline => 'A docked helper for putting Flutter apps on real devices over USB';

  @override
  String get aboutDescription => 'Dock it beside your editor to build and install a Flutter project on an iPhone or Android phone in debug or release. Every button shows the command it runs, and signing problems come with the cause and the steps to fix them.';

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
  String get updateErrorNetwork => 'Couldn\'t reach the update server. Check your internet connection and try again.';

  @override
  String get updateErrorChecksum => 'The downloaded file didn\'t pass verification, so it was not installed. Please try again later.';

  @override
  String get updateErrorInstall => 'Couldn\'t start the installation.';

  @override
  String get updateErrorGeneric => 'The update server sent an unexpected response. Please try again later.';

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
  String get updateBusyBody => 'A task is in progress. Please try again when it has finished.';

  @override
  String get secretsTooltip => 'Release secrets';

  @override
  String get secretsTitle => 'Register release secrets';

  @override
  String get secretsIntro => 'Registers the GitHub Actions secrets that the macOS release workflow uses for signing and notarization, through gh. Values are not stored in this app.';

  @override
  String get secretsRepoLabel => 'Repository (owner/repo)';

  @override
  String get secretsPickFolder => 'Read from a project folder';

  @override
  String get secretsRefresh => 'Refresh registration status';

  @override
  String get secretsRepoInvalid => 'Use the owner/repo form';

  @override
  String get secretsFolderNoRemote => 'No GitHub remote (origin) found in that folder';

  @override
  String get secretsGhMissing => 'GitHub CLI (gh) isn\'t installed. Install it in a terminal with:';

  @override
  String get secretsGhNotLoggedIn => 'gh isn\'t signed in. Run this in a terminal:';

  @override
  String get secretsListFailed => 'Couldn\'t read the registration status. Check the repository name and your access';

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
  String get secretViaStdin => 'The value is passed on standard input, not as a command argument, so it never appears in the command log.';

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
  String get secretOverwriteBody => 'This replaces the registered value with the new one. It can\'t be undone.';

  @override
  String get secretHelpP12 => 'Choose the \'Developer ID Application\' certificate exported as .p12 from Keychain Access. The app registers it as base64.';

  @override
  String get secretHelpP12Password => 'The password you set when exporting the .p12.';

  @override
  String get secretHelpKeychain => 'A temporary keychain password CI uses only during the build. Any value works, so it can be generated for you.';

  @override
  String get secretHelpAppleId => 'The Apple ID email used for notarization.';

  @override
  String get secretHelpApplePassword => 'An app-specific password, not your account password.';

  @override
  String get secretHelpTeamId => 'The 10-character Team ID from Membership details at developer.apple.com/account.';

  @override
  String get secretOpenAppleId => 'Open appleid.apple.com';

  @override
  String get secretOpenDeveloper => 'Open developer.apple.com/account';

  @override
  String get commandBarEmpty => 'No commands run yet';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get homeProjectTitle => 'Project';

  @override
  String get homeProjectOpen => 'Open project';

  @override
  String get homeProjectChange => 'Change';

  @override
  String get homeProjectReload => 'Reload this project';

  @override
  String get homeProjectDrop => 'Drop a Flutter project folder here, or press Open project';

  @override
  String homeProjectNotFlutter(String path) {
    return 'Not a Flutter project: $path';
  }

  @override
  String get homePlatformIos => 'iOS';

  @override
  String get homePlatformAndroid => 'Android';

  @override
  String get homeDevicesTitle => 'Devices';

  @override
  String get homeDevicesRefresh => 'Refresh devices';

  @override
  String get homeDevicesNone => 'No device is connected over USB. Plug in your phone, unlock it, then refresh';

  @override
  String get homeLinkUsb => 'USB';

  @override
  String get homeLinkWireless => 'Wireless';

  @override
  String get homeBuildTitle => 'Build';

  @override
  String get homeModeDebug => 'Debug';

  @override
  String get homeModeRelease => 'Release';

  @override
  String get homeTeamLabel => 'Apple Team ID';

  @override
  String get homeTeamHelp => 'Passed only as a build argument — the project is not modified. Find it at developer.apple.com/account → Membership';

  @override
  String get homeStepsTitle => 'Commands to run';

  @override
  String get homeStepPrepare => 'Prepare';

  @override
  String get homeStepBuild => 'Build';

  @override
  String get homeStepInstall => 'Install';

  @override
  String get homeStepLaunch => 'Launch';

  @override
  String get homeStepRun => 'Run (hot reload)';

  @override
  String get homeActionInstall => 'Build & install';

  @override
  String get homeActionBuildRun => 'Build & run';

  @override
  String get homeActionInstallOnly => 'Install only';

  @override
  String get homeActionClean => 'Clean & get packages';

  @override
  String get homeCleanHelp => 'flutter clean → flutter pub get. Worth trying when a build fails for no clear reason.';

  @override
  String get optTitle => 'Build options';

  @override
  String get optDefault => 'Defaults';

  @override
  String get optFlavor => 'Flavor';

  @override
  String get optFlavorHelp => '--flavor. Only if the project defines flavors';

  @override
  String get optFlavorInvalid => 'Start with a letter; letters, digits, _ and - only';

  @override
  String get optFlavorWindows => 'Windows does not support flavors, so this is ignored';

  @override
  String get optTarget => 'Entry point';

  @override
  String get optTargetHelp => '-t. Empty means lib/main.dart';

  @override
  String get optDefineFile => 'dart-define file';

  @override
  String get optDefineFileHelp => '--dart-define-from-file. Only the path is stored; the file is never read or saved';

  @override
  String get optFileMissing => 'File not found';

  @override
  String get optAppId => 'App ID (optional)';

  @override
  String get optAppIdHelp => 'When the flavor changes the app ID, the ID to launch after installing (e.g. art.zoomon.app.dev)';

  @override
  String get optExtra => 'Extra arguments';

  @override
  String get optExtraHelp => 'e.g. --obfuscate --split-debug-info=build/symbols';

  @override
  String get optPick => 'Choose file';

  @override
  String get optClear => 'Clear options';

  @override
  String get homeCleanDone => 'Cleaned and packages restored. Try building again.';

  @override
  String get homeCleanFailed => 'Clean failed. Check the output in the Log tab.';

  @override
  String get homeActionRun => 'Run debug';

  @override
  String get homeActionCancel => 'Cancel';

  @override
  String get homeActionStop => 'Stop';

  @override
  String get homeHotReload => 'Hot reload';

  @override
  String get homeHotRestart => 'Hot restart';

  @override
  String get homeOutputTitle => 'Output';

  @override
  String get homeCopyCommand => 'Copy command';

  @override
  String get blockerNoProject => 'Open a Flutter project first';

  @override
  String get blockerNoDevice => 'Connect and select a device';

  @override
  String get blockerPlatformMissing => 'This project has no folder (ios/ or android/) for the selected device\'s platform';

  @override
  String get blockerIosNeedsMac => 'Installing on an iPhone needs macOS and Xcode';

  @override
  String get blockerWireless => 'This device is connected wirelessly. Use a USB cable — installs drop over wireless';

  @override
  String get blockerDeveloperModeOff => 'Developer Mode is off on the iPhone. Turn it on in Settings → Privacy & Security → Developer Mode, then restart';

  @override
  String get blockerAndroidUnauthorized => 'Approve this computer in the \'Allow USB debugging\' prompt on the phone';

  @override
  String get blockerNeedsTeamId => 'Enter the Apple Team ID to sign iOS builds with';

  @override
  String get hintUseUsb => 'The connection dropped. Make sure the phone is on a USB cable, not wireless';

  @override
  String get hintUnlockDevice => 'The iPhone is locked. Unlock it and try again';

  @override
  String get hintDeveloperMode => 'Turn on Developer Mode on the iPhone: Settings → Privacy & Security → Developer Mode';

  @override
  String get hintSigning => 'A signing profile problem. Check the Team ID and that Xcode is signed in to your Apple account';

  @override
  String get hintTrustComputer => 'Tap \'Trust This Computer\' on the iPhone';

  @override
  String get hintNoAdb => 'adb wasn\'t found. Install the Android SDK platform-tools and add it to PATH';

  @override
  String hintMissingCommand(String command) {
    return 'The $command command wasn\'t found. Install it and make sure it is on PATH';
  }

  @override
  String get tabInstall => 'Run';

  @override
  String get tabDevices => 'Devices';

  @override
  String get tabSigning => 'Signing';

  @override
  String get tabDoctor => 'Doctor';

  @override
  String get tabLog => 'Log';

  @override
  String get bannerNextStep => 'Next step';

  @override
  String get bannerShowSteps => 'Show how to fix';

  @override
  String get doctorRun => 'Check again';

  @override
  String get doctorRunning => 'Checking…';

  @override
  String get doctorNever => 'Not checked yet';

  @override
  String doctorCollected(String time) {
    return 'Checked at $time';
  }

  @override
  String get doctorAllGood => 'No problems found';

  @override
  String get signingTeams => 'Signing team';

  @override
  String get signingTeamsHelp => 'Teams of certificates whose private key is in your keychain. Tap one to sign with it';

  @override
  String get signingNoTeams => 'No usable development certificate';

  @override
  String get signingCerts => 'Development certificates';

  @override
  String get signingProfiles => 'Profiles for this project';

  @override
  String get signingNoProfiles => 'None yet — Xcode creates one on the first build';

  @override
  String get signingShortLived => '7-day profile';

  @override
  String get signingNoKey => 'No private key';

  @override
  String signingDaysLeft(String days) {
    return '$days days left';
  }

  @override
  String get signingExpired => 'Expired';

  @override
  String get signingAndroid => 'Android release signing';

  @override
  String get signingMacOnly => 'iOS signing checks run on macOS only';

  @override
  String get elevatedTitle => 'Running as administrator';

  @override
  String get elevatedBody => 'Builds with flutter (CMake) can fail when run as administrator. The app will close and reopen with normal permissions.';

  @override
  String get elevatedQuit => 'Close and reopen';

  @override
  String get logClear => 'Clear log';

  @override
  String get outputCopyAll => 'Copy all output';

  @override
  String get outputCopied => 'Output copied';

  @override
  String get outputViewer => 'Open in viewer';

  @override
  String get viewerPause => 'Pause updates (to select text)';

  @override
  String get viewerResume => 'Resume live updates';

  @override
  String viewerLines(Object count) {
    return '$count lines';
  }

  @override
  String get logEmpty => 'No commands run yet';

  @override
  String get logRunning => 'Running';

  @override
  String logExit(String code) {
    return 'Exit code $code';
  }

  @override
  String checkFlutterOk(String version) {
    return 'Flutter $version';
  }

  @override
  String checkFlutterRunFail(String error) {
    return 'flutter ran but failed: $error';
  }

  @override
  String get checkFlutterFail => 'flutter wasn\'t found';

  @override
  String checkXcodeOk(String version) {
    return 'Xcode $version';
  }

  @override
  String get checkXcodeFail => 'Xcode wasn\'t found';

  @override
  String checkAdbOk(String version) {
    return 'adb $version';
  }

  @override
  String get checkAdbWarn => 'adb wasn\'t found (needed to install on Android)';

  @override
  String checkConnectionOk(String name) {
    return '$name: connected over USB';
  }

  @override
  String checkConnectionFail(String name) {
    return '$name: connected wirelessly, not over USB';
  }

  @override
  String get checkDeveloperModeOk => 'Developer Mode is on';

  @override
  String get checkDeveloperModeFail => 'Developer Mode is off on the iPhone';

  @override
  String get checkAndroidAuthOk => 'USB debugging approved';

  @override
  String get checkAndroidAuthFail => 'USB debugging not approved';

  @override
  String checkCertificateOk(String count) {
    return '$count development certificate(s) with a private key';
  }

  @override
  String get checkCertificateFail => 'No usable Apple Development certificate';

  @override
  String checkCertExpiryOk(String name, String days) {
    return '$name · $days days left';
  }

  @override
  String checkCertExpiryWarn(String name, String days) {
    return '$name · expires in $days days';
  }

  @override
  String checkCertExpiryFail(String name) {
    return '$name · expired';
  }

  @override
  String checkTeamOk(String team) {
    return 'Signing team $team';
  }

  @override
  String get checkTeamFail => 'No signing Team ID chosen';

  @override
  String checkTeamWarn(String team) {
    return 'No certificate for team $team on this Mac';
  }

  @override
  String checkProfileOk(String bundle, String days) {
    return '$bundle profile · $days days left';
  }

  @override
  String checkProfileWarn(String bundle, String days) {
    return '$bundle profile expires soon ($days days left)';
  }

  @override
  String checkProfileFail(String bundle) {
    return '$bundle profile expired';
  }

  @override
  String checkProfileInfo(String bundle) {
    return 'No $bundle profile yet — it is created automatically on the first build';
  }

  @override
  String get checkProfileShort => 'A 7-day profile from a free account. When it expires, build and install again';

  @override
  String get checkAndroidSigningDebugKey => 'No keystore configured — signed with the debug key (fine for installing on your own device)';

  @override
  String get checkAndroidSigningKeystore => 'Signed with the release keystore';

  @override
  String get checkAndroidSigningMissing => 'The keystore file key.properties points to is missing';

  @override
  String get stepsWireless => '1. Connect the iPhone to the Mac with a USB cable\n2. Unlock it and tap \'Trust This Computer\'\n3. Press Refresh devices and check the USB badge appears';

  @override
  String get stepsDeveloperMode => '1. On the iPhone: Settings → Privacy & Security → Developer Mode\n2. Turn it on and restart\n3. After the restart, tap \'Turn On\' in the confirmation prompt';

  @override
  String get stepsAndroidAuth => '1. Connect the phone over USB and unlock it\n2. Allow this computer in the \'Allow USB debugging\' prompt\n3. If no prompt appears, enable USB debugging in Developer options';

  @override
  String get stepsTeamId => '1. Find the Team ID (10 characters) at developer.apple.com/account → Membership details\n2. Enter it in Apple Team ID under Build\n3. Or tap a team of your certificates in the Signing tab';

  @override
  String get stepsCertificate => '1. Xcode → Settings → Accounts: sign in with your Apple ID\n2. Manage Certificates → + → add Apple Development\n3. Press Check again';

  @override
  String get stepsFlutterMissing => '1. Install the Flutter SDK from flutter.dev\n2. Add flutter/bin to PATH (~/.zshrc)\n3. Reopen the app and press Check again';

  @override
  String get stepsFlutterMissingWindows => '1. Install the Flutter SDK from flutter.dev\n2. Add the flutter\\bin folder to PATH, or pick flutter.bat with \"Set tool paths…\" above\n3. Press Check again';

  @override
  String get stepsXcodeMissing => '1. Install Xcode from the App Store\n2. In a terminal run sudo xcode-select -s /Applications/Xcode.app\n3. Open Xcode once and accept the license';

  @override
  String get stepsAdbMissing => '1. Install the Android SDK platform-tools (Android Studio SDK Manager)\n2. Add the platform-tools folder to PATH\n3. Press Check again';

  @override
  String get stepsAndroidKeystore => '1. Check the storeFile path in android/key.properties\n2. If the file is gone, recreate the keystore or fix the path\n3. For personal installs you can drop key.properties — the debug key signs the build';

  @override
  String get stepsCertExpiry => '1. Xcode → Settings → Accounts → Manage Certificates: create a new Apple Development certificate\n2. Press Check again';

  @override
  String get homeOpenVsCode => 'Open in VS Code';

  @override
  String get vscodeNotFound => 'VS Code wasn\'t found';

  @override
  String get vscodeDownload => 'Get it';

  @override
  String get vscodeOpenFailed => 'Couldn\'t open VS Code';

  @override
  String get secretFileTitle => 'Register from a file';

  @override
  String get secretFileHelp => 'Registers every entry of a NAME=value (.env) file with gh secret set -f. The app doesn\'t keep the values — it only shows the names; gh reads the file itself.';

  @override
  String get secretFileEmpty => 'No NAME=value entries found';

  @override
  String secretFileUnknown(String names) {
    return 'Entries that aren\'t release secrets are registered too: $names';
  }

  @override
  String secretFileMissing(String names) {
    return 'Release secrets not in the file: $names';
  }

  @override
  String get secretFileRegister => 'Register file';

  @override
  String secretFileConfirmTitle(int count) {
    return 'Register $count secrets?';
  }

  @override
  String secretFileSaved(int count) {
    return 'Registered $count secrets';
  }

  @override
  String get secretFileFailed => 'Couldn\'t register from the file';

  @override
  String get toolPathsOpen => 'Set tool paths…';

  @override
  String get toolPathsTitle => 'Tool paths';

  @override
  String get toolPathsHelp => 'Point the app at tools it can\'t find on PATH. The choice is saved and used the next time too. Pick the executable file, not the folder.';

  @override
  String get toolPathNotFound => 'Not found';

  @override
  String get toolPathChoose => 'Locate…';

  @override
  String get toolPathAuto => 'Automatic';

  @override
  String get toolPathCustom => 'Custom';

  @override
  String get toolPathFlutter => 'flutter';

  @override
  String get toolPathAdb => 'adb (Android SDK platform-tools)';

  @override
  String get homeDevicesCauses => 'Possible reasons no device shows up';

  @override
  String get stepsNoDevice => '1. Connect the phone with a USB cable (a charge-only cable won\'t work)\n2. Unlock it, then tap \'Trust This Computer\' on an iPhone or \'Allow USB debugging\' on Android\n3. Press refresh above';

  @override
  String get homeThisMac => 'This Mac';

  @override
  String get homeThisPc => 'This PC';

  @override
  String get homeLinkLocal => 'This computer';

  @override
  String get homePlatformMacos => 'macOS';

  @override
  String get homePlatformWindows => 'Windows';

  @override
  String get hintCocoapods => 'CocoaPods is missing, so the macOS app couldn\'t be built';

  @override
  String get hintVisualStudio => 'Visual Studio\'s \'Desktop development with C++\' workload is missing, so the Windows app couldn\'t be built';

  @override
  String get hintRestartApp => 'The build failed because the build environment wasn\'t ready (plugin links not found). Closing and reopening the app fixes it';

  @override
  String get restartAppButton => 'Close and reopen';

  @override
  String get homeActionBuildOnly => 'Build only';

  @override
  String get homeActionRunOnly => 'Run only';

  @override
  String get homeRunOnlyNeedsBuild => 'No release build to run. Build first';

  @override
  String get gitTitle => 'Git';

  @override
  String get gitDetached => 'Detached HEAD';

  @override
  String get gitUpToDate => 'Up to date with the remote';

  @override
  String gitAhead(int count) {
    return '$count ahead of the remote';
  }

  @override
  String gitBehind(int count) {
    return '$count behind the remote';
  }

  @override
  String get gitNoUpstream => 'No upstream branch';

  @override
  String get gitDirty => 'Uncommitted changes';

  @override
  String get gitNoRemote => 'No remote';

  @override
  String get gitOpenRemote => 'Open the remote repository in a browser';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitPullHelp => 'git pull --ff-only — fast-forwards only, never merges';

  @override
  String get gitPullBlockedDirty => 'Not pulling: there are uncommitted changes';

  @override
  String get gitPullBlockedDiverged => 'Local and remote have diverged. Merge in a terminal';

  @override
  String get gitPullBlockedNoUpstream => 'This branch has no upstream';

  @override
  String get gitPullBlockedUpToDate => 'Nothing to pull (fetch first)';

  @override
  String get gitFetchDone => 'Fetched';

  @override
  String get gitPullDone => 'Pulled';

  @override
  String get gitFailed => 'Failed. See the output in the Log tab. If credentials are needed, sign in once in a terminal';

  @override
  String get stepsCocoapods => '1. Run brew install cocoapods in a terminal\n2. Build again';

  @override
  String get stepsVisualStudio => '1. Install Visual Studio 2022 (Community is fine)\n2. In the installer pick \'Desktop development with C++\'\n3. Build again';
}
