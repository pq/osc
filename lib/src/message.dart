import 'package:collection/collection.dart';
import 'package:osc/src/convert.dart';

final _illegalAddressChars = RegExp('[#*,?]');

//' ', '#', '*', ',', '?', '[', ']', '{', '}'
bool _isValid(String address) =>
    address != null &&
    address.isNotEmpty &&
    address[0] == '/' &&
    !_illegalAddressChars.hasMatch(address);

class OSCMessage {
  final String address;
  final List<Object> arguments;

  final _builder = OSCMessageBuilder();

  OSCMessage(this.address, {this.arguments}) {
    if (!_isValid(address)) {
      throw ArgumentError('Invalid address: $address');
    }

    _builder.addAddress(address);
    _builder.addArguments(arguments);
  }

  factory OSCMessage.fromBytes(List<int> bytes) =>
      OSCMessageParser(bytes).parse();

  @override
  int get hashCode =>
      address.hashCode ^ const IterableEquality().hash(arguments);

  @override
  bool operator ==(o) =>
      o is OSCMessage &&
      o.address == address &&
      const IterableEquality().equals(o.arguments, arguments);

  List<int> toBytes() => _builder.toBytes();

  @override
  String toString() => 'OSCMesssage($address, args: $arguments)';
}
