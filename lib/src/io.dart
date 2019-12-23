import 'dart:io';

import '../osc.dart';

class OSCSocket {
  final InternetAddress _address;
  final int port;

  RawDatagramSocket _receiveSocket;
  RawDatagramSocket _sendSocket;

  OSCSocket({String address, this.port})
      : _address = address != null
            ? InternetAddress(address)
            : InternetAddress.loopbackIPv4;

  InternetAddress get address => _address;

  void close() {
    _receiveSocket?.close();
    _sendSocket?.close();
  }

  Future<void> listen(void Function(OSCMessage msg) onData) async {
    _receiveSocket ??= await RawDatagramSocket.bind(address, port);
    _receiveSocket.listen((e) {
      final datagram = _receiveSocket.receive();
      if (datagram != null) {
        final msg = OSCMessage.fromBytes(datagram.data);
        onData(msg);
      }
    });
  }

  Future<int> send(OSCMessage msg) async {
    _sendSocket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    return _sendSocket.send(msg.toBytes(), address, port);
  }
}
