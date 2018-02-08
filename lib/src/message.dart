import 'package:collection/collection.dart';
import 'package:osc/src/convert.dart';

class OSCMessage {
  final String address;
  final List<Object> arguments;

  final _builder = new OSCMessageBuilder();

  OSCMessage(this.address, {this.arguments}) {
    if (!_isValid(address)) {
      throw new ArgumentError('Invalid address: $address');
    }

    _builder.addAddress(address);
    _builder.addArguments(arguments);
  }

  factory OSCMessage.fromBytes(List<int> bytes) =>
      new OSCMessageParser(bytes).parse();

  @override
  bool operator ==(o) =>
      o is OSCMessage &&
      o.address == address &&
      const IterableEquality().equals(o.arguments, arguments);

  @override
  int get hashCode =>
      address.hashCode ^ const IterableEquality().hash(arguments);

  @override
  String toString() => 'OSCMesssage($address, args: $arguments)';

  List<int> toBytes() => _builder.toBytes();
}

//' ', '#', '*', ',', '?', '[', ']', '{', '}'
final _illegalAddressChars = new RegExp('[#*,?]');

bool _isValid(String address) =>
    address != null &&
    address.isNotEmpty &&
    address[0] == '/' &&
    !_illegalAddressChars.hasMatch(address);
