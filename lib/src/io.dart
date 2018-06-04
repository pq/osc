import 'dart:io';

import 'package:osc/osc.dart';

class OSCSocket {
  final InternetAddress host;
  final int port;

  RawDatagramSocket _socket;

  OSCSocket({String host: '127.0.0.1', this.port})
      : host = new InternetAddress(host);

  void listen(void onData(OSCMessage msg)) {
    RawDatagramSocket.bind(host, port).then((socket) {
      _socket = socket;
      _socket.listen((e) {
        final datagram = socket.receive();
        if (datagram != null) {
          final msg = new OSCMessage.fromBytes(datagram.data);
          onData(msg);
        }
      });
    });
  }

  void close() {
    _socket?.close();
  }
}
