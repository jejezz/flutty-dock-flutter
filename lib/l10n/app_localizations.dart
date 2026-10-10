import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @aboutTooltip.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get aboutTooltip;

  /// No description provided for @aboutVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version} (빌드 {build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @aboutOpenSourceLicenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get aboutOpenSourceLicenses;

  /// No description provided for @aboutRepository.
  ///
  /// In ko, this message translates to:
  /// **'GitHub'**
  String get aboutRepository;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @aboutMenuItem.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 정보'**
  String aboutMenuItem(String appName);

  /// No description provided for @themeMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get themeMenuTooltip;

  /// No description provided for @themeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따르기'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get themeDark;

  /// No description provided for @languageMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get languageMenuTooltip;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따르기 / System'**
  String get languageSystem;

  /// No description provided for @languageSystemShort.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get languageSystemShort;

  /// No description provided for @aboutTagline.
  ///
  /// In ko, this message translates to:
  /// **'Flutter 앱을 USB 실기기에 올리는 도킹형 도우미'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In ko, this message translates to:
  /// **'편집기 옆에 세워 두고 Flutter 프로젝트를 iPhone·Android 실기기에 debug/release로 빌드·설치합니다. 버튼마다 실제 실행되는 명령을 보여 주고, 서명 문제는 원인과 해결 단계로 안내합니다.'**
  String get aboutDescription;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'Flutter 프로젝트 폴더를 끌어다 놓으세요'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyAction.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 열기'**
  String get homeEmptyAction;

  /// No description provided for @updateCheckMenuItem.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 확인'**
  String get updateCheckMenuItem;

  /// No description provided for @updateChecking.
  ///
  /// In ko, this message translates to:
  /// **'업데이트를 확인하는 중…'**
  String get updateChecking;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 버전이 있습니다'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In ko, this message translates to:
  /// **'{appName} {latest} 버전이 나왔습니다. (현재 {current})'**
  String updateAvailableBody(String appName, String current, String latest);

  /// No description provided for @updateReleaseNotes.
  ///
  /// In ko, this message translates to:
  /// **'변경 내용'**
  String get updateReleaseNotes;

  /// No description provided for @updateNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 업데이트'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get updateLater;

  /// No description provided for @updateSkipVersion.
  ///
  /// In ko, this message translates to:
  /// **'이 버전 건너뛰기'**
  String get updateSkipVersion;

  /// No description provided for @updateDownloading.
  ///
  /// In ko, this message translates to:
  /// **'내려받는 중…'**
  String get updateDownloading;

  /// No description provided for @updateVerifying.
  ///
  /// In ko, this message translates to:
  /// **'파일을 확인하는 중…'**
  String get updateVerifying;

  /// No description provided for @updateDownloadProgress.
  ///
  /// In ko, this message translates to:
  /// **'{received} / {total}'**
  String updateDownloadProgress(String received, String total);

  /// No description provided for @updateCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get updateCancel;

  /// No description provided for @updateFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트하지 못했습니다'**
  String get updateFailedTitle;

  /// No description provided for @updateCheckFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트를 확인하지 못했습니다'**
  String get updateCheckFailedTitle;

  /// No description provided for @updateErrorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 서버에 연결하지 못했습니다. 인터넷 연결을 확인한 뒤 다시 시도해 주세요.'**
  String get updateErrorNetwork;

  /// No description provided for @updateErrorChecksum.
  ///
  /// In ko, this message translates to:
  /// **'내려받은 파일이 올바르지 않아 설치하지 않았습니다. 잠시 뒤에 다시 시도해 주세요.'**
  String get updateErrorChecksum;

  /// No description provided for @updateErrorInstall.
  ///
  /// In ko, this message translates to:
  /// **'설치를 시작하지 못했습니다.'**
  String get updateErrorInstall;

  /// No description provided for @updateErrorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 서버에서 예상하지 못한 응답을 받았습니다. 잠시 뒤에 다시 시도해 주세요.'**
  String get updateErrorGeneric;

  /// No description provided for @updateUpToDateTitle.
  ///
  /// In ko, this message translates to:
  /// **'최신 버전입니다'**
  String get updateUpToDateTitle;

  /// No description provided for @updateUpToDateBody.
  ///
  /// In ko, this message translates to:
  /// **'{version} 버전을 사용 중입니다.'**
  String updateUpToDateBody(String version);

  /// No description provided for @updateUnavailableTitle.
  ///
  /// In ko, this message translates to:
  /// **'직접 설치해 주세요'**
  String get updateUnavailableTitle;

  /// No description provided for @updateUnavailableBody.
  ///
  /// In ko, this message translates to:
  /// **'{latest} 버전이 있지만 앱에서 자동으로 설치할 수 없습니다. 릴리스 페이지에서 받아 주세요.'**
  String updateUnavailableBody(String latest);

  /// No description provided for @updateOpenReleasePage.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 페이지 열기'**
  String get updateOpenReleasePage;

  /// No description provided for @updateMacosOpenedTitle.
  ///
  /// In ko, this message translates to:
  /// **'설치 창이 열렸습니다'**
  String get updateMacosOpenedTitle;

  /// No description provided for @updateMacosOpenedBody.
  ///
  /// In ko, this message translates to:
  /// **'열린 창에서 {appName} 을(를) Applications 폴더로 끌어다 놓아 주세요. 실행 중이면 종료한 뒤 덮어쓰세요.'**
  String updateMacosOpenedBody(String appName);

  /// No description provided for @updateWindowsInstallTitle.
  ///
  /// In ko, this message translates to:
  /// **'설치 프로그램을 열었습니다'**
  String get updateWindowsInstallTitle;

  /// No description provided for @updateWindowsInstallBody.
  ///
  /// In ko, this message translates to:
  /// **'설치하려면 {appName} 을(를) 종료해야 합니다. 설치 프로그램의 안내를 따라 주세요.'**
  String updateWindowsInstallBody(String appName);

  /// No description provided for @updateQuitApp.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 종료'**
  String updateQuitApp(String appName);

  /// No description provided for @updateLinuxInstallTitle.
  ///
  /// In ko, this message translates to:
  /// **'설치를 준비했습니다'**
  String get updateLinuxInstallTitle;

  /// No description provided for @updateLinuxInstallBody.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 을(를) 종료하고 설치합니다. 설치가 끝나면 자동으로 다시 시작됩니다.'**
  String updateLinuxInstallBody(String appName);

  /// No description provided for @updateQuitAndInstall.
  ///
  /// In ko, this message translates to:
  /// **'종료하고 설치'**
  String get updateQuitAndInstall;

  /// No description provided for @updateBusyTitle.
  ///
  /// In ko, this message translates to:
  /// **'지금은 업데이트할 수 없습니다'**
  String get updateBusyTitle;

  /// No description provided for @updateBusyBody.
  ///
  /// In ko, this message translates to:
  /// **'작업이 진행 중입니다. 끝난 뒤에 다시 시도해 주세요.'**
  String get updateBusyBody;

  /// No description provided for @secretsTooltip.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 시크릿'**
  String get secretsTooltip;

  /// No description provided for @secretsTitle.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 시크릿 등록'**
  String get secretsTitle;

  /// No description provided for @secretsIntro.
  ///
  /// In ko, this message translates to:
  /// **'macOS 릴리스 워크플로가 서명·공증에 쓰는 GitHub Actions 시크릿을 gh로 등록합니다. 값은 이 앱에 저장되지 않습니다.'**
  String get secretsIntro;

  /// No description provided for @secretsRepoLabel.
  ///
  /// In ko, this message translates to:
  /// **'저장소 (owner/repo)'**
  String get secretsRepoLabel;

  /// No description provided for @secretsPickFolder.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 폴더에서 읽기'**
  String get secretsPickFolder;

  /// No description provided for @secretsRefresh.
  ///
  /// In ko, this message translates to:
  /// **'등록 상태 새로 고침'**
  String get secretsRefresh;

  /// No description provided for @secretsRepoInvalid.
  ///
  /// In ko, this message translates to:
  /// **'owner/repo 형식으로 입력하세요'**
  String get secretsRepoInvalid;

  /// No description provided for @secretsFolderNoRemote.
  ///
  /// In ko, this message translates to:
  /// **'이 폴더에서 GitHub 원격(origin)을 찾지 못했습니다'**
  String get secretsFolderNoRemote;

  /// No description provided for @secretsGhMissing.
  ///
  /// In ko, this message translates to:
  /// **'GitHub CLI(gh)가 없습니다. 터미널에서 이 명령으로 설치하세요:'**
  String get secretsGhMissing;

  /// No description provided for @secretsGhNotLoggedIn.
  ///
  /// In ko, this message translates to:
  /// **'gh에 로그인하지 않았습니다. 터미널에서 이 명령을 실행하세요:'**
  String get secretsGhNotLoggedIn;

  /// No description provided for @secretsListFailed.
  ///
  /// In ko, this message translates to:
  /// **'등록 상태를 읽지 못했습니다. 저장소 이름과 권한을 확인하세요'**
  String get secretsListFailed;

  /// No description provided for @secretStatusRegistered.
  ///
  /// In ko, this message translates to:
  /// **'등록됨 · {date}'**
  String secretStatusRegistered(String date);

  /// No description provided for @secretStatusMissing.
  ///
  /// In ko, this message translates to:
  /// **'미등록'**
  String get secretStatusMissing;

  /// No description provided for @secretStatusUnknown.
  ///
  /// In ko, this message translates to:
  /// **'확인 안 됨'**
  String get secretStatusUnknown;

  /// No description provided for @secretSet.
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get secretSet;

  /// No description provided for @secretOverwrite.
  ///
  /// In ko, this message translates to:
  /// **'덮어쓰기'**
  String get secretOverwrite;

  /// No description provided for @secretPickFile.
  ///
  /// In ko, this message translates to:
  /// **'파일 선택…'**
  String get secretPickFile;

  /// No description provided for @secretNoFile.
  ///
  /// In ko, this message translates to:
  /// **'선택한 파일 없음'**
  String get secretNoFile;

  /// No description provided for @secretFileLoaded.
  ///
  /// In ko, this message translates to:
  /// **'{name} · {bytes}바이트'**
  String secretFileLoaded(String name, int bytes);

  /// No description provided for @secretGenerate.
  ///
  /// In ko, this message translates to:
  /// **'무작위 생성'**
  String get secretGenerate;

  /// No description provided for @secretGenerated.
  ///
  /// In ko, this message translates to:
  /// **'무작위 값을 만들었습니다 (화면에 표시하지 않음)'**
  String get secretGenerated;

  /// No description provided for @secretViaStdin.
  ///
  /// In ko, this message translates to:
  /// **'값은 명령 인자가 아니라 표준 입력으로 전달되어 명령 기록에 남지 않습니다.'**
  String get secretViaStdin;

  /// No description provided for @secretIssueEmpty.
  ///
  /// In ko, this message translates to:
  /// **'값을 입력하세요'**
  String get secretIssueEmpty;

  /// No description provided for @secretIssueEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일 형식이 아닙니다'**
  String get secretIssueEmail;

  /// No description provided for @secretIssueTeamId.
  ///
  /// In ko, this message translates to:
  /// **'Team ID는 영문 대문자·숫자 10자입니다'**
  String get secretIssueTeamId;

  /// No description provided for @secretSaved.
  ///
  /// In ko, this message translates to:
  /// **'{name} 등록했습니다'**
  String secretSaved(String name);

  /// No description provided for @secretFailed.
  ///
  /// In ko, this message translates to:
  /// **'{name} 등록에 실패했습니다'**
  String secretFailed(String name);

  /// No description provided for @secretOverwriteTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name}을(를) 덮어쓸까요?'**
  String secretOverwriteTitle(String name);

  /// No description provided for @secretOverwriteBody.
  ///
  /// In ko, this message translates to:
  /// **'이미 등록된 값을 새 값으로 바꿉니다. 되돌릴 수 없습니다.'**
  String get secretOverwriteBody;

  /// No description provided for @secretHelpP12.
  ///
  /// In ko, this message translates to:
  /// **'키체인 접근에서 \'Developer ID Application\' 인증서를 .p12로 내보낸 파일을 고르세요. 앱이 base64로 바꿔 등록합니다.'**
  String get secretHelpP12;

  /// No description provided for @secretHelpP12Password.
  ///
  /// In ko, this message translates to:
  /// **'.p12를 내보낼 때 지정한 암호입니다.'**
  String get secretHelpP12Password;

  /// No description provided for @secretHelpKeychain.
  ///
  /// In ko, this message translates to:
  /// **'CI가 빌드 중에만 쓰는 임시 키체인 암호입니다. 아무 값이나 괜찮아서 무작위로 만들어 드립니다.'**
  String get secretHelpKeychain;

  /// No description provided for @secretHelpAppleId.
  ///
  /// In ko, this message translates to:
  /// **'공증(notarization)에 쓰는 Apple ID 이메일입니다.'**
  String get secretHelpAppleId;

  /// No description provided for @secretHelpApplePassword.
  ///
  /// In ko, this message translates to:
  /// **'앱 암호(app-specific password)입니다. 계정 비밀번호가 아닙니다.'**
  String get secretHelpApplePassword;

  /// No description provided for @secretHelpTeamId.
  ///
  /// In ko, this message translates to:
  /// **'developer.apple.com/account의 Membership details에 있는 10자리 Team ID입니다.'**
  String get secretHelpTeamId;

  /// No description provided for @secretOpenAppleId.
  ///
  /// In ko, this message translates to:
  /// **'appleid.apple.com 열기'**
  String get secretOpenAppleId;

  /// No description provided for @secretOpenDeveloper.
  ///
  /// In ko, this message translates to:
  /// **'developer.apple.com/account 열기'**
  String get secretOpenDeveloper;

  /// No description provided for @commandBarEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 실행한 명령이 없습니다'**
  String get commandBarEmpty;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
