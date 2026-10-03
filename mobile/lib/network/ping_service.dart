// Measures UDP round-trip to the server and exposes it as [rttMs].
// Probes once per [interval]; null means no reply within [timeout]
// (disconnected). Own socket, independent from UdpSender.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'packet.dart';

class PingService {
  final String host;
  final int port;
  final Duration interval;
  final Duration timeout;

  /// Last measured round-trip in ms, or null when unreachable.
  final ValueNotifier<int?> rttMs = ValueNotifier<int?>(null);

  RawDatagramSocket? _socket;
  Timer? _timer;
  final Random _random = Random();
  final Map<int, int> _sentAt = {}; // nonce -> epoch ms
  int _lastReplyAt = 0;

  PingService({
    required this.host,
    required this.port,
    this.interval = const Duration(seconds: 1),
    this.timeout = const Duration(milliseconds: 1500),
  });

  Future<void> start() async {
    final RawDatagramSocket socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket = socket;
    socket.listen(_onEvent);
    _ping();
    _timer = Timer.periodic(interval, (_) => _ping());
  }

  void _ping() {
    final RawDatagramSocket? socket = _socket;
    if (socket == null) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastReplyAt > timeout.inMilliseconds) {
      rttMs.value = null;
    }
    _sentAt.removeWhere((_, int sent) => now - sent > timeout.inMilliseconds);
    // 64-bit nonce from two 32-bit draws.
    final int nonce =
        (_random.nextInt(1 << 32) << 32) | _random.nextInt(1 << 32);
    _sentAt[nonce] = now;
    socket.send(encodePing(nonce), InternetAddress(host), port);
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final Datagram? datagram = _socket?.receive();
    if (datagram == null) return;
    final int? nonce = tryDecodePong(datagram.data);
    if (nonce == null) return;
    final int? sent = _sentAt.remove(nonce);
    if (sent == null) return; // unknown or already timed out
    _lastReplyAt = DateTime.now().millisecondsSinceEpoch;
    rttMs.value = _lastReplyAt - sent;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
    _sentAt.clear();
  }

  void dispose() {
    stop();
    rttMs.dispose();
  }
}
