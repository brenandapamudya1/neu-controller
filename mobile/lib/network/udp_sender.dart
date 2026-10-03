// Fixed-rate UDP sender. Reads ControllerState at 60 Hz and sends
// one full-state packet. Never sends per input event.

import 'dart:async';
import 'dart:io';

import '../core/input_state.dart';
import 'packet.dart';

class UdpSender {
  final ControllerState state;
  final String host;
  final int port;

  RawDatagramSocket? _socket;
  Timer? _timer;
  int _seq = 0;

  UdpSender({required this.state, required this.host, this.port = kDefaultPort});

  Future<void> start() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    // 60 Hz fixed rate.
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final snapshot = state.value.copyWith(seq: _seq);
      _seq = (_seq + 1) & 0xFFFF;
      final packet = encodePacket(snapshot);
      _socket?.send(packet, InternetAddress(host), port);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
  }
}
