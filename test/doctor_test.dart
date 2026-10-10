import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/devices/mobile_device.dart';
import 'package:flutty_dock/doctor/checks.dart';
import 'package:flutty_dock/doctor/diagnostics.dart';
import 'package:flutty_dock/doctor/signing_info.dart';
import 'package:flutty_dock/flutter/flutter_project.dart';

final _now = DateTime.utc(2026, 10, 10);

const _opensslOut = '''
subject=C=US,O=Jong Yun Ahn,OU=6N35L95QS4,CN=Apple Development: Jong Yun Ahn (X43N8U2QSG),UID=M3KVLX4862
notAfter=Sep 15 12:56:57 2027 GMT
''';

const _identities = '''
  1) FE16 "Apple Development: Jong Yun Ahn (X43N8U2QSG)"
  2) F8C4 "Apple Distribution: Jong Yun Ahn (6N35L95QS4)"
     2 valid identities found
''';

String _profile({
  String appId = '6N35L95QS4.art.zoomon.app',
  String created = '2026-10-05T00:00:00Z',
  String expires = '2027-10-05T00:00:00Z',
}) =>
    '''
<dict>
  <key>CreationDate</key><date>$created</date>
  <key>ExpirationDate</key><date>$expires</date>
  <key>Name</key><string>iOS Team Provisioning Profile: app</string>
  <key>ProvisionedDevices</key>
  <array><string>A</string><string>B</string><string>C</string></array>
  <key>TeamIdentifier</key>
  <array><string>6N35L95QS4</string></array>
  <key>Entitlements</key>
  <dict><key>application-identifier</key><string>$appId</string></dict>
</dict>''';

const _usb = MobileDevice(
  id: 'U',
  name: 'iPhone',
  platform: DevicePlatform.ios,
  link: DeviceLink.usb,
  developerModeOn: true,
);
const _project = FlutterProject(path: '/p', name: 'app', hasIos: true, hasAndroid: true, iosBundleId: 'art.zoomon.app');

Diagnostics _diag({
  List<SigningCert> certs = const [],
  List<ProfileInfo> profiles = const [],
  AndroidSigning? android,
  ToolInfo flutter = const ToolInfo('3.47.1'),
  ToolInfo xcode = const ToolInfo('27.0'),
  ToolInfo adb = const ToolInfo('1.0.41'),
}) => Diagnostics(
  flutter: flutter,
  xcode: xcode,
  adb: adb,
  certs: certs,
  profiles: profiles,
  androidSigning: android,
  collectedAt: _now,
);

List<CheckItem> _checks(Diagnostics d, {MobileDevice? device = _usb, String? team = '6N35L95QS4'}) =>
    buildChecks(diagnostics: d, project: _project, device: device, teamId: team, hostIsMac: true, now: _now);

CheckStatus _status(List<CheckItem> items, CheckId id) => items.firstWhere((i) => i.id == id).status;

