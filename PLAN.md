# Flutter 모바일 실기기 배포 도구 — 계획서 (v2: 도킹 GUI 우선)

> v1(CLI 우선)에서 변경: 사용 방식이 "VS Code 옆에 세워 두고 빌드·설치는 이 앱으로"로 정해졌다.
> 따라서 **Branch Dock과 같은 도킹형 데스크톱 앱이 본체**이고, 빌드·설치 로직은 UI와 분리된
> 순수 Dart 계층으로 두어 나중에 CLI로도 쓸 수 있게 한다.

## 1. 목표

임의의 Flutter 프로젝트를 디버그/릴리즈로 빌드해 **USB로 연결된 iPhone·Android 실기기에 직접 설치**한다.
편집은 VS Code, 빌드·설치·서명 점검은 이 앱. 버튼마다 **실제 실행되는 명령을 보여 주고**,
지금 **무엇을 해야 하는지 단계별로** 안내해서 쓰면서 명령을 익히게 한다.

- 포함: iOS/Android 모바일, USB 실기기 설치, debug/release, signing 점검, 단계별 안내
- 제외(1차): 스토어 제출(TestFlight/Play), 웹 타깃, 무선 디버깅, Linux 호스트(iOS는 macOS 필수)
- 추가(v0.1.0 이후): 프로젝트가 이미 `macos/`·`windows/`를 지원하면 이 컴퓨터의 데스크톱 빌드(debug 실행·release 빌드 후 열기)
- 성공 기준: 처음 보는 Flutter 프로젝트를 고르면 프로젝트 수정 없이 몇 분 안에 release가 폰에 설치되고,
  실패하면 로그 대신 **원인과 조치 한 줄**이 나온다.

## 2. Phase 0 검증 결과 (완료, 이 Mac 기준)

환경: Flutter 3.47.1, Xcode 27.0, Team `6N35L95QS4`(유료), iPhone 12 mini, Galaxy S25+.

| | iOS | Android |
|---|---|---|
| 빌드 | `flutter build ios --release --config-only --no-codesign` → `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination generic/platform=iOS -derivedDataPath build/ios_dd -allowProvisioningUpdates DEVELOPMENT_TEAM=<id> CODE_SIGN_STYLE=Automatic build` | `flutter build apk --release` (첫 빌드 ~200초) |
| 설치 | `xcrun devicectl device install app --device <UDID> build/ios_dd/Build/Products/Release-iphoneos/Runner.app` | `adb -s <serial> install -r build/app/outputs/flutter-apk/app-release.apk` |
| 프로젝트 수정 | 불필요 (Team을 빌드 인자로 주입) | 불필요 |
| 서명 | development 서명 release, TestFlight 불필요 | 키스토어 설정이 없으면 debug 키 서명 release, 있으면 `key.properties` 사용 |
| 함정 | **무선 연결에서는 설치 실패**(`Connection reset`), USB에서는 성공 | 없음 |

## 3. 앱 구상

### 3.1 기본 모양 (Branch Dock 규약을 그대로)
- VS Code 옆에 세워 두는 세로 창(약 440×960, 최소 폭 380), 항상 위 옵션
- 규약: `application-release-templates` conventions-v1 (정보 창, 아이콘, 라이선스, 한/영, 라이트/다크, 릴리스 워크플로)
- 상단 상태 헤더 고정, 아래에 추천 행동 배너 + 섹션 탭 + 하단 명령 바/로그(⌘J)
- "VS Code로 열기" 버튼 (Branch Dock의 `lib/core/vscode.dart` 재사용)

