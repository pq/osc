import 'dart:io';

import '../osc.dart';

class OSCSocket {
  final InternetAddress destination;
  final int destinationPort;

  final InternetAddress serverAddress;
  final int serverPort;

  InternetAddress lastMessageAddress;
  int lastMessagePort;

  RawDatagramSocket _socket;

  OSCSocket({
    this.destination,
    this.destinationPort,
    this.serverAddress,
    this.serverPort,
  });

  void close() {
    _socket?.close();
  }

  Future<RawDatagramSocket> setupSocket() async {
    var address = serverAddress ?? InternetAddress.anyIPv4;
    var port = serverPort ?? 0;
    return RawDatagramSocket.bind(address, port);
  }

  /// RawDatagramSockets don't support onDone, onError callbacks
  /// because UDP has no concept of a "connection" that can be closed.
  Future<void> listen(void Function(OSCMessage msg) onData) async {
    _socket ??= await setupSocket();

    _socket.listen((e) {
      final datagram = _socket.receive();
      if (datagram != null) {
        lastMessageAddress = datagram.address;
        lastMessagePort = datagram.port;
        final msg = OSCMessage.fromBytes(datagram.data);
        onData(msg);
      }
    });
  }

  Future<int> send(OSCMessage msg) async {
    _socket ??= await setupSocket();
    var to = destination ?? lastMessageAddress;
    var port = destinationPort ?? lastMessagePort;

    if (to == null || port == null) return 0;
    return _socket.send(msg.toBytes(), to, port);
  }

  Future<int> reply(OSCMessage msg) async {
    _socket ??= await setupSocket();
    if (lastMessageAddress == null || lastMessagePort == null) return 0;
    return _socket.send(msg.toBytes(), lastMessageAddress, lastMessagePort);
  }
}
