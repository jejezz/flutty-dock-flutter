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

/// `git worktree list`의 항목 하나: 폴더와 그 폴더에 체크아웃된 브랜치.
class GitWorktree {
  const GitWorktree({required this.path, this.branch, this.detached = false});

  /// 폴더 경로 (git이 주는 대로 `/` 구분).
  final String path;

  /// 체크아웃된 브랜치(`main`). 분리된 HEAD면 null.
  final String? branch;
  final bool detached;

  /// 폴더 이름(경로의 마지막 마디).
  String get folderName {
    final parts = path.split('/').where((p) => p.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }

  @override
  bool operator ==(Object other) =>
      other is GitWorktree && other.path == path && other.branch == branch && other.detached == detached;

  @override
  int get hashCode => Object.hash(path, branch, detached);
}

/// `git worktree list --porcelain` 출력을 읽는다. 첫 항목이 원래 작업 폴더다.
/// 저장소 자체(`bare`)와 이미 사라진 폴더(`prunable`)는 연 수 없으므로 뺀다.
List<GitWorktree> parseWorktrees(String output) {
  final result = <GitWorktree>[];
  String? path;
  String? branch;
  var detached = false;
  var skip = false;

  void flush() {
    if (path != null && !skip) result.add(GitWorktree(path: path!, branch: branch, detached: detached));
    path = null;
    branch = null;
    detached = false;
    skip = false;
  }

  for (final raw in output.split('\n')) {
    final line = raw.trimRight();
    if (line.isEmpty) {
      flush();
    } else if (line.startsWith('worktree ')) {
      flush();
      path = line.substring('worktree '.length);
    } else if (line.startsWith('branch ')) {
      branch = line.substring('branch '.length).replaceFirst('refs/heads/', '');
    } else if (line == 'detached') {
      detached = true;
    } else if (line == 'bare' || line.startsWith('prunable')) {
      skip = true;
    }
  }
  flush();
  return result;
}

/// 프로젝트 경로가 속한 worktree: 경로를 포함하는 것 중 가장 깊은 것. 없으면 null.
/// Windows 경로(`\`)와 대소문자 차이는 같은 것으로 본다.
GitWorktree? worktreeContaining(List<GitWorktree> worktrees, String projectPath) {
  String norm(String p) => p.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '').toLowerCase();
  final target = norm(projectPath);
  GitWorktree? best;
  for (final w in worktrees) {
    final root = norm(w.path);
    if (target == root || target.startsWith('$root/')) {
      if (best == null || root.length > norm(best.path).length) best = w;
    }
  }
  return best;
}

/// 현재 프로젝트가 [from] worktree 안의 어느 하위 폴더에 있는지를 [to] worktree에 옮긴 경로.
/// 저장소 루트가 곧 프로젝트면 [to]의 경로 그대로, 모노레포의 하위 프로젝트면 같은 하위 폴더.
String projectPathIn(GitWorktree from, GitWorktree to, String projectPath) {
  final fromRoot = from.path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  final project = projectPath.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  final sub = project.length > fromRoot.length ? project.substring(fromRoot.length) : '';
  return '${to.path.replaceAll(RegExp(r'/+$'), '')}$sub';
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

  /// git을 실행할 수 있는지 (설치되어 PATH에 있는지). 저장소인지는 따지지 않는다.
  Future<bool> available() async {
    final r = await runner.run(['git', '--version'], environment: _env, quiet: true);
    return r.ok;
  }

  /// 이 저장소의 worktree 목록 (첫 항목이 원래 작업 폴더). 읽지 못하면 빈 목록.
  Future<List<GitWorktree>> worktrees(String directory) async {
    final r = await runner.run(
      ['git', 'worktree', 'list', '--porcelain'],
      workingDirectory: directory,
      environment: _env,
      quiet: true,
    );
    return r.ok ? parseWorktrees(r.stdout) : const [];
  }

  Future<CommandResult> fetch(String directory) =>
      runner.run(['git', 'fetch', '--prune'], workingDirectory: directory, environment: _env);

  /// 충돌 없이 앞으로만 합친다. 갈라졌으면 실패한다 (병합은 사용자가 직접).
  Future<CommandResult> pull(String directory) =>
      runner.run(['git', 'pull', '--ff-only'], workingDirectory: directory, environment: _env);
}
