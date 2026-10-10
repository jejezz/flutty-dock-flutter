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

enum GhStatus { ready, notInstalled, notLoggedIn }

/// GitHub 저장소의 Actions 시크릿을 `gh`로 다루는 창구. 화면은 이 인터페이스만 안다.
abstract class GhClient {
  /// `gh`가 설치되어 있고 로그인되어 있는지.
  Future<GhStatus> status();

  /// 등록된 시크릿 이름 → 마지막 갱신 시각. 읽지 못하면 null (권한 없음, 저장소 없음 등).
  Future<Map<String, DateTime?>?> listSecrets(String repo);

  /// 값을 **표준 입력**으로 넘겨 등록한다. 값은 명령 인자나 로그에 남지 않는다.
  Future<CommandResult> setSecret(String repo, String name, String value);

  /// 폴더의 `origin` 원격에서 `owner/repo`를 읽는다. 없으면 null.
  Future<String?> repoFromFolder(String directory);
}

/// 사람이 복사해서 실행할 수 있는 명령 — 값은 포함하지 않는다.
List<String> secretSetArgs(String repo, String name) => ['gh', 'secret', 'set', name, '--repo', repo];

final _repoPattern = RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$');

bool isValidRepo(String repo) => _repoPattern.hasMatch(repo.trim());

/// `https://github.com/o/r(.git)`, `git@github.com:o/r(.git)`에서 `o/r`를 뽑는다.
String? parseGithubRepo(String remoteUrl) {
  final m = RegExp(r'github\.com[:/]([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+?)(?:\.git)?/?$').firstMatch(remoteUrl.trim());
  return m == null ? null : '${m[1]}/${m[2]}';
}

/// `gh secret list --json name,updatedAt` 출력을 읽는다.
Map<String, DateTime?> parseSecretList(String json) {
  final list = jsonDecode(json) as List<dynamic>;
  return {
    for (final e in list.cast<Map<String, dynamic>>())
      e['name'] as String: DateTime.tryParse((e['updatedAt'] as String?) ?? '')?.toLocal(),
  };
}

const _utf8 = Utf8Codec(allowMalformed: true);

/// `gh`, `git`을 셸 없이 인자 목록으로 실행한다.
///
/// Finder에서 띄운 macOS 앱의 PATH는 `/usr/bin:/bin:/usr/sbin:/sbin`뿐이라
/// Homebrew의 `gh`를 못 찾는다 — [resolvePath]로 로그인 셸의 PATH를 가져온다.
class ProcessGhClient implements GhClient {
  ProcessGhClient(this.log);

  final CommandLog log;
  String? _path;

  Future<CommandResult> _run(List<String> args, {String? stdin, bool quiet = false}) async {
    _path ??= await resolvePath();
    final entry = quiet ? null : log.start(args);
    final watch = Stopwatch()..start();
    try {
      final process = await Process.start(
        args.first,
        args.sublist(1),
        environment: {'PATH': _path!, 'GH_PROMPT_DISABLED': '1', 'GH_NO_UPDATE_NOTIFIER': '1', 'NO_COLOR': '1'},
        runInShell: Platform.isWindows,
      );
      if (stdin != null) process.stdin.add(_utf8.encode(stdin));
      await process.stdin.close();
      final out = StringBuffer();
      final err = StringBuffer();
      void tee(StringBuffer to, String chunk) {
        to.write(chunk);
        entry?.append(chunk);
        if (entry != null) log.update();
      }

      final outDone = process.stdout.transform(_utf8.decoder).listen((c) => tee(out, c)).asFuture<void>();
      final errDone = process.stderr.transform(_utf8.decoder).listen((c) => tee(err, c)).asFuture<void>();
      final code = await process.exitCode;
      await Future.wait([outDone, errDone]);
      entry
        ?..exitCode = code
        ..duration = watch.elapsed;
      if (entry != null) log.update();
      return CommandResult(code, out.toString(), err.toString());
    } on ProcessException catch (e) {
      entry
        ?..append(e.message)
        ..exitCode = 127
        ..duration = watch.elapsed;
      if (entry != null) log.update();
      return CommandResult(127, '', e.message);
    }
  }

  @override
  Future<GhStatus> status() async {
    final r = await _run(['gh', 'auth', 'status'], quiet: true);
    if (r.exitCode == 127) return GhStatus.notInstalled;
    return r.ok ? GhStatus.ready : GhStatus.notLoggedIn;
  }

  @override
  Future<Map<String, DateTime?>?> listSecrets(String repo) async {
    final r = await _run(['gh', 'secret', 'list', '--repo', repo, '--json', 'name,updatedAt']);
    if (!r.ok) return null;
    try {
      return parseSecretList(r.stdout);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<CommandResult> setSecret(String repo, String name, String value) =>
      _run(secretSetArgs(repo, name), stdin: value);

  @override
  Future<String?> repoFromFolder(String directory) async {
    final r = await _run(['git', '-C', directory, 'remote', 'get-url', 'origin'], quiet: true);
    return r.ok ? parseGithubRepo(r.stdout) : null;
  }
}

/// `gh`, `git`을 찾을 PATH: 이 프로세스의 PATH → 로그인 셸의 PATH → 흔한 설치 위치.
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
  }
  return parts.join(sep);
}
