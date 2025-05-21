// Copyright (c) 2021, Google LLC. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'message.dart';

const BlobCodec blobCodec = BlobCodec();

const FloatCodec floatCodec = FloatCodec();

const DoubleCodec doubleCodec = DoubleCodec();

const IntCodec intCodec = IntCodec();

const OSCMessageCodec oscMessageCodec = OSCMessageCodec();

const StringCodec stringCodec = StringCodec();

abstract class DataCodec<T> extends Codec<T, List<int>> {

  // `doubleCodec` is last, as it is in the extended definition. We only want to
  // send it explicitly, so `floatCodec` should be ahead of it.
  static final List<DataCodec<Object>> codecs =
      List<DataCodec<Object>>.unmodifiable(
          <DataCodec<Object>>[blobCodec, intCodec, floatCodec, stringCodec, doubleCodec]);

  final String typeTag;

  const DataCodec({required this.typeTag});

  bool appliesTo(Object? value) => value is T;

  int length(T value);

  T toValue(String string);

  /// TODO: Rename?
  static DataCodec<T> forType<T>(String typeTag) =>
      codecs.firstWhere((codec) => codec.typeTag == typeTag,
              orElse: (() =>
                  throw ArgumentError('Unsupported codec typeTag: $typeTag')))
          as DataCodec<T>;

  static DataCodec<T> forValue<T>(T value) =>
      codecs.firstWhere((codec) => codec.appliesTo(value),
          orElse: (() => throw ArgumentError(
              'Unsupported codec type: ${value.runtimeType}'))) as DataCodec<T>;
}

abstract class DataDecoder<T> extends Converter<List<int>, T> {
  const DataDecoder();
}

abstract class DataEncoder<T> extends Converter<T, List<int>> {
  const DataEncoder();
}

class BlobCodec extends DataCodec<Uint8List> {
  const BlobCodec() : super(typeTag: 'b');

  @override
  Converter<List<int>, Uint8List> get decoder => const BlobDecoder();

  @override
  Converter<Uint8List, List<int>> get encoder => const BlobEncoder();

  @override
  int length(Uint8List value) => value.lengthInBytes;

  @override
  Uint8List toValue(String string) => string.codeUnits as Uint8List;
}

class BlobDecoder extends DataDecoder<Uint8List> {
  const BlobDecoder();

  @override
  Uint8List convert(List<int> input) {
    final buffer = Uint8List.fromList(input).buffer;
    final byteData = ByteData.view(buffer);
    final len = byteData.getInt32(0);
    final retval = input.sublist(4, len + 4);
    return retval as Uint8List;
  }
}

class BlobEncoder extends DataEncoder<Uint8List> {
  const BlobEncoder();

  @override
  List<int> convert(Uint8List input) {
    final len = input.length;
    final list = Uint8List(4);
    final byteData = ByteData.view(list.buffer);
    byteData.setInt32(0, len);
    final retval = list.toList();
    retval.addAll(input);
    return retval;
  }
}

class FloatCodec extends DataCodec<double> {
  const FloatCodec() : super(typeTag: 'f');

  @override
  Converter<List<int>, double> get decoder => const FloatDecoder();

  @override
  Converter<double, List<int>> get encoder => const FloatEncoder();

  @override
  int length(double value) => 4;

  @override
  double toValue(String string) => double.parse(string);
}

class FloatDecoder extends DataDecoder<double> {
  const FloatDecoder();

  @override
  double convert(List<int> input) {
    final buffer = Uint8List.fromList(input).buffer;
    final byteData = ByteData.view(buffer);
    return byteData.getFloat32(0);
  }
}

class FloatEncoder extends DataEncoder<double> {
  const FloatEncoder();

  @override
  List<int> convert(double input) {
    final list = Uint8List(4);
    final byteData = ByteData.view(list.buffer);
    byteData.setFloat32(0, input);
    return list;
  }
}

class DoubleCodec extends DataCodec<double> {
  const DoubleCodec() : super(typeTag: 'd');

  @override
  Converter<List<int>, double> get decoder => const DoubleDecoder();

  @override
  Converter<double, List<int>> get encoder => const DoubleEncoder();

  @override
  int length(double value) => 8;

  @override
  double toValue(String string) => double.parse(string);
}

class DoubleDecoder extends DataDecoder<double> {
  const DoubleDecoder();

  @override
  double convert(List<int> input) {
    final buffer = Uint8List.fromList(input).buffer;
    final byteData = ByteData.view(buffer);
    return byteData.getFloat64(0);
  }
}


class DoubleEncoder extends DataEncoder<double> {
  const DoubleEncoder();

  @override
  List<int> convert(double input) {
    final list = Uint8List(8);
    final byteData = ByteData.view(list.buffer);
    byteData.setFloat64(0, input);
    return list;
  }
}

class IntCodec extends DataCodec<int> {
  const IntCodec() : super(typeTag: 'i');

