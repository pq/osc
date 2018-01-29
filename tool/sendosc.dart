import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:osc/src/convert.dart';
import 'package:osc/src/message.dart';

void main(List<String> args) {
  final destination = new InternetAddress(args[0]);
  final port = int.parse(args[1]);

  final address = args[2];

  final arguments = <Object>[];
  for (var i = 3; i < args.length; i += 2) {
    arguments.add(DataCodec.forType(args[i]).toValue(args[i + 1]));
  }

  final message = new OSCMessage(address, arguments: arguments);

  RawDatagramSocket.bind(InternetAddress.ANY_IP_V4, 0).then((socket) {
    final greenPen = new AnsiPen()..green(bold: true);
    final yellowPen = new AnsiPen()..xterm(003);

    print(
        yellowPen('Sending from ${socket.address.address}:${socket.port}...'));

    final bytes = message.toBytes();
    socket.send(bytes, destination, port);
    print(greenPen('$bytes'));
  });
}
