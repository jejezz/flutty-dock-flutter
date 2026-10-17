import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'command_log.dart';

/// 명령 실행 결과.
class CommandResult {
  const CommandResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get ok => exitCode == 0;

  String get combined => [stdout, stderr].where((s) => s.trim().isNotEmpty).join('\n');
}

/// 오래 걸리는 실행을 중간에 끊거나 입력을 보내는 핸들.
class RunHandle {
  Process? _process;
  bool _cancelled = false;

  bool get cancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _process?.kill();
  }

  /// 실행 중인 프로세스의 표준 입력으로 글자를 보낸다 (`flutter run`의 `r`, `R`, `q`).
  void send(String text) => _process?.stdin.add(utf8.encode(text));
}

const _utf8 = Utf8Codec(allowMalformed: true);

/// 자식 프로세스 출력 한 덩어리를 글자로 바꾼다. UTF-8이면 그대로 읽고, Windows에서 UTF-8이
/// 아니면 시스템 코드 페이지(한국어 Windows는 CP949)로 읽는다 — PowerShell·cmd의 오류 메시지가
/// 그 코드 페이지로 나온다.
String decodeProcessOutput(List<int> bytes, {Encoding? fallback}) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    final enc = fallback ?? (Platform.isWindows ? systemEncoding : null);
    return enc == null ? _utf8.decode(bytes) : enc.decode(bytes);
  }
}

/// 명령을 셸 없이 인자 목록으로 실행하고 [CommandLog]에 남긴다.
///
/// macOS GUI 앱의 PATH는 `/usr/bin:/bin:/usr/sbin:/sbin`뿐이라 Homebrew의 `gh`나
/// 따로 설치한 `flutter`를 못 찾는다 — [resolvePath]가 만든 PATH를 넘긴다.
class CommandRunner {
  /// [path]를 주면 로그인 셸에서 PATH를 읽지 않는다 (테스트용).
  // ignore: prefer_initializing_formals
  CommandRunner(this.log, {String? path}) : _path = path;

  final CommandLog log;
  String? _path;

  /// 사용자가 직접 지정한 실행 파일 (`flutter`, `adb`). 있으면 이름 대신 이 파일을 실행한다.
  Map<String, String> toolPaths = {};

  Future<String> get path async => _path ??= await resolvePath();

  /// 명령 이름을 실제로 실행할 파일로 바꾼다. 지정한 것이 없으면 이름 그대로(PATH에서 찾는다).
  String executableFor(String name) => toolPaths[name] ?? name;

  /// 프로세스에 넘기는 PATH. 지정한 실행 파일의 폴더를 앞에 둔다 — `flutter`가 `adb`를
  /// 찾을 때도 같은 폴더를 보게 한다.
  Future<String> get effectivePath async {
    final sep = Platform.isWindows ? ';' : ':';
    final dirs = [
      for (final p in toolPaths.values)
        if (p.isNotEmpty) File(p).parent.path,
    ];
    return [...dirs.toSet(), await path].join(sep);
  }

  /// [name]을 실제로 실행하게 될 파일의 전체 경로. 찾지 못하면 null.
  Future<String?> locate(String name) async {
    final custom = toolPaths[name];
    if (custom != null) return File(custom).existsSync() ? custom : null;
    return findExecutable(name, await effectivePath);
  }

  /// [quiet]면 로그에 남기지 않는다 (자주 도는 읽기 명령).
  /// [stdin]은 한 번 쓰고 닫는다. [keepStdinOpen]이면 [handle]로 나중에 입력을 보낼 수 있게 열어 둔다.
  Future<CommandResult> run(
    List<String> args, {
    String? workingDirectory,
    Map<String, String> environment = const {},
    bool quiet = false,
    String? stdin,
    RunHandle? handle,
    bool keepStdinOpen = false,
    void Function(String chunk)? onOutput,
  }) async {
    final entry = quiet ? null : log.start(args);
    final watch = Stopwatch()..start();
    void finish(int code) {
      entry
        ?..exitCode = code
        ..cancelled = handle?.cancelled ?? false
        ..duration = watch.elapsed;
      if (entry != null) log.update();
    }

    try {
      var executable = executableFor(args.first);
      var arguments = args.sublist(1);
      var viaShell = Platform.isWindows;
      final bash = args.first == 'flutter' ? gitBashPath() : null;
      if (bash != null) {
        // Windows의 cmd/PowerShell로 `flutter.bat`을 돌리면 오류가 많다 — Git Bash에서
        // `flutter` 셸 스크립트를 직접 실행한다. 인자는 "$@"로 넘겨 따옴표 문제를 피한다.
        final script = flutterShellScript(executable, await effectivePath);
        if (script != null) {
          arguments = ['-c', r'exec "$@"', 'bash', script, ...arguments];
          executable = bash;
          viaShell = false;
        }
      }
      final process = await Process.start(
        executable,
        arguments,
        // 지정하지 않으면 이 앱의 작업 디렉터리(설치 폴더 등)를 물려받는다 — flutter가 거기에
        // hash.txt를 쓰려다 쓰기 권한이 없어 실패한다. 쓸 수 있는 임시 폴더에서 돌린다.
        workingDirectory: workingDirectory ?? Directory.systemTemp.path,
        environment: {
          'PATH': await effectivePath,
          'GH_PROMPT_DISABLED': '1',
          'GH_NO_UPDATE_NOTIFIER': '1',
          'NO_COLOR': '1',
          ...environment,
        },
        runInShell: viaShell,
      );
      handle?._process = process;
      if (stdin != null) {
        process.stdin.add(_utf8.encode(stdin));
        await process.stdin.close();
      } else if (!keepStdinOpen) {
        await process.stdin.close();
      }
      final out = StringBuffer();
      final err = StringBuffer();
      void tee(StringBuffer to, String chunk) {
        to.write(chunk);
        entry?.append(chunk);
        onOutput?.call(chunk);
        if (entry != null) log.update();
      }

      final outDone = process.stdout.map(decodeProcessOutput).listen((c) => tee(out, c)).asFuture<void>();
      final errDone = process.stderr.map(decodeProcessOutput).listen((c) => tee(err, c)).asFuture<void>();
      final code = await process.exitCode;
      await Future.wait([outDone, errDone]);
      finish(code);
      return CommandResult(code, out.toString(), err.toString());
    } on ProcessException catch (e) {
      entry?.append(e.message);
      finish(127);
      return CommandResult(127, '', e.message);
    }
  }
}

