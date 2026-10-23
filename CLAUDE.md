# Flutty Dock

Flutter 앱을 USB로 연결한 iPhone·Android 실기기에 debug/release로 빌드·설치하는 데스크톱 도우미
(macOS / Windows). 편집기(VS Code) 옆에 세로로 세워 두고, 버튼마다 실제로 실행되는 명령을 보여 주며
막힌 서명·기기 문제는 원인과 해결 단계로 안내한다. iOS 설치는 macOS + Xcode가 필요하고, Windows에서는
Android만 설치할 수 있다.

릴리스·버전·패키징·정보 창·아이콘·라이선스·UI/UX·글꼴·언어·테마는
https://github.com/jejezz/application-release-templates/tree/main/conventions
규약을 따른다. 이 앱에 적용된 규약 버전: conventions-v1

- 표시 이름 `Flutty Dock`, 파일 이름 `FluttyDock`, 패키지 `flutty_dock`,
  식별자 `art.zoomon.fluttydock`. 식별자와 `installer/windows/app.iss`의 `AppId`는 릴리스 후 바꾸지 않는다.
- 앱 이름에 "Flutter"를 넣지 않는다 (Flutter 상표). 소개 문구에서만 "for Flutter apps"처럼 쓴다.
- 대상: USB로 연결된 iPhone·Android, 그리고 프로젝트에 `macos/`·`windows/`가 이미 있을 때만 이 컴퓨터(현재 OS)의 데스크톱. 없는 플랫폼은 만들어 주지 않는다.
- 대상 프로젝트는 수정하지 않는다: 서명 Team 등은 빌드 인자로 주입하고, 설정은 앱 쪽에만 저장한다.
  유일한 예외는 사용자가 직접 누른 git 동작이다. git은 상태 표시, `fetch --prune`, `pull --ff-only`까지만 한다
  (깨끗하고 앞으로만 합칠 수 있을 때만 pull; push·병합·강제 동작은 두지 않는다).
- 비밀값(키, 비밀번호)은 저장하지 않고 경로만 참조한다.
- 창은 도킹형 세로 창(440×960, 최소 380×560)이다. 구조 참고: ../branch-dock-flutter.
- 기능 범위는 [PLAN.md](PLAN.md)(Phase 0 검증 결과 포함).
- 릴리스는 macOS + Windows만 (Linux 잡은 release.yml에서 뺐다).
