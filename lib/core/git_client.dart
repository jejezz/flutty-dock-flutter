import 'command_runner.dart';

/// 프로젝트 폴더의 git 상태: 브랜치, 원격과의 차이, 커밋하지 않은 변경, 원격 주소.
class GitState {
  const GitState({this.branch, this.upstream, this.ahead = 0, this.behind = 0, this.dirty = false, this.remoteUrl});

  /// 현재 브랜치. HEAD가 분리돼 있으면 null.
  final String? branch;

  /// 추적하는 원격 브랜치(`origin/main`). 없으면 null.
  final String? upstream;
  final int ahead;
  final int behind;

  /// 추적 중인 파일에 커밋하지 않은 변경이 있다 (추적하지 않는 새 파일은 세지 않는다).
  final bool dirty;

  /// `origin`의 주소. 없으면 null.
  final String? remoteUrl;

  bool get detached => branch == null;
  bool get hasUpstream => upstream != null;

  /// 브라우저로 열 수 있는 원격 저장소 주소.
  String? get remoteWebUrl => remoteUrl == null ? null : remoteWebUrlOf(remoteUrl!);

  /// `git pull --ff-only`가 그냥 앞으로만 합칠 수 있는 상태: 원격이 앞서 있고, 로컬이 갈라지지 않았고, 깨끗하다.
  bool get canPull => hasUpstream && behind > 0 && ahead == 0 && !dirty;

  /// [canPull]이 아닐 때의 이유. 받을 수 있으면 null.
  GitPullBlock? get pullBlock {
    if (canPull) return null;
    if (!hasUpstream) return GitPullBlock.noUpstream;
    if (dirty) return GitPullBlock.dirty;
    if (ahead > 0 && behind > 0) return GitPullBlock.diverged;
    return GitPullBlock.upToDate;
  }
}

enum GitPullBlock { noUpstream, dirty, diverged, upToDate }

/// `git status --porcelain=v2 --branch --untracked-files=no` 출력을 읽는다.
GitState parseGitStatus(String output, {String? remoteUrl}) {
  String? branch;
  String? upstream;
  var ahead = 0;
  var behind = 0;
  var dirty = false;
  for (final line in output.split('\n')) {
    final l = line.trimRight();
    if (l.isEmpty) continue;
    if (l.startsWith('# branch.head ')) {
      final head = l.substring('# branch.head '.length);
      branch = head == '(detached)' ? null : head;
    } else if (l.startsWith('# branch.upstream ')) {
      upstream = l.substring('# branch.upstream '.length);
    } else if (l.startsWith('# branch.ab ')) {
      final m = RegExp(r'\+(\d+) -(\d+)').firstMatch(l);
      if (m != null) {
        ahead = int.parse(m[1]!);
        behind = int.parse(m[2]!);
      }
    } else if (!l.startsWith('#')) {
      dirty = true;
    }
  }
  return GitState(
    branch: branch,
    upstream: upstream,
    ahead: ahead,
    behind: behind,
    dirty: dirty,
    remoteUrl: remoteUrl,
  );
}

/// 원격 주소를 브라우저 주소로 바꾼다. 모르는 형식이면 null.
///
/// `https://host/o/r(.git)`, `git@host:o/r(.git)`, `ssh://git@host(:port)/o/r(.git)`.
/// 주소에 든 사용자 이름·토큰(`https://user:token@host/...`)은 버린다.
String? remoteWebUrlOf(String remote) {
  final url = remote.trim();
  String? host;
  String? path;

  final scp = RegExp(r'^(?:[^@/\s]+@)?([A-Za-z0-9.-]+):(?!//)(.+)$').firstMatch(url);
  final scheme = RegExp(r'^(?:https?|ssh|git)://(?:[^@/\s]+@)?([A-Za-z0-9.-]+)(?::\d+)?/(.+)$').firstMatch(url);
  if (scheme != null) {
    host = scheme[1];
    path = scheme[2];
  } else if (scp != null) {
    host = scp[1];
    path = scp[2];
  }
  // 점이 없는 host는 `C:\repo` 같은 로컬 경로다.
  if (host == null || path == null || !host.contains('.')) return null;
  path = path.replaceAll(RegExp(r'/+$'), '').replaceAll(RegExp(r'\.git$'), '');
  if (path.isEmpty) return null;
  return 'https://$host/$path';
}

/// [CommandRunner]로 `git`을 실행한다. 읽기 명령은 기록에 남기지 않고, fetch·pull은 남긴다.
///
/// 자격 증명을 물어볼 수 없는 환경이라 `GIT_TERMINAL_PROMPT=0`으로 멈춤 대신 실패하게 한다.
class GitClient {
  GitClient(this.runner);

  final CommandRunner runner;

  static const _env = {'GIT_TERMINAL_PROMPT': '0'};

  /// git 저장소가 아니거나 git이 없으면 null.
  Future<GitState?> status(String directory) async {
    final r = await runner.run(
      ['git', 'status', '--porcelain=v2', '--branch', '--untracked-files=no'],
      workingDirectory: directory,
      environment: _env,
      quiet: true,
    );
    if (!r.ok) return null;
    final remote = await runner.run(
      ['git', 'remote', 'get-url', 'origin'],
      workingDirectory: directory,
      environment: _env,
      quiet: true,
    );
    return parseGitStatus(r.stdout, remoteUrl: remote.ok ? remote.stdout.trim() : null);
  }

  Future<CommandResult> fetch(String directory) =>
      runner.run(['git', 'fetch', '--prune'], workingDirectory: directory, environment: _env);

  /// 충돌 없이 앞으로만 합친다. 갈라졌으면 실패한다 (병합은 사용자가 직접).
  Future<CommandResult> pull(String directory) =>
      runner.run(['git', 'pull', '--ff-only'], workingDirectory: directory, environment: _env);
}
