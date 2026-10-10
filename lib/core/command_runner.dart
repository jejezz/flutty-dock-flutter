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

/// 명령을 셸 없이 인자 목록으로 실행하고 [CommandLog]에 남긴다.
///
/// macOS GUI 앱의 PATH는 `/usr/bin:/bin:/usr/sbin:/sbin`뿐이라 Homebrew의 `gh`나
/// 따로 설치한 `flutter`를 못 찾는다 — [resolvePath]가 만든 PATH를 넘긴다.
class CommandRunner {
  CommandRunner(this.log);

  final CommandLog log;
  String? _path;

  Future<String> get path async => _path ??= await resolvePath();

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
      final process = await Process.start(
        args.first,
        args.sublist(1),
        workingDirectory: workingDirectory,
        environment: {
          'PATH': await path,
          'GH_PROMPT_DISABLED': '1',
          'GH_NO_UPDATE_NOTIFIER': '1',
          'NO_COLOR': '1',
          ...environment,
        },
        runInShell: Platform.isWindows,
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

      final outDone = process.stdout.transform(_utf8.decoder).listen((c) => tee(out, c)).asFuture<void>();
      final errDone = process.stderr.transform(_utf8.decoder).listen((c) => tee(err, c)).asFuture<void>();
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
  } else {
    final local = Platform.environment['LOCALAPPDATA'];
    addAll(
      [
        '${Platform.environment['ProgramFiles'] ?? r'C:\Program Files'}\\Git\\cmd',
        if (local != null) '$local\\Android\\Sdk\\platform-tools',
      ].join(sep),
    );
  }
  return parts.join(sep);
}
