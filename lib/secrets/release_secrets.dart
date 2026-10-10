import 'dart:math';

/// 입력 방식.
enum SecretKind {
  /// 파일을 골라 base64로 바꿔 등록한다 (`.p12` 인증서).
  file,
  password,
  text,

  /// 앱이 무작위로 만들어 준다 (CI의 임시 키체인 암호).
  generated,
}

enum SecretIssue { empty, notEmail, badTeamId }

/// 데스크톱 릴리스 워크플로(`release.yml`)가 macOS 서명·공증에 쓰는 시크릿 하나.
class SecretSpec {
  const SecretSpec(this.name, this.kind);

  final String name;
  final SecretKind kind;
}

/// application-release-templates `desktop/README.md`의 macOS 시크릿 표와 같은 순서.
const macosReleaseSecrets = [
  SecretSpec('MACOS_CERTIFICATE_P12_BASE64', SecretKind.file),
  SecretSpec('MACOS_CERTIFICATE_PASSWORD', SecretKind.password),
  SecretSpec('MACOS_KEYCHAIN_PASSWORD', SecretKind.generated),
  SecretSpec('APPLE_ID', SecretKind.text),
  SecretSpec('APPLE_ID_PASSWORD', SecretKind.password),
  SecretSpec('APPLE_TEAM_ID', SecretKind.text),
];

/// 값이 올바르면 null, 아니면 이유.
SecretIssue? validateSecret(SecretSpec spec, String value) {
  final v = value.trim();
  if (v.isEmpty) return SecretIssue.empty;
  if (spec.name == 'APPLE_ID' && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return SecretIssue.notEmail;
  if (spec.name == 'APPLE_TEAM_ID' && !RegExp(r'^[A-Z0-9]{10}$').hasMatch(v)) return SecretIssue.badTeamId;
  return null;
}

/// CI 임시 키체인 암호 — 영숫자 32자.
String generatePassword([Random? random]) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  final r = random ?? Random.secure();
  return List.generate(32, (_) => chars[r.nextInt(chars.length)]).join();
}
