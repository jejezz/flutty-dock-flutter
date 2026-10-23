import 'dart:convert';

/// 프로젝트마다 다른 `flutter run`·`flutter build` 옵션. 앱 쪽에만 저장하고 프로젝트 파일은 고치지 않는다.
///
/// 비밀값은 저장하지 않는다: dart-define은 **파일 경로**만 기억하고 파일 내용은 읽지도 않는다.
class BuildOptions {
  const BuildOptions({
    this.flavor = '',
    this.target = '',
    this.defineFile = '',
    this.appId = '',
    this.extraArgs = '',
  });

  /// `--flavor`. Android·iOS·macOS에서만 쓴다 (Windows는 flavor를 지원하지 않는다).
  final String flavor;

  /// `-t`. 비우면 `lib/main.dart`.
  final String target;

  /// `--dart-define-from-file`의 파일 경로 (프로젝트 기준 상대 경로 또는 절대 경로).
  final String defineFile;

  /// flavor가 앱 ID를 바꿀 때 "실행" 단계에 쓸 ID (Android applicationId, iOS bundle id). 비우면 프로젝트 것.
  final String appId;

  /// 위에 없는 나머지 인자. 공백으로 나누고 따옴표로 묶을 수 있다.
  final String extraArgs;

  bool get isEmpty =>
      flavor.trim().isEmpty &&
      target.trim().isEmpty &&
      defineFile.trim().isEmpty &&
      appId.trim().isEmpty &&
      extraArgs.trim().isEmpty;

  /// 명령에 실제로 쓰는 flavor: 이름 규칙에 맞을 때만 (그렇지 않으면 빈 문자열).
  String get validFlavor => isValidFlavor(flavor.trim()) ? flavor.trim() : '';

  /// 입력은 있는데 flavor 이름 규칙에 맞지 않는다.
  bool get flavorInvalid => flavor.trim().isNotEmpty && !isValidFlavor(flavor.trim());

  /// `flutter run`·`flutter build` 뒤에 붙는 인자. [flavorSupported]가 아니면 flavor는 빼고 나머지만.
  List<String> flutterArgs({required bool flavorSupported}) => [
    if (flavorSupported && validFlavor.isNotEmpty) ...['--flavor', validFlavor],
    if (target.trim().isNotEmpty) ...['-t', target.trim()],
    if (defineFile.trim().isNotEmpty) '--dart-define-from-file=${defineFile.trim()}',
    ...splitArgs(extraArgs),
  ];

  /// "실행" 단계에 쓸 앱 ID: 직접 적은 것이 있으면 그것, 없으면 [fallback].
  String? appIdOr(String? fallback) => appId.trim().isNotEmpty ? appId.trim() : fallback;

  BuildOptions copyWith({String? flavor, String? target, String? defineFile, String? appId, String? extraArgs}) =>
      BuildOptions(
        flavor: flavor ?? this.flavor,
        target: target ?? this.target,
        defineFile: defineFile ?? this.defineFile,
        appId: appId ?? this.appId,
        extraArgs: extraArgs ?? this.extraArgs,
      );

  String encode() => jsonEncode({
    'flavor': flavor,
    'target': target,
    'defineFile': defineFile,
    'appId': appId,
    'extraArgs': extraArgs,
  });

  /// 저장된 문자열을 읽는다. 없거나 깨졌으면 빈 옵션.
  static BuildOptions decode(String? text) {
    if (text == null || text.isEmpty) return const BuildOptions();
    try {
      final m = jsonDecode(text) as Map<String, dynamic>;
      String s(String k) => (m[k] as String?) ?? '';
      return BuildOptions(
        flavor: s('flavor'),
        target: s('target'),
        defineFile: s('defineFile'),
        appId: s('appId'),
        extraArgs: s('extraArgs'),
      );
    } on Object {
      return const BuildOptions();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BuildOptions &&
      other.flavor == flavor &&
      other.target == target &&
      other.defineFile == defineFile &&
      other.appId == appId &&
      other.extraArgs == extraArgs;

  @override
  int get hashCode => Object.hash(flavor, target, defineFile, appId, extraArgs);
}

/// flavor 이름: 영문자로 시작하고 영문자·숫자·`_`·`-`만 (명령 인자와 폴더·scheme 이름에 그대로 들어간다).
bool isValidFlavor(String name) => RegExp(r'^[A-Za-z][A-Za-z0-9_-]*$').hasMatch(name);

/// 셸처럼 공백으로 나누되 작은따옴표·큰따옴표로 묶은 부분은 한 인자로 둔다. 이스케이프(`\`)는 쓰지 않는다
/// (Windows 경로의 `\`를 그대로 두기 위해). 닫히지 않은 따옴표는 끝까지를 한 인자로 본다.
List<String> splitArgs(String text) {
  final args = <String>[];
  final buf = StringBuffer();
  var inToken = false;
  String? quote;
  for (final ch in text.split('')) {
    if (quote != null) {
      if (ch == quote) {
        quote = null;
      } else {
        buf.write(ch);
      }
    } else if (ch == '"' || ch == "'") {
      quote = ch;
      inToken = true;
    } else if (ch.trim().isEmpty) {
      if (inToken) {
        args.add(buf.toString());
        buf.clear();
        inToken = false;
      }
    } else {
      buf.write(ch);
      inToken = true;
    }
  }
  if (inToken) args.add(buf.toString());
  return args;
}
