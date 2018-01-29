import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:osc/message.dart';

abstract class DataCodec<T> extends Codec<T, List<int>> {
  static final List<DataCodec<Object>> codecs =
      new List<DataCodec<Object>>.unmodifiable(
          <DataCodec<Object>>[intCodec, stringCodec]);

  final String typeTag;

  const DataCodec({this.typeTag});

  static DataCodec<T> forType<T>(String typeTag) =>
      codecs.firstWhere((codec) => codec.typeTag == typeTag,
          orElse: () =>
              throw new ArgumentError('Unsupported codec typeTag: $typeTag'));

  static DataCodec<T> forValue<T>(T value) =>
      codecs.firstWhere((codec) => codec.appliesTo(value),
          orElse: () => throw new ArgumentError(
              'Unsupported codec type: ${value.runtimeType}'));

  bool appliesTo(Object value) => value is T;

  // TODO: Rename?
  int length(T value);

  T toValue(String string);
}

abstract class DataDecoder<T> extends Converter<List<int>, T> {
  const DataDecoder();
}

abstract class DataEncoder<T> extends Converter<T, List<int>> {
  const DataEncoder();
}

const IntCodec intCodec = const IntCodec();
const StringCodec stringCodec = const StringCodec();
const OSCMessageCodec oscMessageCodec = const OSCMessageCodec();

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
  int convert(List<int> value) =>
      (value[0] << 24) & 0xFF |
      (value[1] << 18) & 0xFF |
      (value[2] << 8) & 0xFF |
      (value[3] /* << 0 */) & 0xFF;
}

class IntEncoder extends DataEncoder<int> {
  const IntEncoder();

  @override
  List<int> convert(int value) => <int>[
        (value >> 24) & 0xFF,
        (value >> 18) & 0xFF,
        (value >> 8) & 0xFF,
        (value /* >> 0 */) & 0xFF,
      ];
}

class StringCodec extends DataCodec<String> {
  const StringCodec() : super(typeTag: 's');

  @override
  Converter<List<int>, String> get decoder => const StringDecoder();

  @override
  Converter<String, List<int>> get encoder => const StringEncoder();

  @override
  int length(String value) => value.length;

  @override
  String toValue(String string) => string;
}

class StringDecoder extends DataDecoder<String> {
  const StringDecoder();

  @override
  String convert(List<int> input) => UTF8.decode(input);
}

class StringEncoder extends DataEncoder<String> {
  const StringEncoder();

  @override
  List<int> convert(String input) {
    final bytes = UTF8.encode(input).toList();
    bytes.add(0);

    var pad = (4 - bytes.length % 4) % 4;
    while (pad-- > 0) {
      bytes.add(0);
    }

    return bytes;
  }
}

class OSCMessageDecoder extends DataDecoder<OSCMessage> {
  const OSCMessageDecoder();

  @override
  OSCMessage convert(List<int> input) => new OSCMessageParser(input).parse();
}

class OSCMessageParser {
  int index = 0;

  List<int> input;
  OSCMessageParser(this.input);

  String asString(List<int> bytes) => stringCodec.decode(bytes);

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
      }
    }

    return new OSCMessage(address, arguments: args);
  }

  void eat({@required int byte}) {
    if (input[++index] != byte) {
      //TODO: throw
    }
  }

  void advance({@required String char}) {
    if (input[index++] != stringCodec.encode(char)[0]) {
      //TODO: throw
    }
  }

  List<int> takeUntil({@required int byte}) {
    final count = input.indexOf(byte, index) - index;
    if (count < 1) {
      //TODO: throw
    }

    return input.sublist(index, index += count);
  }

  void align() {
    index += (4 - index % 4) % 4;
  }
}

class OSCMessageEncoder extends DataEncoder<OSCMessage> {
  const OSCMessageEncoder();

  @override
  List<int> convert(OSCMessage msg) {
    final builder = new OSCMessageBuilder();
    builder.addAddress(msg.address);
    builder.addArguments(msg.arguments);
    return builder.toBytes();
  }
}

class OSCMessageBuilder {
  final _builder = new BytesBuilder();

  void addAddress(String address) {
    addString(address);
  }

  void addArguments(List<Object> args) {
    final codecs = args.map(DataCodec.forValue).toList();

    // Type tag (e.g., `,iis`).
    final sb = new StringBuffer();
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

  int get length => _builder.length;

  List<int> toBytes() => _builder.toBytes();
}

class OSCMessageCodec extends Codec<OSCMessage, List<int>> {
  const OSCMessageCodec();

  @override
  Converter<List<int>, OSCMessage> get decoder => const OSCMessageDecoder();

  @override
  Converter<OSCMessage, List<int>> get encoder => const OSCMessageEncoder();
}
