// M3a tests: ping probe encoding and pong parsing (no sockets).
// Run with: flutter test (requires Flutter SDK).

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/network/packet.dart';

void main() {
  test('ping layout is 12 bytes with PLpg magic', () {
    final Uint8List bytes = encodePing(42);
    expect(bytes.length, kPingSize);
    expect(bytes.sublist(0, 4), <int>[0x50, 0x4C, 0x70, 0x67]);
  });

  test('pong round-trips the nonce', () {
    for (final int nonce in <int>[0, 1, 123456789, 0x7FFFFFFFFFFFFFFF]) {
      expect(tryDecodePong(encodePing(nonce)), nonce);
    }
  });

  test('pong rejects malformed datagrams', () {
    expect(tryDecodePong(Uint8List(0)), isNull);
    expect(tryDecodePong(Uint8List(kPingSize)), isNull); // zero magic
    expect(tryDecodePong(Uint8List.fromList(List.filled(13, 0x50))), isNull);
  });
}