  @override
  Converter<List<int>, int> get decoder => const IntDecoder();

  @override
  Converter<int, List<int>> get encoder => const IntEncoder();

  @override
  int length(int value) => 4;

  @override
  int toValue(String string) => int.parse(string);
}

class IntDecoder extends DataDecoder<int> {
  const IntDecoder();

  @override
  int convert(List<int> input) {
    final buffer = Uint8List.fromList(input).buffer;
    final byteData = ByteData.view(buffer);
    return byteData.getInt32(0);
  }
}

class IntEncoder extends DataEncoder<int> {
  const IntEncoder();

  @override
  List<int> convert(int input) {
    final list = Uint8List(4);
    final byteData = ByteData.view(list.buffer);
    byteData.setInt32(0, input);
    return list;
  }
}

class StringCodec extends DataCodec<String> {
  const StringCodec() : super(typeTag: 's');

  @override
  Converter<List<int>, String> get decoder => const StringDecoder();

  @override
  Converter<String, List<int>> get encoder => const StringEncoder();

  @override
  int length(String value) =>  value.length % 4 == 0 ? value.length + 1 : value.length;

  @override
  String toValue(String string) => string;
}

class StringDecoder extends DataDecoder<String> {
  const StringDecoder();

  @override
  String convert(List<int> input) {
    final nextNull = input.indexOf(0);
    if (nextNull == -1) {
      return utf8.decode(input);
    } else {
      return utf8.decode(input.sublist(0, nextNull));
    }
  }
}

class StringEncoder extends DataEncoder<String> {
  const StringEncoder();

  @override
  List<int> convert(String input) {
    // final bytes = utf8.encode(input).toList();
    final bytes = input.codeUnits.toList();
    bytes.add(0);

    final pad = (4 - bytes.length % 4) % 4;
    bytes.addAll(List.generate(pad, (i) => 0));

    return bytes;
  }
}

class OSCMessageBuilder {
  final _builder = BytesBuilder();

  int get length => _builder.length;

  void addAddress(String address) {
    addString(address);
  }

  void addArguments(List<Object> args) {
    final codecs = args.map(DataCodec.forValue).toList();

    // Type tag (e.g., `,iis`).
    final sb = StringBuffer();
    sb.write(',');
    for (var codec in codecs) {
      sb.write(codec.typeTag);
    }
    addString(sb.toString());

    // Args.
    for (var i = 0; i < args.length; ++i) {
      addBytes(codecs[i].encode(args[i]));
    }
  }

  void addBytes(List<int> bytes) {
    _builder.add(bytes);
  }

  void addString(String string) {
    _builder.add(stringCodec.encode(string));
  }

  List<int> toBytes() => _builder.toBytes();
}

class OSCMessageCodec extends Codec<OSCMessage, List<int>> {
  const OSCMessageCodec();

  @override
  Converter<List<int>, OSCMessage> get decoder => const OSCMessageDecoder();

  @override
  Converter<OSCMessage, List<int>> get encoder => const OSCMessageEncoder();
}

class OSCMessageDecoder extends DataDecoder<OSCMessage> {
  const OSCMessageDecoder();

  @override
  OSCMessage convert(List<int> input) => OSCMessageParser(input).parse();
}

class OSCMessageEncoder extends DataEncoder<OSCMessage> {
  const OSCMessageEncoder();

  @override
  List<int> convert(OSCMessage input) {
    final builder = OSCMessageBuilder();
    builder.addAddress(input.address);
    builder.addArguments(input.arguments);
    return builder.toBytes();
  }
}

class OSCMessageParser {
  int index = 0;

  final List<int> input;
  OSCMessageParser(this.input);

  void advance({required String char}) {
    if (input[index++] != stringCodec.encode(char)[0]) {
      //TODO: throw
    }
  }

  void align() {
    index += (4 - index % 4) % 4;
  }

  String asString(List<int> bytes) => stringCodec.decode(bytes);

  void eat({required int byte}) {
    if (input[++index] != byte) {
      //TODO: throw
    }
  }

  OSCMessage parse() {
    final addressBytes = takeUntil(byte: 0);
    final address = asString(addressBytes);

    eat(byte: 0);
    align();

    advance(char: ',');
    final args = <Object>[];
    final typeTagBytes = takeUntil(byte: 0);
    if (typeTagBytes.isNotEmpty) {
      eat(byte: 0);
      align();

      final codecs =
          typeTagBytes.map((b) => DataCodec.forType(asString(<int>[b])));
      for (var codec in codecs) {
        final value = codec.decode(input.sublist(index));
        args.add(value);

        index += codec.length(value);
        // if (value is String) eat(byte: 0);
        align();
      }
    }

    return OSCMessage(address, arguments: args);
  }

  List<int> takeUntil({required int byte}) {
    final count = input.indexOf(byte, index) - index;
    if (count < 1) {
      //TODO: throw
    }

    return input.sublist(index, index += count);
  }
}
