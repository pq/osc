import 'dart:io';

import '../osc.dart';

class OSCSocket {
  final InternetAddress _address;
  final int port;

  RawDatagramSocket _socket;

  OSCSocket({String address, this.port})
      : _address = address != null
            ? InternetAddress(address)
            : InternetAddress.loopbackIPv4;

  InternetAddress get address => _address;

  void close() {
    _socket?.close();
  }

  void listen(void Function(OSCMessage msg) onData) {
    RawDatagramSocket.bind(address, port).then((socket) {
      _socket = socket;
      _socket.listen((e) {
        final datagram = socket.receive();
        if (datagram != null) {
          final msg = OSCMessage.fromBytes(datagram.data);
          onData(msg);
        }
      });
    });
  }

  Future<int> send(OSCMessage msg) {
    return RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
      return socket.send(msg.toBytes(), address, port);
    });
  }
}
