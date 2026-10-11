import 'dart:io';

/// 디스크의 Flutter 프로젝트 한 개. 읽기만 한다 — 프로젝트 파일은 고치지 않는다.
class FlutterProject {
  const FlutterProject({
    required this.path,
    required this.name,
    this.version,
    required this.hasIos,
    required this.hasAndroid,
    this.iosBundleId,
    this.iosTeamId,
    this.androidApplicationId,
    this.hasMacos = false,
    this.hasWindows = false,
    this.macosAppName,
    this.windowsBinaryName,
  });

  final String path;
  final String name;
  final String? version;
  final bool hasIos;
  final bool hasAndroid;

  /// `ios/Runner.xcodeproj`에서 읽은 번들 ID. 변수(`$(…)`)면 null.
  final String? iosBundleId;

  /// 프로젝트에 이미 들어 있는 `DEVELOPMENT_TEAM`.
  final String? iosTeamId;
  final String? androidApplicationId;

  /// 이 프로젝트가 데스크톱을 이미 지원하는지 (`macos/Runner.xcodeproj`, `windows/CMakeLists.txt`가 있음).
  final bool hasMacos;
  final bool hasWindows;

  /// 빌드 산출물 이름: macOS는 `<PRODUCT_NAME>.app`, Windows는 `<BINARY_NAME>.exe`.
  final String? macosAppName;
  final String? windowsBinaryName;

  /// [dir]이 Flutter 프로젝트면 읽어서 돌려주고, 아니면 null.
  static Future<FlutterProject?> detect(String dir) async {
    final pubspec = File('$dir/pubspec.yaml');
    if (!await pubspec.exists()) return null;
    final text = await pubspec.readAsString();
    if (!isFlutterPubspec(text)) return null;
    final pbx = File('$dir/ios/Runner.xcodeproj/project.pbxproj');
    final pbxText = await pbx.exists() ? await pbx.readAsString() : null;
    String? gradle;
    for (final f in ['$dir/android/app/build.gradle.kts', '$dir/android/app/build.gradle']) {
      if (await File(f).exists()) {
        gradle = await File(f).readAsString();
        break;
      }
    }
    final xcconfig = File('$dir/macos/Runner/Configs/AppInfo.xcconfig');
    final cmake = File('$dir/windows/CMakeLists.txt');
    final hasMacos = await File('$dir/macos/Runner.xcodeproj/project.pbxproj').exists();
    final hasWindows = await cmake.exists();
    return FlutterProject(
      path: dir,
      name: parsePubspecField(text, 'name') ?? dir.split(Platform.pathSeparator).last,
      version: parsePubspecField(text, 'version'),
      hasIos: pbxText != null,
      hasAndroid: gradle != null,
      iosBundleId: pbxText == null ? null : parseIosBundleId(pbxText),
      iosTeamId: pbxText == null ? null : parseIosTeamId(pbxText),
      androidApplicationId: gradle == null ? null : parseAndroidApplicationId(gradle),
      hasMacos: hasMacos,
      hasWindows: hasWindows,
      macosAppName: hasMacos && await xcconfig.exists() ? parseMacosProductName(await xcconfig.readAsString()) : null,
      windowsBinaryName: hasWindows ? parseWindowsBinaryName(await cmake.readAsString()) : null,
    );
  }
}

/// `dependencies:` 아래에 `flutter:` SDK 의존성이 있으면 Flutter 프로젝트다.
bool isFlutterPubspec(String pubspec) =>
    RegExp(r'^\s{2}flutter:\s*$\n\s{4}sdk:\s*flutter', multiLine: true).hasMatch(pubspec);

String? parsePubspecField(String pubspec, String key) {
  final m = RegExp('^$key:\\s*["\']?([^"\'\\n#]+?)["\']?\\s*(?:#.*)?\$', multiLine: true).firstMatch(pubspec);
  return m?[1];
}

/// 앱 본체의 번들 ID — 테스트 타깃(`RunnerTests`)과 변수 참조는 건너뛴다.
String? parseIosBundleId(String pbxproj) {
  for (final m in RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);').allMatches(pbxproj)) {
    final v = m[1]!.trim().replaceAll('"', '');
    if (!v.contains('RunnerTests') && !v.startsWith(r'$(')) return v;
  }
  return null;
}

String? parseIosTeamId(String pbxproj) => RegExp(r'DEVELOPMENT_TEAM = ([A-Z0-9]{10});').firstMatch(pbxproj)?[1];

String? parseAndroidApplicationId(String gradle) =>
    RegExp(r'''applicationId\s*=?\s*["']([^"']+)["']''').firstMatch(gradle)?[1];

/// `macos/Runner/Configs/AppInfo.xcconfig`의 `PRODUCT_NAME` — 앱 번들 이름(`<이름>.app`).
String? parseMacosProductName(String xcconfig) =>
    RegExp(r'^\s*PRODUCT_NAME\s*=\s*(.+?)\s*$', multiLine: true).firstMatch(xcconfig)?[1];

/// `windows/CMakeLists.txt`의 `set(BINARY_NAME "…")` — 실행 파일 이름(`<이름>.exe`).
String? parseWindowsBinaryName(String cmake) => RegExp(r'set\(\s*BINARY_NAME\s+"([^"]+)"\s*\)').firstMatch(cmake)?[1];
