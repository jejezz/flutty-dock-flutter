/// 키체인의 개발 인증서 하나.
class SigningCert {
  const SigningCert({required this.name, required this.teamId, this.expires, this.hasPrivateKey = false});

  /// `Apple Development: 이름 (XXXXXXXXXX)`
  final String name;

  /// 인증서의 OU — 서명에 쓰는 Team ID.
  final String teamId;
  final DateTime? expires;

  /// 개인 키가 이 Mac에 있어야 서명할 수 있다 (`security find-identity -v`에 나온다).
  final bool hasPrivateKey;

  int? daysLeft(DateTime now) => expires?.difference(now).inDays;
}

/// 이름과 Team이 같은 인증서는 하나로 합친다.
///
/// 키체인에는 같은 이름의 개발 인증서가 여러 장 있을 수 있다(만료일만 다름). 목록과 점검에는 쓸 수 있는 쪽 하나만
/// 보여 준다: 개인 키가 있는 것을 먼저, 그다음 만료가 가장 늦은 것. 순서는 처음 나온 순서를 따른다.
List<SigningCert> uniqueCerts(List<SigningCert> certs) {
  final best = <String, SigningCert>{};
  for (final c in certs) {
    final key = '${c.teamId}\u0000${c.name}';
    final current = best[key];
    if (current == null || _better(c, current)) best[key] = c;
  }
  return best.values.toList();
}

bool _better(SigningCert a, SigningCert b) {
  if (a.hasPrivateKey != b.hasPrivateKey) return a.hasPrivateKey;
  final ae = a.expires, be = b.expires;
  if (ae == null || be == null) return ae != null && be == null;
  return ae.isAfter(be);
}

/// `~/Library/.../Provisioning Profiles`의 프로파일 하나.
class ProfileInfo {
  const ProfileInfo({
    required this.name,
    required this.appId,
    required this.teamId,
    this.created,
    this.expires,
    this.deviceCount,
  });

  final String name;

  /// `TEAMID.번들ID` (와일드카드면 `TEAMID.*`)
  final String appId;
  final String teamId;
  final DateTime? created;
  final DateTime? expires;
  final int? deviceCount;

  /// 무료 Apple ID 프로파일은 수명이 7일이다.
  bool get isShortLived => created != null && expires != null && expires!.difference(created!).inDays <= 8;

  int? daysLeft(DateTime now) => expires?.difference(now).inDays;

  bool matches(String bundleId) {
    final id = appId.contains('.') ? appId.substring(appId.indexOf('.') + 1) : appId;
    return id == bundleId || id == '*' || (id.endsWith('.*') && bundleId.startsWith(id.substring(0, id.length - 1)));
  }
}

/// `security find-certificate -a -p` 출력을 인증서 한 개씩의 PEM으로 나눈다.
List<String> splitPems(String text) => [
  for (final m in RegExp(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', dotAll: true).allMatches(text))
    '${m[0]}\n',
];

const _months = {
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};

/// `openssl x509 -noout -subject -enddate -nameopt RFC2253` 출력에서 인증서를 읽는다.
SigningCert? parseOpenSslCert(String out, {Set<String> identityNames = const {}}) {
  final cn = RegExp(r'CN=([^,\n]+(?:\([^)]*\))?)').firstMatch(out)?[1]?.trim();
  final ou = RegExp(r'OU=([A-Z0-9]{10})').firstMatch(out)?[1];
  if (cn == null || ou == null) return null;
  DateTime? end;
  final m = RegExp(r'notAfter=(\w{3})\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d{4})').firstMatch(out);
  if (m != null && _months[m[1]] != null) {
    end = DateTime.utc(int.parse(m[6]!), _months[m[1]]!, int.parse(m[2]!), int.parse(m[3]!), int.parse(m[4]!));
  }
  return SigningCert(name: cn, teamId: ou, expires: end, hasPrivateKey: identityNames.contains(cn));
}

/// `security find-identity -v -p codesigning`에서 유효한 인증서 이름들.
Set<String> parseIdentityNames(String out) => {for (final m in RegExp(r'"([^"]+)"').allMatches(out)) m[1]!};

/// `security cms -D -i profile.mobileprovision`의 XML plist에서 필요한 값만 읽는다.
ProfileInfo? parseProfileXml(String xml) {
  String? value(String key, String tag) => RegExp('<key>$key</key>\\s*<$tag>([^<]*)</$tag>').firstMatch(xml)?[1];
  final appId = value('application-identifier', 'string');
  final team = RegExp(r'<key>TeamIdentifier</key>\s*<array>\s*<string>([^<]*)</string>').firstMatch(xml)?[1];
  if (appId == null || team == null) return null;
  final devices = RegExp(r'<key>ProvisionedDevices</key>\s*<array>(.*?)</array>', dotAll: true).firstMatch(xml);
  return ProfileInfo(
    name: value('Name', 'string') ?? appId,
    appId: appId,
    teamId: team,
    created: DateTime.tryParse(value('CreationDate', 'date') ?? ''),
    expires: DateTime.tryParse(value('ExpirationDate', 'date') ?? ''),
    deviceCount: devices == null ? null : '<string>'.allMatches(devices[1]!).length,
  );
}

/// `android/key.properties`의 `storeFile` 값.
String? parseKeyPropertiesStoreFile(String text) =>
    RegExp(r'^\s*storeFile\s*=\s*(.+?)\s*$', multiLine: true).firstMatch(text)?[1];
