import 'package:osc/src/convert.dart';
import 'package:osc/src/message.dart';
import 'package:test/test.dart';

void main() {
  group('codecs', () {
    group('forType', () {
      test('unknown', () {
        expect(() => DataCodec.forType('x'),
            throwsA(const isInstanceOf<ArgumentError>()));
      });
    });

    group('messages', () {
      group('encode', () {
        test('empty', () {
          final message = new OSCMessage('/empty', arguments: []);
          expect(oscMessageCodec.encode(message),
              [47, 101, 109, 112, 116, 121, 0, 0, 44, 0, 0, 0]);
        });
        test('int', () {
          final message = new OSCMessage('/int', arguments: [99]);
          expect(oscMessageCodec.encode(message),
              [47, 105, 110, 116, 0, 0, 0, 0, 44, 105, 0, 0, 0, 0, 0, 99]);
        });
      });

      group('decode', () {
        test('empty', () {
          final message = oscMessageCodec
              .decode([47, 101, 109, 112, 116, 121, 0, 0, 44, 0, 0, 0]);
          expect(message.address, '/empty');
          expect(message.arguments, isEmpty);
        });
        test('int', () {
          final message = oscMessageCodec.decode(
              [47, 105, 110, 116, 0, 0, 0, 0, 44, 105, 0, 0, 0, 0, 0, 99]);
          expect(message.address, '/int');
          expect(message.arguments, <Object>[99]);
        });
      });
    });

    group('ints', () {
      test('decode', () {
        expect(intCodec.decoder.convert([0, 0, 0, 13]), 13);
      });

      test('encode', () {
        expect(intCodec.encoder.convert(13), [0, 0, 0, 13]);
      });
    });

    group('strings', () {
      test('decode', () {
        expect(stringCodec.decoder.convert([102, 111, 111]), 'foo');
      });

      test('encode', () {
        expect(stringCodec.encoder.convert('foo'), [102, 111, 111, 0]);
      });
    });
  });
}
