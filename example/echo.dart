import 'package:ansicolor/ansicolor.dart';
import 'package:osc/osc.dart';

const int defaultPort = 4440;

/// simple echo server; useful for testing.
void main(List<String> args) {
  final port = args.length == 1 ? int.parse(args[0]) : defaultPort;
  final greenPen = AnsiPen()..green(bold: true);
  final bluePen = AnsiPen()..blue(bold: true);
  final grayPen = AnsiPen()..gray(level: 0.5);

  print(greenPen('echo osc listening on port $port... (^C to quit)'));

  final socket = OSCSocket(port: port);
  socket.listen(
      (msg) => print("${grayPen('received:')} ${bluePen(msg.toString())}"));
}