/// Windows에서 Git for Windows의 `bash.exe` 경로. 없거나 Windows가 아니면 null.
/// (`C:\Windows\System32\bash.exe`는 WSL이라 쓰지 않는다.)
String? gitBashPath() {
  if (!Platform.isWindows) return null;
  final env = Platform.environment;
  final candidates = [
    for (final root in [env['ProgramFiles'], env['ProgramW6432'], env['LOCALAPPDATA'] == null ? null : '${env['LOCALAPPDATA']}\\Programs'])
      if (root != null) '$root\\Git\\bin\\bash.exe',
  ];
  for (final c in candidates) {
    if (File(c).existsSync()) return c;
  }
  return null;
}

/// `flutter` 명령에 해당하는 셸 스크립트(`bin/flutter`, 확장자 없음) 경로. 없으면 null.
String? flutterShellScript(String executable, String path) {
  var file = executable;
  if (executable == 'flutter') {
    file = findExecutable('flutter', path) ?? '';
  }
  if (file.isEmpty) return null;
  final lower = file.toLowerCase();
  if (lower.endsWith('.bat') || lower.endsWith('.cmd') || lower.endsWith('.exe')) {
    file = file.substring(0, file.length - 4);
  }
  return File(file).existsSync() ? file.replaceAll('\\', '/') : null;
}

/// [path]의 폴더들에서 [name] 실행 파일을 찾아 전체 경로를 돌려준다. 없으면 null.
/// Windows에서는 `.exe`를 먼저, 그다음 `.cmd`·`.bat`를 찾는다.
String? findExecutable(String name, String path) {
  final windows = Platform.isWindows;
  final names = windows ? ['$name.exe', '$name.cmd', '$name.bat'] : [name];
  for (final file in names) {
    for (final dir in path.split(windows ? ';' : ':')) {
      if (dir.trim().isEmpty) continue;
      final f = File('${dir.trim()}${Platform.pathSeparator}$file');
      if (f.existsSync()) return f.path;
    }
  }
  return null;
}

/// 실행 파일을 찾을 PATH: 이 프로세스의 PATH → 로그인 셸의 PATH → 흔한 설치 위치.
Future<String> resolvePath() async {
  final sep = Platform.isWindows ? ';' : ':';
  final parts = <String>[];
  void addAll(String? value) {
    if (value == null) return;
    for (final p in value.split(sep)) {
      final t = p.trim();
      if (t.isNotEmpty && !parts.contains(t)) parts.add(t);
    }
  }

  addAll(Platform.environment['PATH']);
  if (!Platform.isWindows) {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    try {
      final r = await Process.run(shell, ['-lc', r'printf %s "$PATH"']).timeout(const Duration(seconds: 3));
      if (r.exitCode == 0) addAll(r.stdout as String);
    } on Object {
      // 셸이 느리거나 없으면 흔한 위치로 충분하다.
    }
    addAll('/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin');
    addAll(_existing(_commonToolDirs()).join(sep));
  } else {
    final local = Platform.environment['LOCALAPPDATA'];
    final env = Platform.environment;
    addAll(
      [
        '${env['ProgramFiles'] ?? r'C:\Program Files'}\\Git\\cmd',
        ..._existing([
          if (local != null) '$local\\Android\\Sdk\\platform-tools',
          if (env['ANDROID_HOME'] != null) '${env['ANDROID_HOME']}\\platform-tools',
          if (env['ANDROID_SDK_ROOT'] != null) '${env['ANDROID_SDK_ROOT']}\\platform-tools',
        ]),
      ].join(sep),
    );
  }
  return parts.join(sep);
}

/// 셸 설정(`.zshrc`)에만 PATH를 넣어 둔 도구를 위해 흔한 설치 위치를 더한다 — 실제로 있는 폴더만.
List<String> _commonToolDirs() {
  final env = Platform.environment;
  final home = env['HOME'];
  return [
    if (env['ANDROID_HOME'] != null) '${env['ANDROID_HOME']}/platform-tools',
    if (env['ANDROID_SDK_ROOT'] != null) '${env['ANDROID_SDK_ROOT']}/platform-tools',
    if (home != null) ...[
      '$home/Library/Android/sdk/platform-tools',
      '$home/Android/Sdk/platform-tools',
      '$home/development/flutter/bin',
      '$home/flutter/bin',
      '$home/fvm/default/bin',
    ],
  ];
}

List<String> _existing(List<String> dirs) => [
  for (final d in dirs)
    if (Directory(d).existsSync()) d,
];
