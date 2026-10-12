import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutty_dock/core/command_runner.dart';

void main() {
  test('UTF-8 출력은 그대로 읽는다', () {
    expect(decodeProcessOutput(utf8.encode('한글 ok')), '한글 ok');
  });

  test('UTF-8이 아니면 대체 코덱으로 읽는다', () {
    expect(decodeProcessOutput([0xE9, 0x61], fallback: latin1), 'éa');
  });
}
