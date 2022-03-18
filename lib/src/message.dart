// Copyright (c) 2021, Google LLC. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import 'convert.dart';

final _illegalAddressChars = RegExp('[#*,?]');

//' ', '#', '*', ',', '?', '[', ']', '{', '}'
bool _isValid(String address) =>
    address.isNotEmpty &&
    address[0] == '/' &&
    !_illegalAddressChars.hasMatch(address);

class OSCMessage {
  final String address;
  final List<Object> arguments;

  final _builder = OSCMessageBuilder();

  OSCMessage(this.address, {required this.arguments}) {
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
  bool operator ==(other) =>
      other is OSCMessage &&
      other.address == address &&
      const IterableEquality().equals(other.arguments, arguments);

  List<int> toBytes() => _builder.toBytes();

  @override
  String toString() => 'OSCMesssage($address, args: $arguments)';
}
