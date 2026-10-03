// M3b tests: discovery query/reply codec and loopback scan.
// Run with: flutter test (requires Flutter SDK).

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/network/discovery.dart';

/// Builds a reply exactly per spec (not via the encoder under test).
Uint8List _specReply(int port, String name) {
  final List<int> nameBytes = utf8.encode(name);
  final Uint8List out = Uint8List(7 + nameBytes.length);
  out.setRange(0, 4, <int>[0x50, 0x4C, 0x64, 0x73]);
  out[4] = 0x01;
  out[5] = port & 0xFF;
  out[6] = (port >> 8) & 0xFF;
  out.setRange(7, 7 + nameBytes.length, nameBytes);
  return out;
}

void main() {
  test('query is 5 bytes PLds v1', () {
    expect(
      encodeDiscoveryQuery(),
      <int>[0x50, 0x4C, 0x64, 0x73, 0x01],
    );
  });

  test('reply decodes spec-built bytes', () {
    final ({int port, String name})? reply =
        tryDecodeDiscoveryReply(_specReply(9876, 'laptop'));
    expect(reply, isNotNull);
    expect(reply!.port, 9876);
    expect(reply.name, 'laptop');
  });

  test('reply rejects malformed datagrams', () {
    expect(tryDecodeDiscoveryReply(Uint8List(0)), isNull);
    expect(tryDecodeDiscoveryReply(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7])),
        isNull);
    final Uint8List badVersion = _specReply(9876, 'x')..[4] = 0x02;
    expect(tryDecodeDiscoveryReply(badVersion), isNull);
  });

  test('servers compare by ip and port only', () {
    const DiscoveredServer a =
        DiscoveredServer(ip: '1.2.3.4', port: 5, name: 'one');
    const DiscoveredServer b =
        DiscoveredServer(ip: '1.2.3.4', port: 5, name: 'two');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('scan finds a loopback responder', () async {
    final RawDatagramSocket responder =
        await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final int responderPort = responder.port;
    final StreamSubscription<void> sub = responder.listen((RawSocketEvent e) {
      if (e != RawSocketEvent.read) return;
      final Datagram? dg = responder.receive();
      if (dg == null || dg.data.length != 5) return;
      responder.send(
        _specReply(9876, 'testbox'),
        dg.address,
        dg.port,
      );
    });

    final DiscoveryService service = DiscoveryService(
      port: responderPort,
      scanDuration: const Duration(milliseconds: 300),
    );
    await service.scan(target: '127.0.0.1');
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(service.scanning.value, isFalse);
    expect(service.servers.value, hasLength(1));
    expect(service.servers.value.single.ip, '127.0.0.1');
    expect(service.servers.value.single.port, 9876);
    expect(service.servers.value.single.name, 'testbox');

    service.dispose();
    await sub.cancel();
    responder.close();
  });
}
