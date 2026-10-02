// LAN server discovery (M3b). The app broadcasts a 5-byte query;
// each server replies directly with its input port and hostname.
// Layout mirrors server/protocol.py discovery section.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'packet.dart';

/// A server found on the local network.
@immutable
class DiscoveredServer {
  final String ip;
  final int port;
  final String name;

  const DiscoveredServer({
    required this.ip,
    required this.port,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      other is DiscoveredServer && other.ip == ip && other.port == port;

  @override
  int get hashCode => Object.hash(ip, port);

  @override
  String toString() => 'DiscoveredServer($name $ip:$port)';
}

Uint8List encodeDiscoveryQuery() {
  return Uint8List.fromList([0x50, 0x4C, 0x64, 0x73, 0x01]); // 'PLds' + v1
}

/// Parses a discovery reply into (port, name), or null when malformed.
({int port, String name})? tryDecodeDiscoveryReply(Uint8List data) {
  if (data.length < 7) return null;
  if (data[0] != 0x50 || data[1] != 0x4C || data[2] != 0x64 || data[3] != 0x73) {
    return null;
  }
  if (data[4] != 0x01) return null;
  final int port = data[5] | (data[6] << 8);
  final String name = utf8.decode(data.sublist(7), allowMalformed: true);
  return (port: port, name: name);
}

/// Broadcasts discovery queries for [scanDuration] and collects replies.
class DiscoveryService {
  final int port;
  final Duration scanDuration;

  /// Unique servers seen during the current scan, in arrival order.
  final ValueNotifier<List<DiscoveredServer>> servers =
      ValueNotifier<List<DiscoveredServer>>(const []);

  /// True while a scan is running.
  final ValueNotifier<bool> scanning = ValueNotifier<bool>(false);

  RawDatagramSocket? _socket;
  Timer? _stopTimer;
  Timer? _repeatTimer;

  DiscoveryService({
    this.port = kDefaultPort,
    this.scanDuration = const Duration(seconds: 3),
  });

  /// Address to send the query to. Production uses the LAN broadcast;
  /// tests point it at loopback.
  Future<void> scan({String target = '255.255.255.255'}) async {
    if (scanning.value) return;
    final RawDatagramSocket socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket = socket;
    try {
      socket.broadcastEnabled = true;
    } catch (_) {
      // Some platforms disallow the flag; unicast targets still work.
    }
    servers.value = const [];
    scanning.value = true;
    socket.listen(_onEvent);
    _sendQuery(target);
    // Repeat halfway so slow hosts still answer within the window.
    _repeatTimer = Timer(scanDuration ~/ 2, () => _sendQuery(target));
    _stopTimer = Timer(scanDuration, stop);
  }

  void _sendQuery(String target) {
    try {
      _socket?.send(
        encodeDiscoveryQuery(),
        InternetAddress(target),
        port,
      );
    } catch (_) {
      // Unreachable broadcast domain: keep listening, then time out.
    }
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final Datagram? datagram = _socket?.receive();
    if (datagram == null) return;
    final ({int port, String name})? reply =
        tryDecodeDiscoveryReply(datagram.data);
    if (reply == null) return;
    final DiscoveredServer found = DiscoveredServer(
      ip: datagram.address.address,
      port: reply.port,
      name: reply.name,
    );
    if (!servers.value.contains(found)) {
      servers.value = [...servers.value, found];
    }
  }

  void stop() {
    _stopTimer?.cancel();
    _stopTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _socket?.close();
    _socket = null;
    scanning.value = false;
  }

  void dispose() {
    stop();
    servers.dispose();
    scanning.dispose();
  }
}