### 3.2 화면 구성
1. **상태 헤더**: 프로젝트 이름/경로, Flutter·Xcode 버전, 선택된 기기(iPhone 12 mini · USB ✓ / Galaxy S25+ · USB ✓), 서명 요약(Team, 인증서, 만료까지 n일)
2. **추천 행동 배너**: 지금 막힌 것 하나만 제안. 예) "iPhone이 무선으로만 잡혀 있습니다. USB로 연결하세요", "개발자 모드가 꺼져 있습니다 [방법 보기]"
3. **탭**
   - **설치**: 플랫폼(iOS/Android) · 모드(Debug/Release) · 기기 선택 → **[빌드 & 설치]**. 아래에 실행될 명령 전체를 그대로 표시(복사 가능)하고, 단계 진행바(① 준비 `--config-only` → ② 서명 빌드 → ③ 설치 → ④ 실행)로 어디까지 됐는지 보여 준다
   - **기기**: USB/무선 상태, 개발자 모드, 신뢰, USB 디버깅 승인 상태. 각 항목이 ✗면 "무엇을 해야 하는지" 단계 안내
   - **서명**: iOS(Team, Apple Development 인증서, 프로파일 만료, 번들 ID), Android(키스토어 유무, 서명 방식)
   - **점검(Doctor)**: `flutter doctor` 요약 + 위 항목 전체 체크리스트
   - **로그**: 명령별 출력, 실패 시 "원인·조치 한 줄"로 번역(12~20개 흔한 오류부터)
4. **용어 도움말**: provisioning profile, 개발자 모드, debug 키 서명 등을 "단어 → 의미 → 그림"으로 (Branch Dock 방식)

### 3.3 "단계별 안내" 방식
- 모든 작업은 **단계 목록 + 각 단계의 실제 명령**으로 정의한다(데이터 주도). 같은 정의가 (a) 미리 보기 (b) 실행 (c) 진행바 (d) 로그의 근거가 된다.
- 사전 조건이 안 맞으면 실행 대신 해결 단계 목록을 먼저 보여 준다.
- 버튼이 실행하는 명령은 항상 복사해서 터미널에서 그대로 돌릴 수 있어야 한다(셸 없이 인자 목록으로 실행).

## 4. 아키텍처
```
lib/
  core/        command_runner, command_log, vscode   ← Branch Dock에서 가져와 맞춤
  flutter/     프로젝트 탐지(pubspec, ios/android 유무), flutter 경로, doctor
  ios/         devicectl 기기 목록(--json-output), 서명 점검, 빌드/설치 단계 정의
  android/     adb 기기 목록, 키스토어 점검, 빌드/설치 단계 정의
  plan/        Step/Plan 모델(명령, 사전조건, 오류 번역) ← CLI로도 재사용 가능
  ui/          헤더, 배너, 탭, 명령 바, 단계 진행바
  settings/    Team ID, API 키 경로, 마지막 프로젝트, 언어/테마
```
원칙: 대상 프로젝트는 수정하지 않는다 / 비밀값은 저장하지 않고 경로만 참조 / 임시 변경은 빌드 인자로만.

## 5. 단계

| Phase | 내용 | 비고 |
|---|---|---|
| 0 | 검증 스파이크 | **완료** |
| 1 | `flutter-app-bootstrap`으로 앱 골격(식별자, 버전, 릴리스 워크플로, 아이콘, 한/영, 테마) | 기능 코드 전 |
| 2 | 핵심: 프로젝트 선택, 기기 목록(iOS/Android), 설치 탭(미리보기+실행+진행바+로그) | MVP |
| 3 | 서명·기기·Doctor 탭, 추천 배너, 오류 번역 | |
| 4 | 용어 도움말, VS Code 연동, 릴리스(dmg) | |
| 5 | (선택) CLI 진입점, GitHub Actions 템플릿, Remote Control 운용 | |

## 6. 리스크
- Xcode/Flutter 버전에 따라 명령·출력 변화 → `devicectl --json-output` 사용, 버전 감지
- 플러그인이 capability/entitlement를 요구하면 자동 서명 실패 → 오류 번역에 패턴 추가
- 번들 ID가 이미 다른 팀에 있으면 충돌 → 점검 단계에서 경고, 임시 번들 ID 오버라이드는 빌드 인자로만
- iOS 첫 release 빌드는 느림(수 분) → 진행바와 취소 버튼 필요

## 7. 결정이 필요한 것
1. **앱 이름**: Branch Dock처럼 "Flutter"를 이름에 넣지 않는 쪽을 권장(상표). 후보: **Device Dock**, Launch Dock, Ship Dock
2. 폴더/저장소 이름: 현재 `~/FlutterProject/mdeploy-flutter` → 이름 확정 후 `device-dock-flutter` 식으로 변경
3. 공개 저장소(GitHub)로 낼 것인지 (다른 앱들처럼 릴리스 워크플로 포함)
