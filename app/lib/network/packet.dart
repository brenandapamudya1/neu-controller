// v1 packet encoder. Must stay in sync with server/protocol.py.
// Little-endian, 13 bytes: magic(2) version(1) seq(u16) buttons(u16)
// l2(u8) r2(u8) lx(i8) ly(i8) rx(i8) ry(i8).

import 'dart:typed_data';

import '../core/input_state.dart';

const int kPacketSize = 13;
const int kProtocolVersion = 1;
const int kDefaultPort = 9876;

Uint8List encodePacket(InputState state) {
  final bytes = ByteData(kPacketSize);
  bytes.setUint8(0, 0x50); // 'P'
  bytes.setUint8(1, 0x4C); // 'L'
  bytes.setUint8(2, kProtocolVersion);
  bytes.setUint16(3, state.seq & 0xFFFF, Endian.little);
  bytes.setUint16(5, state.buttons & 0xFFFF, Endian.little);
  bytes.setUint8(7, state.l2.clamp(0, 255));
  bytes.setUint8(8, state.r2.clamp(0, 255));
  bytes.setInt8(9, state.lx.clamp(-127, 127));
  bytes.setInt8(10, state.ly.clamp(-127, 127));
  bytes.setInt8(11, state.rx.clamp(-127, 127));
  bytes.setInt8(12, state.ry.clamp(-127, 127));
  return bytes.buffer.asUint8List();
}
