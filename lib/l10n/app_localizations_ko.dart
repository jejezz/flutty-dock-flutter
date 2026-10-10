// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get aboutTooltip => '정보';

  @override
  String aboutVersion(String version, String build) {
    return '버전 $version (빌드 $build)';
  }

  @override
  String get aboutOpenSourceLicenses => '오픈소스 라이선스';

  @override
  String get aboutRepository => 'GitHub';

  @override
  String get commonClose => '닫기';

  @override
  String aboutMenuItem(String appName) {
    return '$appName 정보';
  }

  @override
  String get themeMenuTooltip => '테마';

  @override
  String get themeSystem => '시스템 설정 따르기';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get languageMenuTooltip => '언어';

  @override
  String get languageSystem => '시스템 설정 따르기 / System';

  @override
  String get languageSystemShort => '시스템';

  @override
  String get aboutTagline => 'Flutter 앱을 USB 실기기에 올리는 도킹형 도우미';

  @override
  String get aboutDescription =>
      '편집기 옆에 세워 두고 Flutter 프로젝트를 iPhone·Android 실기기에 debug/release로 빌드·설치합니다. 버튼마다 실제 실행되는 명령을 보여 주고, 서명 문제는 원인과 해결 단계로 안내합니다.';

  @override
  String get homeEmptyTitle => 'Flutter 프로젝트 폴더를 끌어다 놓으세요';

  @override
  String get homeEmptyAction => '프로젝트 열기';

  @override
  String get updateCheckMenuItem => '업데이트 확인';

  @override
  String get updateChecking => '업데이트를 확인하는 중…';

  @override
  String get updateAvailableTitle => '새 버전이 있습니다';

  @override
  String updateAvailableBody(String appName, String current, String latest) {
    return '$appName $latest 버전이 나왔습니다. (현재 $current)';
  }

  @override
  String get updateReleaseNotes => '변경 내용';

  @override
  String get updateNow => '지금 업데이트';

  @override
  String get updateLater => '나중에';

  @override
  String get updateSkipVersion => '이 버전 건너뛰기';

  @override
  String get updateDownloading => '내려받는 중…';

  @override
  String get updateVerifying => '파일을 확인하는 중…';

  @override
  String updateDownloadProgress(String received, String total) {
    return '$received / $total';
  }

  @override
  String get updateCancel => '취소';

  @override
  String get updateFailedTitle => '업데이트하지 못했습니다';

  @override
  String get updateCheckFailedTitle => '업데이트를 확인하지 못했습니다';

  @override
  String get updateErrorNetwork =>
      '업데이트 서버에 연결하지 못했습니다. 인터넷 연결을 확인한 뒤 다시 시도해 주세요.';

  @override
  String get updateErrorChecksum =>
      '내려받은 파일이 올바르지 않아 설치하지 않았습니다. 잠시 뒤에 다시 시도해 주세요.';

  @override
  String get updateErrorInstall => '설치를 시작하지 못했습니다.';

  @override
  String get updateErrorGeneric =>
      '업데이트 서버에서 예상하지 못한 응답을 받았습니다. 잠시 뒤에 다시 시도해 주세요.';

  @override
  String get updateUpToDateTitle => '최신 버전입니다';

  @override
  String updateUpToDateBody(String version) {
    return '$version 버전을 사용 중입니다.';
  }

  @override
  String get updateUnavailableTitle => '직접 설치해 주세요';

  @override
  String updateUnavailableBody(String latest) {
    return '$latest 버전이 있지만 앱에서 자동으로 설치할 수 없습니다. 릴리스 페이지에서 받아 주세요.';
  }

  @override
  String get updateOpenReleasePage => '릴리스 페이지 열기';

  @override
  String get updateMacosOpenedTitle => '설치 창이 열렸습니다';

  @override
  String updateMacosOpenedBody(String appName) {
    return '열린 창에서 $appName 을(를) Applications 폴더로 끌어다 놓아 주세요. 실행 중이면 종료한 뒤 덮어쓰세요.';
  }

  @override
  String get updateWindowsInstallTitle => '설치 프로그램을 열었습니다';

  @override
  String updateWindowsInstallBody(String appName) {
    return '설치하려면 $appName 을(를) 종료해야 합니다. 설치 프로그램의 안내를 따라 주세요.';
  }

  @override
  String updateQuitApp(String appName) {
    return '$appName 종료';
  }

  @override
  String get updateLinuxInstallTitle => '설치를 준비했습니다';

  @override
  String updateLinuxInstallBody(String appName) {
    return '$appName 을(를) 종료하고 설치합니다. 설치가 끝나면 자동으로 다시 시작됩니다.';
  }

  @override
  String get updateQuitAndInstall => '종료하고 설치';

  @override
  String get updateBusyTitle => '지금은 업데이트할 수 없습니다';

  @override
  String get updateBusyBody => '작업이 진행 중입니다. 끝난 뒤에 다시 시도해 주세요.';

  @override
  String get secretsTooltip => '릴리스 시크릿';

  @override
  String get secretsTitle => '릴리스 시크릿 등록';

  @override
  String get secretsIntro =>
      'macOS 릴리스 워크플로가 서명·공증에 쓰는 GitHub Actions 시크릿을 gh로 등록합니다. 값은 이 앱에 저장되지 않습니다.';

  @override
  String get secretsRepoLabel => '저장소 (owner/repo)';

  @override
  String get secretsPickFolder => '프로젝트 폴더에서 읽기';

  @override
  String get secretsRefresh => '등록 상태 새로 고침';

  @override
  String get secretsRepoInvalid => 'owner/repo 형식으로 입력하세요';

  @override
  String get secretsFolderNoRemote => '이 폴더에서 GitHub 원격(origin)을 찾지 못했습니다';

  @override
  String get secretsGhMissing => 'GitHub CLI(gh)가 없습니다. 터미널에서 이 명령으로 설치하세요:';

  @override
  String get secretsGhNotLoggedIn => 'gh에 로그인하지 않았습니다. 터미널에서 이 명령을 실행하세요:';

  @override
  String get secretsListFailed => '등록 상태를 읽지 못했습니다. 저장소 이름과 권한을 확인하세요';

  @override
  String secretStatusRegistered(String date) {
    return '등록됨 · $date';
  }

  @override
  String get secretStatusMissing => '미등록';

  @override
  String get secretStatusUnknown => '확인 안 됨';

  @override
  String get secretSet => '등록';

  @override
  String get secretOverwrite => '덮어쓰기';

  @override
  String get secretPickFile => '파일 선택…';

  @override
  String get secretNoFile => '선택한 파일 없음';

  @override
  String secretFileLoaded(String name, int bytes) {
    return '$name · $bytes바이트';
  }

  @override
  String get secretGenerate => '무작위 생성';

  @override
  String get secretGenerated => '무작위 값을 만들었습니다 (화면에 표시하지 않음)';

  @override
  String get secretViaStdin => '값은 명령 인자가 아니라 표준 입력으로 전달되어 명령 기록에 남지 않습니다.';

  @override
  String get secretIssueEmpty => '값을 입력하세요';

  @override
  String get secretIssueEmail => '이메일 형식이 아닙니다';

  @override
  String get secretIssueTeamId => 'Team ID는 영문 대문자·숫자 10자입니다';

  @override
  String secretSaved(String name) {
    return '$name 등록했습니다';
  }

  @override
  String secretFailed(String name) {
    return '$name 등록에 실패했습니다';
  }

  @override
  String secretOverwriteTitle(String name) {
    return '$name을(를) 덮어쓸까요?';
  }

  @override
  String get secretOverwriteBody => '이미 등록된 값을 새 값으로 바꿉니다. 되돌릴 수 없습니다.';

  @override
  String get secretHelpP12 =>
      '키체인 접근에서 \'Developer ID Application\' 인증서를 .p12로 내보낸 파일을 고르세요. 앱이 base64로 바꿔 등록합니다.';

  @override
  String get secretHelpP12Password => '.p12를 내보낼 때 지정한 암호입니다.';

  @override
  String get secretHelpKeychain =>
      'CI가 빌드 중에만 쓰는 임시 키체인 암호입니다. 아무 값이나 괜찮아서 무작위로 만들어 드립니다.';

  @override
  String get secretHelpAppleId => '공증(notarization)에 쓰는 Apple ID 이메일입니다.';

  @override
  String get secretHelpApplePassword =>
      '앱 암호(app-specific password)입니다. 계정 비밀번호가 아닙니다.';

  @override
  String get secretHelpTeamId =>
      'developer.apple.com/account의 Membership details에 있는 10자리 Team ID입니다.';

  @override
  String get secretOpenAppleId => 'appleid.apple.com 열기';

  @override
  String get secretOpenDeveloper => 'developer.apple.com/account 열기';

  @override
  String get commandBarEmpty => '아직 실행한 명령이 없습니다';

  @override
  String get commonCancel => '취소';

  @override
  String get homeProjectTitle => '프로젝트';

  @override
  String get homeProjectOpen => '프로젝트 열기';

  @override
  String get homeProjectChange => '변경';

  @override
  String get homeProjectDrop => 'Flutter 프로젝트 폴더를 여기로 끌어다 놓거나 [프로젝트 열기]를 누르세요';

  @override
  String homeProjectNotFlutter(String path) {
    return 'Flutter 프로젝트가 아닙니다: $path';
  }

  @override
  String get homePlatformIos => 'iOS';

  @override
  String get homePlatformAndroid => 'Android';

  @override
  String get homeDevicesTitle => '기기';

  @override
  String get homeDevicesRefresh => '기기 새로 고침';

  @override
  String get homeDevicesNone =>
      'USB로 연결된 기기가 없습니다. 폰을 USB로 연결하고 잠금을 푼 뒤 새로 고치세요';

  @override
  String get homeLinkUsb => 'USB';

  @override
  String get homeLinkWireless => '무선';

  @override
  String get homeBuildTitle => '빌드';

  @override
  String get homeModeDebug => 'Debug';

  @override
  String get homeModeRelease => 'Release';

  @override
  String get homeTeamLabel => 'Apple Team ID';

  @override
  String get homeTeamHelp =>
      '프로젝트를 고치지 않고 빌드 인자로만 넘깁니다. developer.apple.com/account → Membership에서 확인하세요';

  @override
  String get homeStepsTitle => '실행할 명령';

  @override
  String get homeStepPrepare => '준비';

  @override
  String get homeStepBuild => '빌드';

  @override
  String get homeStepInstall => '설치';

  @override
  String get homeStepLaunch => '실행';

  @override
  String get homeStepRun => '실행 (핫 리로드)';

  @override
  String get homeActionInstall => '빌드 & 설치';

  @override
  String get homeActionRun => '디버그 실행';

  @override
  String get homeActionCancel => '취소';

  @override
  String get homeActionStop => '중지';

  @override
  String get homeHotReload => '핫 리로드';

  @override
  String get homeHotRestart => '핫 리스타트';

  @override
  String get homeOutputTitle => '출력';

  @override
  String get homeCopyCommand => '명령 복사';

  @override
  String get blockerNoProject => '먼저 Flutter 프로젝트를 여세요';

  @override
  String get blockerNoDevice => '기기를 연결하고 선택하세요';

  @override
  String get blockerPlatformMissing =>
      '이 프로젝트에는 선택한 기기의 플랫폼 폴더(ios/ 또는 android/)가 없습니다';

  @override
  String get blockerIosNeedsMac => 'iPhone에 설치하려면 macOS와 Xcode가 필요합니다';

  @override
  String get blockerWireless =>
      '무선으로 잡힌 기기입니다. USB 케이블로 연결하세요 (무선에서는 설치가 끊깁니다)';

  @override
  String get blockerDeveloperModeOff =>
      'iPhone의 개발자 모드가 꺼져 있습니다. 설정 → 개인정보 보호 및 보안 → 개발자 모드를 켜고 재시동하세요';

  @override
  String get blockerAndroidUnauthorized =>
      '폰 화면의 \'USB 디버깅 허용\' 창에서 이 컴퓨터를 승인하세요';

  @override
  String get blockerNeedsTeamId => 'iOS 서명에 쓸 Apple Team ID를 입력하세요';

  @override
  String get hintUseUsb => '연결이 끊겼습니다. 무선이 아니라 USB 케이블로 연결했는지 확인하세요';

  @override
  String get hintUnlockDevice => 'iPhone이 잠겨 있습니다. 잠금을 풀고 다시 시도하세요';

  @override
  String get hintDeveloperMode =>
      'iPhone의 개발자 모드를 켜세요: 설정 → 개인정보 보호 및 보안 → 개발자 모드';

  @override
  String get hintSigning =>
      '서명 프로파일 문제입니다. Team ID가 맞는지, Xcode에 Apple 계정이 로그인되어 있는지 확인하세요';

  @override
  String get hintTrustComputer => 'iPhone에서 \'이 컴퓨터를 신뢰\'를 누르세요';

  @override
  String get hintNoAdb =>
      'adb를 찾지 못했습니다. Android SDK platform-tools를 설치하고 PATH에 추가하세요';

  @override
  String hintMissingCommand(String command) {
    return '$command 명령을 찾지 못했습니다. 설치하고 PATH에 있는지 확인하세요';
  }

  @override
  String get tabInstall => '설치';

  @override
  String get tabDevices => '기기';

  @override
  String get tabSigning => '서명';

  @override
  String get tabDoctor => '점검';

  @override
  String get tabLog => '기록';

  @override
  String get bannerNextStep => '지금 할 일';

  @override
  String get bannerShowSteps => '해결 방법 보기';

  @override
  String get doctorRun => '다시 점검';

  @override
  String get doctorRunning => '점검 중…';

  @override
  String get doctorNever => '아직 점검하지 않았습니다';

  @override
  String doctorCollected(String time) {
    return '$time에 점검함';
  }

  @override
  String get doctorAllGood => '문제가 없습니다';

  @override
  String get signingTeams => '서명 Team';

  @override
  String get signingTeamsHelp =>
      '키체인에 개인 키가 있는 인증서의 Team입니다. 누르면 이 Team으로 서명합니다';

  @override
  String get signingNoTeams => '사용할 수 있는 개발 인증서가 없습니다';

  @override
  String get signingCerts => '개발 인증서';

  @override
  String get signingProfiles => '이 프로젝트의 프로파일';

  @override
  String get signingNoProfiles => '아직 없습니다 — 첫 빌드에서 Xcode가 자동으로 만듭니다';

  @override
  String get signingShortLived => '7일 프로파일';

  @override
  String get signingNoKey => '개인 키 없음';

  @override
  String signingDaysLeft(String days) {
    return '$days일 남음';
  }

  @override
  String get signingExpired => '만료됨';

  @override
  String get signingAndroid => 'Android 릴리스 서명';

  @override
  String get signingMacOnly => 'iOS 서명 점검은 macOS에서만 합니다';

  @override
  String get logClear => '기록 지우기';

  @override
  String get logEmpty => '아직 실행한 명령이 없습니다';

  @override
  String get logRunning => '실행 중';

  @override
  String logExit(String code) {
    return '종료 코드 $code';
  }

  @override
  String checkFlutterOk(String version) {
    return 'Flutter $version';
  }

  @override
  String get checkFlutterFail => 'flutter를 찾지 못했습니다';

  @override
  String checkXcodeOk(String version) {
    return 'Xcode $version';
  }

  @override
  String get checkXcodeFail => 'Xcode를 찾지 못했습니다';

  @override
  String checkAdbOk(String version) {
    return 'adb $version';
  }

  @override
  String get checkAdbWarn => 'adb를 찾지 못했습니다 (Android 설치에 필요)';

  @override
  String checkConnectionOk(String name) {
    return '$name: USB로 연결됨';
  }

  @override
  String checkConnectionFail(String name) {
    return '$name: USB가 아니라 무선으로 연결됨';
  }

  @override
  String get checkDeveloperModeOk => 'iPhone 개발자 모드 켜짐';

  @override
  String get checkDeveloperModeFail => 'iPhone 개발자 모드가 꺼져 있음';

  @override
  String get checkAndroidAuthOk => 'USB 디버깅 승인됨';

  @override
  String get checkAndroidAuthFail => 'USB 디버깅을 승인하지 않음';

  @override
  String checkCertificateOk(String count) {
    return '개발 인증서 $count개 (개인 키 있음)';
  }

  @override
  String get checkCertificateFail => '사용할 수 있는 Apple Development 인증서가 없음';

  @override
  String checkCertExpiryOk(String name, String days) {
    return '$name · $days일 남음';
  }

  @override
  String checkCertExpiryWarn(String name, String days) {
    return '$name · $days일 뒤 만료';
  }

  @override
  String checkCertExpiryFail(String name) {
    return '$name · 만료됨';
  }

  @override
  String checkTeamOk(String team) {
    return '서명 Team $team';
  }

  @override
  String get checkTeamFail => '서명할 Team ID가 정해지지 않음';

  @override
  String checkTeamWarn(String team) {
    return 'Team $team의 인증서가 이 Mac에 없음';
  }

  @override
  String checkProfileOk(String bundle, String days) {
    return '$bundle 프로파일 · $days일 남음';
  }

  @override
  String checkProfileWarn(String bundle, String days) {
    return '$bundle 프로파일이 곧 만료됨 ($days일 남음)';
  }

  @override
  String checkProfileFail(String bundle) {
    return '$bundle 프로파일이 만료됨';
  }

  @override
  String checkProfileInfo(String bundle) {
    return '$bundle 프로파일 없음 — 첫 빌드에서 자동으로 만들어짐';
  }

  @override
  String get checkProfileShort => '무료 계정의 7일 프로파일입니다. 만료되면 다시 빌드해서 설치하세요';

  @override
  String get checkAndroidSigningDebugKey =>
      '키스토어 설정 없음 — debug 키로 서명 (개인 기기 설치용으로 충분)';

  @override
  String get checkAndroidSigningKeystore => '릴리스 키스토어로 서명';

  @override
  String get checkAndroidSigningMissing => 'key.properties가 가리키는 키스토어 파일이 없음';

  @override
  String get stepsWireless =>
      '1. iPhone을 USB 케이블로 Mac에 연결합니다\n2. 잠금을 풀고 \'이 컴퓨터를 신뢰\'를 누릅니다\n3. 기기 새로 고침을 누르고 USB 표시가 뜨는지 확인합니다';

  @override
  String get stepsDeveloperMode =>
      '1. iPhone: 설정 → 개인정보 보호 및 보안 → 개발자 모드\n2. 켜고 재시동합니다\n3. 재시동 후 나오는 확인 창에서 \'켜기\'를 누릅니다';

  @override
  String get stepsAndroidAuth =>
      '1. 폰을 USB로 연결하고 잠금을 풉니다\n2. \'USB 디버깅 허용\' 창에서 이 컴퓨터를 허용합니다\n3. 창이 안 뜨면 개발자 옵션에서 USB 디버깅을 켭니다';

  @override
  String get stepsTeamId =>
      '1. developer.apple.com/account → Membership details에서 Team ID(10자)를 확인합니다\n2. 빌드 영역의 Apple Team ID에 입력합니다\n3. 서명 탭에서 인증서의 Team을 눌러 고를 수도 있습니다';

  @override
  String get stepsCertificate =>
      '1. Xcode → Settings → Accounts에서 Apple ID로 로그인합니다\n2. Manage Certificates → + → Apple Development을 추가합니다\n3. 다시 점검을 누릅니다';

  @override
  String get stepsFlutterMissing =>
      '1. flutter.dev에서 Flutter SDK를 설치합니다\n2. flutter/bin을 PATH에 추가합니다 (~/.zshrc)\n3. 앱을 다시 열고 점검을 누릅니다';

  @override
  String get stepsXcodeMissing =>
      '1. App Store에서 Xcode를 설치합니다\n2. 터미널에서 sudo xcode-select -s /Applications/Xcode.app 를 실행합니다\n3. Xcode를 한 번 열어 라이선스에 동의합니다';

  @override
  String get stepsAdbMissing =>
      '1. Android SDK platform-tools를 설치합니다 (Android Studio SDK Manager)\n2. platform-tools 폴더를 PATH에 추가합니다\n3. 다시 점검을 누릅니다';

  @override
  String get stepsAndroidKeystore =>
      '1. android/key.properties의 storeFile 경로를 확인합니다\n2. 파일이 없으면 키스토어를 다시 만들거나 경로를 고칩니다\n3. 개인 설치만 한다면 key.properties를 쓰지 않아도 debug 키로 서명됩니다';

  @override
  String get stepsCertExpiry =>
      '1. Xcode → Settings → Accounts → Manage Certificates에서 새 Apple Development 인증서를 만듭니다\n2. 다시 점검을 누릅니다';
}
