import 'dart:io';

/// Windows에서 이 프로세스가 관리자 권한(상승된 토큰)으로 실행 중인지. Windows가 아니거나 알 수 없으면 false.
///
/// `whoami /groups`에 High Mandatory Level(`S-1-16-12288`)이 있으면 상승된 프로세스다.
/// SID는 언어와 무관해서 한국어 Windows에서도 같다.
Future<bool> isRunningElevated() async {
  if (!Platform.isWindows) return false;
  try {
    final r = await Process.run('whoami', ['/groups']);
    return r.exitCode == 0 && (r.stdout as String).contains('S-1-16-12288');
  } on Object {
    return false;
  }
}

/// 상승되지 않은 일반 권한으로 이 앱을 다시 연다. 탐색기가 대신 실행하므로 권한을 물려받지 않는다.
/// 시작했으면 true.
Future<bool> relaunchWithoutElevation() async {
  if (!Platform.isWindows) return false;
  try {
    await Process.start('explorer.exe', [Platform.resolvedExecutable], mode: ProcessStartMode.detached);
    return true;
  } on Object {
    return false;
  }
}
