import 'dart:io';

import '../core/command_runner.dart';
import '../flutter/flutter_project.dart';
import 'signing_info.dart';

/// 명령줄 도구 하나: 찾았으면 버전, 못 찾았으면 [version]이 null.
class ToolInfo {
  const ToolInfo(this.version, {this.error});

  final String? version;

  /// 실행은 했지만 실패했을 때 도구가 남긴 첫 줄들. 못 찾은 경우엔 비어 있다.
  final String? error;
  bool get found => version != null;
}

/// 릴리스 APK를 서명하는 방식.
enum AndroidSigning {
  /// 프로젝트에 키스토어 설정이 없다 — Flutter 기본값인 debug 키로 서명한다 (개인 설치용으로는 충분).
  debugKey,
  keystore,

  /// `key.properties`가 있는데 `storeFile`이 가리키는 파일이 없다.
  keystoreMissing,
}

/// 한 번 모은 환경 정보. 점검 탭과 서명 탭이 같은 값을 본다.
class Diagnostics {
  const Diagnostics({
    required this.flutter,
    required this.xcode,
    required this.adb,
    this.certs = const [],
    this.profiles = const [],
    this.androidSigning,
    required this.collectedAt,
  });

  final ToolInfo flutter;
  final ToolInfo xcode;
  final ToolInfo adb;
  final List<SigningCert> certs;

  /// 이름·Team이 같은 인증서를 하나로 합친 목록 — 화면과 점검은 이것을 쓴다.
  List<SigningCert> get distinctCerts => uniqueCerts(certs);
  final List<ProfileInfo> profiles;
  final AndroidSigning? androidSigning;
  final DateTime collectedAt;

  /// 개인 키가 있는 개발 인증서의 Team ID들.
  Set<String> get usableTeams => {
    for (final c in certs)
      if (c.hasPrivateKey) c.teamId,
  };
}

abstract class DiagnosticsService {
  Future<Diagnostics> collect(FlutterProject? project);
}

class ProcessDiagnosticsService implements DiagnosticsService {
  ProcessDiagnosticsService(this.runner);

  final CommandRunner runner;

  Future<ToolInfo> _tool(List<String> args, RegExp pattern) async {
    final r = await runner.run(args, quiet: true);
    if (!r.ok) {
      final lines = r.combined.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).take(2).join(' ');
      // 실행 파일을 못 찾은 경우(127)는 '못 찾음'이지 '실행 실패'가 아니다.
      return ToolInfo(null, error: r.exitCode == 127 || lines.isEmpty ? null : lines);
    }
    return ToolInfo(pattern.firstMatch(r.combined)?[1] ?? '?');
  }

  @override
  Future<Diagnostics> collect(FlutterProject? project) async {
    final results = await Future.wait([
      _tool(['flutter', '--version'], RegExp(r'Flutter (\S+)')),
      Platform.isMacOS ? _tool(['xcodebuild', '-version'], RegExp(r'Xcode (\S+)')) : Future.value(const ToolInfo(null)),
      _tool(['adb', 'version'], RegExp(r'Version (\S+)')),
      if (Platform.isMacOS) _certs() else Future.value(const <SigningCert>[]),
      if (Platform.isMacOS) _profiles() else Future.value(const <ProfileInfo>[]),
      _androidSigning(project),
    ]);
    return Diagnostics(
      flutter: results[0] as ToolInfo,
      xcode: results[1] as ToolInfo,
      adb: results[2] as ToolInfo,
      certs: results[3] as List<SigningCert>,
      profiles: results[4] as List<ProfileInfo>,
      androidSigning: results[5] as AndroidSigning?,
      collectedAt: DateTime.now(),
    );
  }

  Future<List<SigningCert>> _certs() async {
    final identities = await runner.run(['security', 'find-identity', '-v', '-p', 'codesigning'], quiet: true);
    final names = parseIdentityNames(identities.stdout);
    final pems = await runner.run(['security', 'find-certificate', '-a', '-c', 'Apple Development', '-p'], quiet: true);
    final out = <SigningCert>[];
    for (final pem in splitPems(pems.stdout)) {
      final r = await runner.run(
        ['openssl', 'x509', '-noout', '-subject', '-enddate', '-nameopt', 'RFC2253'],
        stdin: pem,
        quiet: true,
      );
      final cert = parseOpenSslCert(r.stdout, identityNames: names);
      if (cert != null) out.add(cert);
    }
    return out;
  }

  Future<List<ProfileInfo>> _profiles() async {
    final home = Platform.environment['HOME'];
    if (home == null) return const [];
    final out = <ProfileInfo>[];
    for (final dir in [
      '$home/Library/Developer/Xcode/UserData/Provisioning Profiles',
      '$home/Library/MobileDevice/Provisioning Profiles',
    ]) {
      final d = Directory(dir);
      if (!await d.exists()) continue;
      await for (final f in d.list()) {
        if (!f.path.endsWith('.mobileprovision')) continue;
        final r = await runner.run(['security', 'cms', '-D', '-i', f.path], quiet: true);
        final info = r.ok ? parseProfileXml(r.stdout) : null;
        if (info != null) out.add(info);
      }
    }
    return out;
  }

  Future<AndroidSigning?> _androidSigning(FlutterProject? project) async {
    if (project == null || !project.hasAndroid) return null;
    final props = File('${project.path}/android/key.properties');
    if (!await props.exists()) return AndroidSigning.debugKey;
    final store = parseKeyPropertiesStoreFile(await props.readAsString());
    if (store == null) return AndroidSigning.keystoreMissing;
    // storeFile은 android/app 기준 상대 경로이거나 절대 경로다.
    final file = store.startsWith('/') ? File(store) : File('${project.path}/android/app/$store');
    return await file.exists() ? AndroidSigning.keystore : AndroidSigning.keystoreMissing;
  }
}
