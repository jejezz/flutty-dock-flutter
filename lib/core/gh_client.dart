import 'dart:convert';

import 'command_runner.dart';

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

/// [CommandRunner]로 `gh`, `git`을 실행하는 실제 구현.
class ProcessGhClient implements GhClient {
  ProcessGhClient(this.runner);

  final CommandRunner runner;

  @override
  Future<GhStatus> status() async {
    final r = await runner.run(['gh', 'auth', 'status'], quiet: true);
    if (r.exitCode == 127) return GhStatus.notInstalled;
    return r.ok ? GhStatus.ready : GhStatus.notLoggedIn;
  }

  @override
  Future<Map<String, DateTime?>?> listSecrets(String repo) async {
    final r = await runner.run(['gh', 'secret', 'list', '--repo', repo, '--json', 'name,updatedAt']);
    if (!r.ok) return null;
    try {
      return parseSecretList(r.stdout);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<CommandResult> setSecret(String repo, String name, String value) =>
      runner.run(secretSetArgs(repo, name), stdin: value);

  @override
  Future<String?> repoFromFolder(String directory) async {
    final r = await runner.run(['git', '-C', directory, 'remote', 'get-url', 'origin'], quiet: true);
    return r.ok ? parseGithubRepo(r.stdout) : null;
  }
}
