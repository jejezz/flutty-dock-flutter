import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_log.dart';
import 'package:flutty_dock/core/gh_client.dart';
import 'package:flutty_dock/l10n/app_localizations.dart';
import 'package:flutty_dock/secrets/release_secrets.dart';
import 'package:flutty_dock/secrets/secrets_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGh implements GhClient {
  GhStatus statusValue = GhStatus.ready;
  Map<String, DateTime?>? secrets = {'APPLE_ID': DateTime(2026, 10, 1)};
  final sets = <(String, String, String)>[];

  @override
  Future<GhStatus> status() async => statusValue;

  @override
  Future<Map<String, DateTime?>?> listSecrets(String repo) async => secrets;

  @override
  Future<CommandResult> setSecret(String repo, String name, String value) async {
    sets.add((repo, name, value));
    secrets = {...?secrets, name: DateTime(2026, 10, 10)};
    return const CommandResult(0, '', '');
  }

  @override
  Future<String?> repoFromFolder(String directory) async => 'jejezz/demo';
}

Widget _app(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

Future<void> _pump(WidgetTester tester, _FakeGh gh) async {
  // 목록이 느리게 만들어지므로 여섯 카드가 모두 보이게 창을 키운다.
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(SecretsScreen(client: gh, log: CommandLog())));
  await tester.pumpAndSettle();
}

void main() {
  group('pure helpers', () {
    test('release secrets are the six macOS ones, in README order', () {
      expect(macosReleaseSecrets.map((s) => s.name), [
        'MACOS_CERTIFICATE_P12_BASE64',
        'MACOS_CERTIFICATE_PASSWORD',
        'MACOS_KEYCHAIN_PASSWORD',
        'APPLE_ID',
        'APPLE_ID_PASSWORD',
        'APPLE_TEAM_ID',
      ]);
    });

    test('validateSecret', () {
      SecretSpec spec(String n) => macosReleaseSecrets.firstWhere((s) => s.name == n);
      expect(validateSecret(spec('APPLE_ID'), ''), SecretIssue.empty);
      expect(validateSecret(spec('APPLE_ID'), 'nope'), SecretIssue.notEmail);
      expect(validateSecret(spec('APPLE_ID'), 'a@b.co'), isNull);
      expect(validateSecret(spec('APPLE_TEAM_ID'), '6n35l95qs4'), SecretIssue.badTeamId);
      expect(validateSecret(spec('APPLE_TEAM_ID'), '6N35L95QS4'), isNull);
      expect(validateSecret(spec('MACOS_CERTIFICATE_PASSWORD'), 'x'), isNull);
    });

    test('generatePassword is 32 alphanumerics and differs each time', () {
      final a = generatePassword();
      expect(a, matches(RegExp(r'^[A-Za-z0-9]{32}$')));
      expect(generatePassword(), isNot(a));
    });

    test('repo parsing and the shown command never contain a value', () {
      expect(isValidRepo('jejezz/flutty-dock-flutter'), isTrue);
      expect(isValidRepo('jejezz'), isFalse);
      expect(isValidRepo('a b/c'), isFalse);
      expect(parseGithubRepo('https://github.com/jejezz/flutty-dock-flutter.git'), 'jejezz/flutty-dock-flutter');
      expect(parseGithubRepo('git@github.com:jejezz/flutty-dock-flutter.git'), 'jejezz/flutty-dock-flutter');
      expect(parseGithubRepo('https://gitlab.com/a/b'), isNull);
      expect(formatCommandLine(secretSetArgs('o/r', 'APPLE_ID')), 'gh secret set APPLE_ID --repo o/r');
    });

    test('parseSecretList reads gh --json output', () {
      final m = parseSecretList('[{"name":"A","updatedAt":"2026-10-01T00:00:00Z"},{"name":"B","updatedAt":""}]');
      expect(m.keys, ['A', 'B']);
      expect(m['A'], isNotNull);
      expect(m['B'], isNull);
    });
  });

  group('SecretsScreen', () {
    setUp(() => SharedPreferences.setMockInitialValues({'secrets_repo': 'jejezz/demo'}));

    testWidgets('shows the six secrets and which are registered', (tester) async {
      await _pump(tester, _FakeGh());
      for (final s in macosReleaseSecrets) {
        expect(find.text(s.name), findsOneWidget);
      }
      expect(find.textContaining('Registered'), findsOneWidget);
      expect(find.text('Not registered'), findsNWidgets(5));
    });

    testWidgets('rejects a bad Team ID and registers a valid one via the client', (tester) async {
      final gh = _FakeGh();
      await _pump(tester, gh);

      final teamField = find.byType(TextField).last;
      final teamButton = find.widgetWithText(FilledButton, 'Register').last;

      await tester.enterText(teamField, 'abc');
      await tester.tap(teamButton);
      await tester.pumpAndSettle();
      expect(find.text('A Team ID is 10 uppercase letters or digits'), findsOneWidget);
      expect(gh.sets, isEmpty);

      await tester.enterText(teamField, '6N35L95QS4');
      await tester.tap(teamButton);
      await tester.pumpAndSettle();
      expect(gh.sets, [('jejezz/demo', 'APPLE_TEAM_ID', '6N35L95QS4')]);
      // 등록하면 입력란을 비운다.
      expect(tester.widget<TextField>(teamField).controller!.text, isEmpty);
    });

    testWidgets('asks before overwriting a registered secret', (tester) async {
      final gh = _FakeGh();
      await _pump(tester, gh);

      // APPLE_ID 입력란: 텍스트 필드 순서는 repo, MACOS_CERTIFICATE_PASSWORD, APPLE_ID, APPLE_ID_PASSWORD, APPLE_TEAM_ID.
      await tester.enterText(find.byType(TextField).at(2), 'me@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Overwrite'));
      await tester.pumpAndSettle();
      expect(find.text('Overwrite APPLE_ID?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(gh.sets, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Overwrite'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Overwrite')));
      await tester.pumpAndSettle();
      expect(gh.sets, [('jejezz/demo', 'APPLE_ID', 'me@example.com')]);
    });

    testWidgets('tells how to fix gh when it is missing', (tester) async {
      final gh = _FakeGh()..statusValue = GhStatus.notInstalled;
      await _pump(tester, gh);
      expect(find.text('brew install gh'), findsOneWidget);
    });
  });
}
