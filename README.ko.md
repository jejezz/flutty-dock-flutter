<!-- From jejezz/application-release-templates common/tool/readme @ conventions-v1.
     tool/readme/init_readme.py가 만든 파일입니다 — conventions/readme-guide.md 참고.
     {{TODO: …}}를 모두 채우십시오. 하나라도 남아 있으면 tool/readme/check_readme.py가 실패합니다. -->

<p align="center">
  <img src="assets/icon/app_icon.png" width="128" alt="Flutty Dock 아이콘">
</p>

<h1 align="center">Flutty Dock</h1>

<p align="center">
  편집기 옆에 세워 두고 Flutter 앱을 <b>iPhone·Android 실기기에 USB로 빌드·설치</b>하는 무료 오픈소스 데스크톱 도우미 — 버튼마다 실제 실행되는 명령을 보여 줍니다.
</p>

<p align="center">
  <a href="https://github.com/jejezz/flutty-dock-flutter/releases/latest"><img src="https://img.shields.io/github/v/release/jejezz/flutty-dock-flutter?style=flat-square&color=4c9dff" alt="최신 릴리스"></a>
  <a href="https://github.com/jejezz/flutty-dock-flutter/releases"><img src="https://img.shields.io/github/downloads/jejezz/flutty-dock-flutter/total?style=flat-square&color=7c5cff" alt="다운로드"></a>
  <img src="https://img.shields.io/badge/platform-macOS%20%C2%B7%20Windows-34d399?style=flat-square" alt="macOS · Windows">
  <img src="https://img.shields.io/badge/built%20with-Flutter-02569b?style=flat-square" alt="Flutter">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/jejezz/flutty-dock-flutter?style=flat-square" alt="MIT 라이선스"></a>
</p>

<p align="center">
  <a href="README.md">English</a> · <b>한국어</b>
</p>

<p align="center">
  <img src="docs/screenshots/demo.gif" width="720" alt="Flutty Dock 데모: Flutter 프로젝트를 고르고 USB로 연결된 폰에 release 버전을 빌드해 설치">
</p>

## 기능

- **명령을 보여 주는 버튼** — 빌드·설치·실행 단계마다 실제로 실행되는 명령(`xcodebuild …`, `xcrun devicectl device install app …`, `adb install -r …`)을 그대로 복사할 수 있게 보여 주고, 명령 기록에 출력을 남깁니다
- **USB로 iPhone·Android, debug·release** — release는 개발 인증서로 서명해 TestFlight 없이 폰에 바로 설치하고, debug는 `flutter run`으로 핫 리로드·핫 리스타트 버튼을 씁니다
- **프로젝트를 고치지 않습니다** — 서명 Team은 빌드 인자로만 넘기고 `project.pbxproj`에 쓰지 않아서, 어떤 Flutter 프로젝트든 그대로 쓸 수 있습니다
- **다음에 할 일 하나를 알려 줍니다** — 막힌 것(USB가 아니라 무선, 개발자 모드 꺼짐, Team ID 없음 …)을 배너로 알리고 번호 붙은 해결 단계를 펼쳐 보여 줍니다. 점검 탭은 Flutter·Xcode·adb, 인증서와 만료, 프로비저닝 프로파일(무료 계정의 7일 프로파일 포함), Android 키스토어를 확인합니다
- **릴리스 시크릿 등록 (macOS)** — macOS 서명용 GitHub Actions 시크릿을 `gh secret set`으로 등록합니다. 값은 표준 입력으로 전달하고 저장하지 않으며 명령 기록에도 남지 않습니다
- **편집기 옆에서** — 프로젝트를 VS Code로 열고, 폴더를 창에 끌어다 놓을 수 있으며, 창 크기와 위치를 기억합니다
- **라이트·다크, 한국어·English** — 시스템 설정을 따르거나 툴바에서 고를 수 있습니다

<p align="center">
  <img src="docs/screenshots/home.png" width="360" alt="설치 탭: 프로젝트, Release 모드와 USB로 연결된 폰에 실행될 명령 (라이트·다크)">
  <img src="docs/screenshots/detail.png" width="360" alt="점검 탭: Flutter·Xcode·adb·서명 인증서·연결된 폰 점검과 실패 항목의 해결 단계">
</p>

## 설치

[**Releases**](https://github.com/jejezz/flutty-dock-flutter/releases/latest)에서 받습니다.

| OS | 파일 |
|---|---|
| macOS 12.0 이상 | `FluttyDock-<버전>-macos-universal.dmg` — 열어서 앱을 Applications 폴더로 끌어다 놓으세요 |
| Windows 10/11 (x64) | `FluttyDock-<버전>-windows-x64-setup.exe` |

**Windows:** 설치 프로그램에 아직 코드 서명이 없어서 SmartScreen이 "Windows의 PC 보호" 창을 띄웁니다. **추가 정보 → 실행**을 누르세요.

## 동작 방식

Flutty Dock은 Flutter 도구를 다시 만들지 않습니다. 이미 설치된 `flutter`, `xcodebuild`, `xcrun devicectl`, `adb`를 셸 없이 인자 목록으로 실행하므로 앱에서 한 일과 터미널에서 한 일이 항상 같습니다. 서명 Team은 release에서는 `xcodebuild` 명령줄의 `DEVELOPMENT_TEAM=<id>`로, `flutter run`에서는 `FLUTTER_XCODE_DEVELOPMENT_TEAM` 환경 변수로 넘깁니다(Flutter가 `FLUTTER_XCODE_*` 변수를 `xcodebuild`에 전달합니다). 그래서 프로젝트 파일은 그대로입니다.

## 개발

```bash
flutter pub get
flutter run -d macos
```

iPhone에 설치하려면 Xcode가 있는 macOS와, Xcode에 로그인된 Apple Developer 계정이 필요합니다. Windows에서는 Android만 지원합니다. Android에는 `PATH`에 `adb`(Android SDK platform-tools)가 필요하고, 릴리스 시크릿 화면에는 GitHub CLI(`gh`)가 필요합니다. 실기기에서 검증한 범위와 계획은 [PLAN.md](PLAN.md)에 있습니다.

릴리스: `scripts/bump-version.sh patch` → 병합 → `vX.Y.Z` 태그. CI가 모든 플랫폼을 빌드해서 올립니다. 규칙: [application-release-templates/conventions](https://github.com/jejezz/application-release-templates/tree/main/conventions).

## 크레딧

- 글꼴: [서울남산체](https://www.seoul.go.kr/seoul/font.do) (서울특별시)
- 아이콘: [Icons8](https://icons8.com)

## 라이선스

[MIT](LICENSE) © 2026 Jongyun Ahn