void main() {
  group('signing parsers', () {
    test('openssl output → cert with team, expiry and private key', () {
      final names = parseIdentityNames(_identities);
      expect(names, contains('Apple Development: Jong Yun Ahn (X43N8U2QSG)'));
      final c = parseOpenSslCert(_opensslOut, identityNames: names)!;
      expect(c.name, 'Apple Development: Jong Yun Ahn (X43N8U2QSG)');
      expect(c.teamId, '6N35L95QS4');
      expect(c.hasPrivateKey, isTrue);
      expect(c.expires, DateTime.utc(2027, 9, 15, 12, 56));
      expect(c.daysLeft(_now), greaterThan(300));
      expect(parseOpenSslCert(_opensslOut)!.hasPrivateKey, isFalse);
    });

    test('splitPems', () {
      const pem = '-----BEGIN CERTIFICATE-----\nAAA\n-----END CERTIFICATE-----\n';
      expect(splitPems(pem + pem), hasLength(2));
    });

    test('profile xml, wildcard matching and the 7-day free-account lifetime', () {
      final p = parseProfileXml(_profile())!;
      expect(p.appId, '6N35L95QS4.art.zoomon.app');
      expect(p.teamId, '6N35L95QS4');
      expect(p.deviceCount, 3);
      expect(p.isShortLived, isFalse);
      expect(p.matches('art.zoomon.app'), isTrue);
      expect(p.matches('art.zoomon.other'), isFalse);
      expect(parseProfileXml(_profile(appId: '6N35L95QS4.*'))!.matches('any.bundle'), isTrue);
      expect(parseProfileXml(_profile(appId: '6N35L95QS4.art.*'))!.matches('art.zoomon.x'), isTrue);
      final free = parseProfileXml(_profile(created: '2026-10-08T00:00:00Z', expires: '2026-10-15T00:00:00Z'))!;
      expect(free.isShortLived, isTrue);
      expect(free.daysLeft(_now), 5);
    });

    test('key.properties storeFile', () {
      expect(parseKeyPropertiesStoreFile('storePassword=x\nstoreFile=../upload.jks\n'), '../upload.jks');
      expect(parseKeyPropertiesStoreFile('storePassword=x'), isNull);
    });
  });

  group('uniqueCerts', () {
    SigningCert cert(String name, {String team = 'T', int days = 100, bool key = true}) => SigningCert(
      name: name,
      teamId: team,
      expires: _now.add(Duration(days: days)),
      hasPrivateKey: key,
    );

    test('same name and team collapse to the one expiring last', () {
      final merged = uniqueCerts([cert('A', days: 340), cert('A', days: 344)]);
      expect(merged, hasLength(1));
      expect(merged.single.daysLeft(_now), 344);
    });

    test('a certificate with a private key beats a later one without', () {
      final merged = uniqueCerts([cert('A', days: 100), cert('A', days: 300, key: false)]);
      expect(merged.single.hasPrivateKey, isTrue);
      expect(merged.single.daysLeft(_now), 100);
    });

    test('different names or teams stay separate, in first-seen order', () {
      final merged = uniqueCerts([cert('B'), cert('A'), cert('B', days: 200), cert('A', team: 'OTHER')]);
      expect(merged.map((c) => '${c.name}/${c.teamId}'), ['B/T', 'A/T', 'A/OTHER']);
      expect(merged.first.daysLeft(_now), 200);
    });

    test('certificate checks list a duplicated certificate once', () {
      final items = _checks(
        _diag(certs: [cert('Apple Development: A', days: 340), cert('Apple Development: A', days: 344)]),
      );
      expect(items.where((i) => i.id == CheckId.certificateExpiry), hasLength(1));
      expect(items.firstWhere((i) => i.id == CheckId.certificate).params['count'], '1');
    });
  });

  group('buildChecks', () {
    final cert = SigningCert(
      name: 'Apple Development: A (X)',
      teamId: '6N35L95QS4',
      expires: DateTime.utc(2027, 9, 15),
      hasPrivateKey: true,
    );

    test('a healthy setup has no failures', () {
      final items = _checks(
        _diag(certs: [cert], profiles: [parseProfileXml(_profile())!], android: AndroidSigning.keystore),
      );
      expect(items.where((i) => i.status == CheckStatus.fail), isEmpty);
      expect(firstProblem(items), isNull);
      expect(_status(items, CheckId.profile), CheckStatus.ok);
    });

    test('missing tools and certificate fail; adb is only a warning', () {
      final items = _checks(
        _diag(flutter: const ToolInfo(null), xcode: const ToolInfo(null), adb: const ToolInfo(null)),
      );
      expect(_status(items, CheckId.flutter), CheckStatus.fail);
      expect(_status(items, CheckId.xcode), CheckStatus.fail);
      expect(_status(items, CheckId.adb), CheckStatus.warn);
      expect(_status(items, CheckId.certificate), CheckStatus.fail);
      expect(firstProblem(items)!.id, CheckId.flutter);
    });

    test('certificate expiry: warn within 30 days, fail once expired', () {
      SigningCert expiring(int days) => SigningCert(
        name: 'n',
        teamId: 'T',
        expires: _now.add(Duration(days: days)),
        hasPrivateKey: true,
      );
      expect(_status(_checks(_diag(certs: [expiring(10)])), CheckId.certificateExpiry), CheckStatus.warn);
      expect(_status(_checks(_diag(certs: [expiring(-1)])), CheckId.certificateExpiry), CheckStatus.fail);
    });

    test('team: missing fails, one that no certificate covers warns', () {
      expect(_status(_checks(_diag(certs: [cert]), team: null), CheckId.team), CheckStatus.fail);
      expect(_status(_checks(_diag(certs: [cert]), team: 'OTHERTEAM1'), CheckId.team), CheckStatus.warn);
    });

    test('profile: none is just info; a free-account profile close to expiry warns', () {
      expect(_status(_checks(_diag(certs: [cert])), CheckId.profile), CheckStatus.info);
      final soon = parseProfileXml(_profile(created: '2026-10-05T00:00:00Z', expires: '2026-10-12T00:00:00Z'))!;
      final items = _checks(_diag(certs: [cert], profiles: [soon]));
      expect(_status(items, CheckId.profile), CheckStatus.warn);
      expect(items.firstWhere((i) => i.id == CheckId.profile).params['short'], 'true');
    });

    test('device checks', () {
      const wireless = MobileDevice(
        id: 'W',
        name: 'W',
        platform: DevicePlatform.ios,
        link: DeviceLink.wireless,
        developerModeOn: false,
      );
      final items = _checks(_diag(certs: [cert]), device: wireless);
      expect(_status(items, CheckId.connection), CheckStatus.fail);
      expect(_status(items, CheckId.developerMode), CheckStatus.fail);
      const unauth = MobileDevice(
        id: 'A',
        name: 'A',
        platform: DevicePlatform.android,
        link: DeviceLink.usb,
        authorized: false,
      );
      expect(_status(_checks(_diag(), device: unauth), CheckId.androidAuth), CheckStatus.fail);
    });

    test('android signing modes', () {
      expect(_status(_checks(_diag(android: AndroidSigning.debugKey)), CheckId.androidSigning), CheckStatus.info);
      expect(
        _status(_checks(_diag(android: AndroidSigning.keystoreMissing)), CheckId.androidSigning),
        CheckStatus.fail,
      );
    });

    test('nothing to check before diagnostics ran', () {
      expect(
        buildChecks(diagnostics: null, project: _project, device: _usb, teamId: null, hostIsMac: true, now: _now),
        isEmpty,
      );
    });
  });
}
