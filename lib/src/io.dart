import 'dart:io';

import 'package:osc/osc.dart';

class OSCSocket {
  final InternetAddress _host;
  final int port;

  RawDatagramSocket _socket;

  OSCSocket({String host, this.port})
      : _host = host != null
            ? new InternetAddress(host)
            : InternetAddress.loopbackIPv4;

  InternetAddress get host => _host;

  void close() {
    _socket?.close();
  }

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
}
