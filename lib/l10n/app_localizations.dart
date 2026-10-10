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

  /// No description provided for @homeProjectTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트'**
  String get homeProjectTitle;

  /// No description provided for @homeProjectOpen.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 열기'**
  String get homeProjectOpen;

  /// No description provided for @homeProjectChange.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get homeProjectChange;

  /// No description provided for @homeProjectDrop.
  ///
  /// In ko, this message translates to:
  /// **'Flutter 프로젝트 폴더를 여기로 끌어다 놓거나 [프로젝트 열기]를 누르세요'**
  String get homeProjectDrop;

  /// No description provided for @homeProjectNotFlutter.
  ///
  /// In ko, this message translates to:
  /// **'Flutter 프로젝트가 아닙니다: {path}'**
  String homeProjectNotFlutter(String path);

  /// No description provided for @homePlatformIos.
  ///
  /// In ko, this message translates to:
  /// **'iOS'**
  String get homePlatformIos;

  /// No description provided for @homePlatformAndroid.
  ///
  /// In ko, this message translates to:
  /// **'Android'**
  String get homePlatformAndroid;

  /// No description provided for @homeDevicesTitle.
  ///
  /// In ko, this message translates to:
  /// **'기기'**
  String get homeDevicesTitle;

  /// No description provided for @homeDevicesRefresh.
  ///
  /// In ko, this message translates to:
  /// **'기기 새로 고침'**
  String get homeDevicesRefresh;

  /// No description provided for @homeDevicesNone.
  ///
  /// In ko, this message translates to:
  /// **'USB로 연결된 기기가 없습니다. 폰을 USB로 연결하고 잠금을 푼 뒤 새로 고치세요'**
  String get homeDevicesNone;

  /// No description provided for @homeLinkUsb.
  ///
  /// In ko, this message translates to:
  /// **'USB'**
  String get homeLinkUsb;

  /// No description provided for @homeLinkWireless.
  ///
  /// In ko, this message translates to:
  /// **'무선'**
  String get homeLinkWireless;

  /// No description provided for @homeBuildTitle.
  ///
  /// In ko, this message translates to:
  /// **'빌드'**
  String get homeBuildTitle;

  /// No description provided for @homeModeDebug.
  ///
  /// In ko, this message translates to:
  /// **'Debug'**
  String get homeModeDebug;

  /// No description provided for @homeModeRelease.
  ///
  /// In ko, this message translates to:
  /// **'Release'**
  String get homeModeRelease;

  /// No description provided for @homeTeamLabel.
  ///
  /// In ko, this message translates to:
  /// **'Apple Team ID'**
  String get homeTeamLabel;

  /// No description provided for @homeTeamHelp.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트를 고치지 않고 빌드 인자로만 넘깁니다. developer.apple.com/account → Membership에서 확인하세요'**
  String get homeTeamHelp;

  /// No description provided for @homeStepsTitle.
  ///
  /// In ko, this message translates to:
  /// **'실행할 명령'**
  String get homeStepsTitle;

  /// No description provided for @homeStepPrepare.
  ///
  /// In ko, this message translates to:
  /// **'준비'**
  String get homeStepPrepare;

  /// No description provided for @homeStepBuild.
  ///
  /// In ko, this message translates to:
  /// **'빌드'**
  String get homeStepBuild;

  /// No description provided for @homeStepInstall.
  ///
  /// In ko, this message translates to:
  /// **'설치'**
  String get homeStepInstall;

  /// No description provided for @homeStepLaunch.
  ///
  /// In ko, this message translates to:
  /// **'실행'**
  String get homeStepLaunch;

  /// No description provided for @homeStepRun.
  ///
  /// In ko, this message translates to:
  /// **'실행 (핫 리로드)'**
  String get homeStepRun;

  /// No description provided for @homeActionInstall.
  ///
  /// In ko, this message translates to:
  /// **'빌드 & 설치'**
  String get homeActionInstall;

  /// No description provided for @homeActionRun.
  ///
  /// In ko, this message translates to:
  /// **'디버그 실행'**
  String get homeActionRun;

  /// No description provided for @homeActionCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get homeActionCancel;

  /// No description provided for @homeActionStop.
  ///
  /// In ko, this message translates to:
  /// **'중지'**
  String get homeActionStop;

  /// No description provided for @homeHotReload.
  ///
  /// In ko, this message translates to:
  /// **'핫 리로드'**
  String get homeHotReload;

  /// No description provided for @homeHotRestart.
  ///
  /// In ko, this message translates to:
  /// **'핫 리스타트'**
  String get homeHotRestart;

  /// No description provided for @homeOutputTitle.
  ///
  /// In ko, this message translates to:
  /// **'출력'**
  String get homeOutputTitle;

  /// No description provided for @homeCopyCommand.
  ///
  /// In ko, this message translates to:
  /// **'명령 복사'**
  String get homeCopyCommand;

  /// No description provided for @blockerNoProject.
  ///
  /// In ko, this message translates to:
  /// **'먼저 Flutter 프로젝트를 여세요'**
  String get blockerNoProject;

  /// No description provided for @blockerNoDevice.
  ///
  /// In ko, this message translates to:
  /// **'기기를 연결하고 선택하세요'**
  String get blockerNoDevice;

  /// No description provided for @blockerPlatformMissing.
  ///
  /// In ko, this message translates to:
  /// **'이 프로젝트에는 선택한 기기의 플랫폼 폴더(ios/ 또는 android/)가 없습니다'**
  String get blockerPlatformMissing;

  /// No description provided for @blockerIosNeedsMac.
  ///
  /// In ko, this message translates to:
  /// **'iPhone에 설치하려면 macOS와 Xcode가 필요합니다'**
  String get blockerIosNeedsMac;

  /// No description provided for @blockerWireless.
  ///
  /// In ko, this message translates to:
  /// **'무선으로 잡힌 기기입니다. USB 케이블로 연결하세요 (무선에서는 설치가 끊깁니다)'**
  String get blockerWireless;

  /// No description provided for @blockerDeveloperModeOff.
  ///
  /// In ko, this message translates to:
  /// **'iPhone의 개발자 모드가 꺼져 있습니다. 설정 → 개인정보 보호 및 보안 → 개발자 모드를 켜고 재시동하세요'**
  String get blockerDeveloperModeOff;

  /// No description provided for @blockerAndroidUnauthorized.
  ///
  /// In ko, this message translates to:
  /// **'폰 화면의 \'USB 디버깅 허용\' 창에서 이 컴퓨터를 승인하세요'**
  String get blockerAndroidUnauthorized;

  /// No description provided for @blockerNeedsTeamId.
  ///
  /// In ko, this message translates to:
  /// **'iOS 서명에 쓸 Apple Team ID를 입력하세요'**
  String get blockerNeedsTeamId;

  /// No description provided for @hintUseUsb.
  ///
  /// In ko, this message translates to:
  /// **'연결이 끊겼습니다. 무선이 아니라 USB 케이블로 연결했는지 확인하세요'**
  String get hintUseUsb;

  /// No description provided for @hintUnlockDevice.
  ///
  /// In ko, this message translates to:
  /// **'iPhone이 잠겨 있습니다. 잠금을 풀고 다시 시도하세요'**
  String get hintUnlockDevice;

  /// No description provided for @hintDeveloperMode.
  ///
  /// In ko, this message translates to:
  /// **'iPhone의 개발자 모드를 켜세요: 설정 → 개인정보 보호 및 보안 → 개발자 모드'**
  String get hintDeveloperMode;

  /// No description provided for @hintSigning.
  ///
  /// In ko, this message translates to:
  /// **'서명 프로파일 문제입니다. Team ID가 맞는지, Xcode에 Apple 계정이 로그인되어 있는지 확인하세요'**
  String get hintSigning;

  /// No description provided for @hintTrustComputer.
  ///
  /// In ko, this message translates to:
  /// **'iPhone에서 \'이 컴퓨터를 신뢰\'를 누르세요'**
  String get hintTrustComputer;

  /// No description provided for @hintNoAdb.
  ///
  /// In ko, this message translates to:
  /// **'adb를 찾지 못했습니다. Android SDK platform-tools를 설치하고 PATH에 추가하세요'**
  String get hintNoAdb;

  /// No description provided for @hintMissingCommand.
  ///
  /// In ko, this message translates to:
  /// **'{command} 명령을 찾지 못했습니다. 설치하고 PATH에 있는지 확인하세요'**
  String hintMissingCommand(String command);

  /// No description provided for @tabInstall.
  ///
  /// In ko, this message translates to:
  /// **'설치'**
  String get tabInstall;

  /// No description provided for @tabDevices.
  ///
  /// In ko, this message translates to:
  /// **'기기'**
  String get tabDevices;

  /// No description provided for @tabSigning.
  ///
  /// In ko, this message translates to:
  /// **'서명'**
  String get tabSigning;

  /// No description provided for @tabDoctor.
  ///
  /// In ko, this message translates to:
  /// **'점검'**
  String get tabDoctor;

  /// No description provided for @tabLog.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get tabLog;

  /// No description provided for @bannerNextStep.
  ///
  /// In ko, this message translates to:
  /// **'지금 할 일'**
  String get bannerNextStep;

  /// No description provided for @bannerShowSteps.
  ///
  /// In ko, this message translates to:
  /// **'해결 방법 보기'**
  String get bannerShowSteps;

  /// No description provided for @doctorRun.
  ///
  /// In ko, this message translates to:
  /// **'다시 점검'**
  String get doctorRun;

  /// No description provided for @doctorRunning.
  ///
  /// In ko, this message translates to:
  /// **'점검 중…'**
  String get doctorRunning;

  /// No description provided for @doctorNever.
  ///
  /// In ko, this message translates to:
  /// **'아직 점검하지 않았습니다'**
  String get doctorNever;

  /// No description provided for @doctorCollected.
  ///
  /// In ko, this message translates to:
  /// **'{time}에 점검함'**
  String doctorCollected(String time);

  /// No description provided for @doctorAllGood.
  ///
  /// In ko, this message translates to:
  /// **'문제가 없습니다'**
  String get doctorAllGood;

  /// No description provided for @signingTeams.
  ///
  /// In ko, this message translates to:
  /// **'서명 Team'**
  String get signingTeams;

  /// No description provided for @signingTeamsHelp.
  ///
  /// In ko, this message translates to:
  /// **'키체인에 개인 키가 있는 인증서의 Team입니다. 누르면 이 Team으로 서명합니다'**
  String get signingTeamsHelp;

  /// No description provided for @signingNoTeams.
  ///
  /// In ko, this message translates to:
  /// **'사용할 수 있는 개발 인증서가 없습니다'**
  String get signingNoTeams;

  /// No description provided for @signingCerts.
  ///
  /// In ko, this message translates to:
  /// **'개발 인증서'**
  String get signingCerts;

  /// No description provided for @signingProfiles.
  ///
  /// In ko, this message translates to:
  /// **'이 프로젝트의 프로파일'**
  String get signingProfiles;

  /// No description provided for @signingNoProfiles.
  ///
  /// In ko, this message translates to:
  /// **'아직 없습니다 — 첫 빌드에서 Xcode가 자동으로 만듭니다'**
  String get signingNoProfiles;

  /// No description provided for @signingShortLived.
  ///
  /// In ko, this message translates to:
  /// **'7일 프로파일'**
  String get signingShortLived;

  /// No description provided for @signingNoKey.
  ///
  /// In ko, this message translates to:
  /// **'개인 키 없음'**
  String get signingNoKey;

  /// No description provided for @signingDaysLeft.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 남음'**
  String signingDaysLeft(String days);

  /// No description provided for @signingExpired.
  ///
  /// In ko, this message translates to:
  /// **'만료됨'**
  String get signingExpired;

  /// No description provided for @signingAndroid.
  ///
  /// In ko, this message translates to:
  /// **'Android 릴리스 서명'**
  String get signingAndroid;

  /// No description provided for @signingMacOnly.
  ///
  /// In ko, this message translates to:
  /// **'iOS 서명 점검은 macOS에서만 합니다'**
  String get signingMacOnly;

  /// No description provided for @logClear.
  ///
  /// In ko, this message translates to:
  /// **'기록 지우기'**
  String get logClear;

  /// No description provided for @logEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 실행한 명령이 없습니다'**
  String get logEmpty;

  /// No description provided for @logRunning.
  ///
  /// In ko, this message translates to:
  /// **'실행 중'**
  String get logRunning;

  /// No description provided for @logExit.
  ///
  /// In ko, this message translates to:
  /// **'종료 코드 {code}'**
  String logExit(String code);

  /// No description provided for @checkFlutterOk.
  ///
  /// In ko, this message translates to:
  /// **'Flutter {version}'**
  String checkFlutterOk(String version);

  /// No description provided for @checkFlutterFail.
  ///
  /// In ko, this message translates to:
  /// **'flutter를 찾지 못했습니다'**
  String get checkFlutterFail;

  /// No description provided for @checkXcodeOk.
  ///
  /// In ko, this message translates to:
  /// **'Xcode {version}'**
  String checkXcodeOk(String version);

  /// No description provided for @checkXcodeFail.
  ///
  /// In ko, this message translates to:
  /// **'Xcode를 찾지 못했습니다'**
  String get checkXcodeFail;

  /// No description provided for @checkAdbOk.
  ///
  /// In ko, this message translates to:
  /// **'adb {version}'**
  String checkAdbOk(String version);

  /// No description provided for @checkAdbWarn.
  ///
  /// In ko, this message translates to:
  /// **'adb를 찾지 못했습니다 (Android 설치에 필요)'**
  String get checkAdbWarn;

  /// No description provided for @checkConnectionOk.
  ///
  /// In ko, this message translates to:
  /// **'{name}: USB로 연결됨'**
  String checkConnectionOk(String name);

  /// No description provided for @checkConnectionFail.
  ///
  /// In ko, this message translates to:
  /// **'{name}: USB가 아니라 무선으로 연결됨'**
  String checkConnectionFail(String name);

  /// No description provided for @checkDeveloperModeOk.
  ///
  /// In ko, this message translates to:
  /// **'iPhone 개발자 모드 켜짐'**
  String get checkDeveloperModeOk;

  /// No description provided for @checkDeveloperModeFail.
  ///
  /// In ko, this message translates to:
  /// **'iPhone 개발자 모드가 꺼져 있음'**
  String get checkDeveloperModeFail;

  /// No description provided for @checkAndroidAuthOk.
  ///
  /// In ko, this message translates to:
  /// **'USB 디버깅 승인됨'**
  String get checkAndroidAuthOk;

  /// No description provided for @checkAndroidAuthFail.
  ///
  /// In ko, this message translates to:
  /// **'USB 디버깅을 승인하지 않음'**
  String get checkAndroidAuthFail;

  /// No description provided for @checkCertificateOk.
  ///
  /// In ko, this message translates to:
  /// **'개발 인증서 {count}개 (개인 키 있음)'**
  String checkCertificateOk(String count);

  /// No description provided for @checkCertificateFail.
  ///
  /// In ko, this message translates to:
  /// **'사용할 수 있는 Apple Development 인증서가 없음'**
  String get checkCertificateFail;

  /// No description provided for @checkCertExpiryOk.
  ///
  /// In ko, this message translates to:
  /// **'{name} · {days}일 남음'**
  String checkCertExpiryOk(String name, String days);

  /// No description provided for @checkCertExpiryWarn.
  ///
  /// In ko, this message translates to:
  /// **'{name} · {days}일 뒤 만료'**
  String checkCertExpiryWarn(String name, String days);

  /// No description provided for @checkCertExpiryFail.
  ///
  /// In ko, this message translates to:
  /// **'{name} · 만료됨'**
  String checkCertExpiryFail(String name);

  /// No description provided for @checkTeamOk.
  ///
  /// In ko, this message translates to:
  /// **'서명 Team {team}'**
  String checkTeamOk(String team);

  /// No description provided for @checkTeamFail.
  ///
  /// In ko, this message translates to:
  /// **'서명할 Team ID가 정해지지 않음'**
  String get checkTeamFail;

  /// No description provided for @checkTeamWarn.
  ///
  /// In ko, this message translates to:
  /// **'Team {team}의 인증서가 이 Mac에 없음'**
  String checkTeamWarn(String team);

  /// No description provided for @checkProfileOk.
  ///
  /// In ko, this message translates to:
  /// **'{bundle} 프로파일 · {days}일 남음'**
  String checkProfileOk(String bundle, String days);

  /// No description provided for @checkProfileWarn.
  ///
  /// In ko, this message translates to:
  /// **'{bundle} 프로파일이 곧 만료됨 ({days}일 남음)'**
  String checkProfileWarn(String bundle, String days);

  /// No description provided for @checkProfileFail.
  ///
  /// In ko, this message translates to:
  /// **'{bundle} 프로파일이 만료됨'**
  String checkProfileFail(String bundle);

  /// No description provided for @checkProfileInfo.
  ///
  /// In ko, this message translates to:
  /// **'{bundle} 프로파일 없음 — 첫 빌드에서 자동으로 만들어짐'**
  String checkProfileInfo(String bundle);

  /// No description provided for @checkProfileShort.
  ///
  /// In ko, this message translates to:
  /// **'무료 계정의 7일 프로파일입니다. 만료되면 다시 빌드해서 설치하세요'**
  String get checkProfileShort;

  /// No description provided for @checkAndroidSigningDebugKey.
  ///
  /// In ko, this message translates to:
  /// **'키스토어 설정 없음 — debug 키로 서명 (개인 기기 설치용으로 충분)'**
  String get checkAndroidSigningDebugKey;

  /// No description provided for @checkAndroidSigningKeystore.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 키스토어로 서명'**
  String get checkAndroidSigningKeystore;

  /// No description provided for @checkAndroidSigningMissing.
  ///
  /// In ko, this message translates to:
  /// **'key.properties가 가리키는 키스토어 파일이 없음'**
  String get checkAndroidSigningMissing;

  /// No description provided for @stepsWireless.
  ///
  /// In ko, this message translates to:
  /// **'1. iPhone을 USB 케이블로 Mac에 연결합니다\n2. 잠금을 풀고 \'이 컴퓨터를 신뢰\'를 누릅니다\n3. 기기 새로 고침을 누르고 USB 표시가 뜨는지 확인합니다'**
  String get stepsWireless;

  /// No description provided for @stepsDeveloperMode.
  ///
  /// In ko, this message translates to:
  /// **'1. iPhone: 설정 → 개인정보 보호 및 보안 → 개발자 모드\n2. 켜고 재시동합니다\n3. 재시동 후 나오는 확인 창에서 \'켜기\'를 누릅니다'**
  String get stepsDeveloperMode;

  /// No description provided for @stepsAndroidAuth.
  ///
  /// In ko, this message translates to:
  /// **'1. 폰을 USB로 연결하고 잠금을 풉니다\n2. \'USB 디버깅 허용\' 창에서 이 컴퓨터를 허용합니다\n3. 창이 안 뜨면 개발자 옵션에서 USB 디버깅을 켭니다'**
  String get stepsAndroidAuth;

  /// No description provided for @stepsTeamId.
  ///
  /// In ko, this message translates to:
  /// **'1. developer.apple.com/account → Membership details에서 Team ID(10자)를 확인합니다\n2. 빌드 영역의 Apple Team ID에 입력합니다\n3. 서명 탭에서 인증서의 Team을 눌러 고를 수도 있습니다'**
  String get stepsTeamId;

  /// No description provided for @stepsCertificate.
  ///
  /// In ko, this message translates to:
  /// **'1. Xcode → Settings → Accounts에서 Apple ID로 로그인합니다\n2. Manage Certificates → + → Apple Development을 추가합니다\n3. 다시 점검을 누릅니다'**
  String get stepsCertificate;

  /// No description provided for @stepsFlutterMissing.
  ///
  /// In ko, this message translates to:
  /// **'1. flutter.dev에서 Flutter SDK를 설치합니다\n2. flutter/bin을 PATH에 추가합니다 (~/.zshrc)\n3. 앱을 다시 열고 점검을 누릅니다'**
  String get stepsFlutterMissing;

  /// No description provided for @stepsXcodeMissing.
  ///
  /// In ko, this message translates to:
  /// **'1. App Store에서 Xcode를 설치합니다\n2. 터미널에서 sudo xcode-select -s /Applications/Xcode.app 를 실행합니다\n3. Xcode를 한 번 열어 라이선스에 동의합니다'**
  String get stepsXcodeMissing;

  /// No description provided for @stepsAdbMissing.
  ///
  /// In ko, this message translates to:
  /// **'1. Android SDK platform-tools를 설치합니다 (Android Studio SDK Manager)\n2. platform-tools 폴더를 PATH에 추가합니다\n3. 다시 점검을 누릅니다'**
  String get stepsAdbMissing;

  /// No description provided for @stepsAndroidKeystore.
  ///
  /// In ko, this message translates to:
  /// **'1. android/key.properties의 storeFile 경로를 확인합니다\n2. 파일이 없으면 키스토어를 다시 만들거나 경로를 고칩니다\n3. 개인 설치만 한다면 key.properties를 쓰지 않아도 debug 키로 서명됩니다'**
  String get stepsAndroidKeystore;

  /// No description provided for @stepsCertExpiry.
  ///
  /// In ko, this message translates to:
  /// **'1. Xcode → Settings → Accounts → Manage Certificates에서 새 Apple Development 인증서를 만듭니다\n2. 다시 점검을 누릅니다'**
  String get stepsCertExpiry;

  /// No description provided for @homeOpenVsCode.
  ///
  /// In ko, this message translates to:
  /// **'VS Code로 열기'**
  String get homeOpenVsCode;

  /// No description provided for @vscodeNotFound.
  ///
  /// In ko, this message translates to:
  /// **'VS Code를 찾지 못했습니다'**
  String get vscodeNotFound;

  /// No description provided for @vscodeDownload.
  ///
  /// In ko, this message translates to:
  /// **'받기'**
  String get vscodeDownload;

  /// No description provided for @vscodeOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'VS Code를 열지 못했습니다'**
  String get vscodeOpenFailed;

  /// No description provided for @secretFileTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일에서 한 번에 등록'**
  String get secretFileTitle;

  /// No description provided for @secretFileHelp.
  ///
  /// In ko, this message translates to:
  /// **'NAME=값 형식(.env) 파일의 모든 항목을 gh secret set -f로 등록합니다. 이 앱은 값을 읽어 두지 않고 이름만 보여 줍니다. 파일은 gh가 직접 읽습니다.'**
  String get secretFileHelp;

  /// No description provided for @secretFileEmpty.
  ///
  /// In ko, this message translates to:
  /// **'NAME=값 형식의 항목이 없습니다'**
  String get secretFileEmpty;

  /// No description provided for @secretFileUnknown.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 시크릿이 아닌 항목도 함께 등록됩니다: {names}'**
  String secretFileUnknown(String names);

  /// No description provided for @secretFileMissing.
  ///
  /// In ko, this message translates to:
  /// **'파일에 없는 릴리스 시크릿: {names}'**
  String secretFileMissing(String names);

  /// No description provided for @secretFileRegister.
  ///
  /// In ko, this message translates to:
  /// **'파일로 등록'**
  String get secretFileRegister;

  /// No description provided for @secretFileConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 시크릿을 등록할까요?'**
  String secretFileConfirmTitle(int count);

  /// No description provided for @secretFileSaved.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 시크릿을 등록했습니다'**
  String secretFileSaved(int count);

  /// No description provided for @secretFileFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일로 등록하지 못했습니다'**
  String get secretFileFailed;

  /// No description provided for @toolPathsOpen.
  ///
  /// In ko, this message translates to:
  /// **'도구 경로 지정…'**
  String get toolPathsOpen;

  /// No description provided for @toolPathsTitle.
  ///
  /// In ko, this message translates to:
  /// **'도구 경로'**
  String get toolPathsTitle;

  /// No description provided for @toolPathsHelp.
  ///
  /// In ko, this message translates to:
  /// **'PATH에서 찾지 못하는 도구는 직접 지정할 수 있습니다. 한 번 지정하면 저장되고 다음 실행에도 쓰입니다. 폴더가 아니라 실행 파일을 고르세요.'**
  String get toolPathsHelp;

  /// No description provided for @toolPathNotFound.
  ///
  /// In ko, this message translates to:
  /// **'찾지 못함'**
  String get toolPathNotFound;

  /// No description provided for @toolPathChoose.
  ///
  /// In ko, this message translates to:
  /// **'찾아서 지정…'**
  String get toolPathChoose;

  /// No description provided for @toolPathAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동으로'**
  String get toolPathAuto;

  /// No description provided for @toolPathCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 지정'**
  String get toolPathCustom;

  /// No description provided for @toolPathFlutter.
  ///
  /// In ko, this message translates to:
  /// **'flutter'**
  String get toolPathFlutter;

  /// No description provided for @toolPathAdb.
  ///
  /// In ko, this message translates to:
  /// **'adb (Android SDK platform-tools)'**
  String get toolPathAdb;

  /// No description provided for @homeDevicesCauses.
  ///
  /// In ko, this message translates to:
  /// **'기기가 안 보이는 이유일 수 있는 것'**
  String get homeDevicesCauses;

  /// No description provided for @stepsNoDevice.
  ///
  /// In ko, this message translates to:
  /// **'1. USB 케이블로 폰을 연결합니다 (충전 전용 케이블은 안 됩니다)\n2. 잠금을 풀고, iPhone은 \'이 컴퓨터를 신뢰\', Android는 \'USB 디버깅 허용\'을 누릅니다\n3. 위의 새로 고침을 누릅니다'**
  String get stepsNoDevice;
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
