import 'dart:async';
import 'dart:io';

import 'core/convert.dart';
import 'core/message.dart';
import 'model/companion_command.dart';
import 'model/osc_response.dart';

class OscManager {
  String address;
  int listenPort;
  int sendPort;

  OscManager({
    required this.address,
    required this.listenPort,
    required this.sendPort,
  });

  RawDatagramSocket? oscSocket; // OSC 소켓
  Stream<RawSocketEvent>? _oscStream;

  // OSC 메시지 핸들러 저장용 Map
  final Map<String, Function(OSCMessage)> _handlers = {};

  /// OSC 소켓을 연결하는 메서드
  Future<void> connect() async {
    try {
      // RawDatagramSocket을 사용하여 지정된 포트와 주소에서 수신을 위한 소켓을 바인딩
      oscSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, // 모든 IPv4 주소에서 수신
        listenPort, // 소켓의 포트
        ttl: 50, // Time-to-live 값
      );

      _oscStream = oscSocket?.asBroadcastStream(onCancel: (subscription) {
        if (oscSocket != null) {
          oscSocket?.close();
          oscSocket = null;
          print("OSC 소켓 닫힘 - 모든 리스너 취소");
        }
      });

      // 소켓 이벤트를 수신하고 처리
      _oscStream?.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            Datagram? d = oscSocket?.receive();
            if (d != null) {
              final parsedMsg = OSCMessageParser(d.data).parse();
              print('OSC 메세지 수신 : $parsedMsg');

              _handleOsc(parsedMsg);
            }
          } else if (event == RawSocketEvent.closed) {
            oscSocket = null; // 소켓이 닫히면 null로 설정
            print("OSC Socket closed");
          }
        },
        onError: (e) {
          print("OSC Error: $e");
        },
        onDone: () {
          oscSocket = null;
          print("OSC Socket closed");
        },
      );

      print("OSC Socket connected");
    } catch (e) {
      print("Failed to bind socket: $e"); // 바인딩 실패 시 오류 출력
      rethrow;
    }
  }

  /// OSC 메시지 핸들러 추가
  void addHandler(String address, Function(OSCMessage) handler) {
    _handlers[address] = handler;
  }

  /// 저장된 핸들러를 통해 OSC 메시지를 처리
  void _handleOsc(OSCMessage parsedMsg) {
    final handler = _handlers[parsedMsg.address];

    try {
      handler!(parsedMsg);
    } catch (e) {
      print("처리할 핸들러가 없음: ${parsedMsg.address}");
    }
  }

  /// OSC 소켓 연결을 해제하는 메서드
  void disconnect() {
    try {
      if (oscSocket != null) {
        oscSocket!.close(); // 소켓을 닫음
        oscSocket = null; // 소켓 객체를 null로 설정
        print("OSC Socket disconnected");
      }
    } catch (e) {
      print("Error during disconnect: $e");
    }
  }

  /// OSC 메세지를 특정 주소(default:서버)로 발송하는 메서드
  Future<OscResponse?> sendString({
    String? address,
    int? port,
    required String query,
    List<Object> messages = const [],
    bool needResponse = false,
    Function()? afterComplete,
  }) async {
    address = address ?? this.address;
    port = port ?? sendPort;

    final message = OSCMessage(query, arguments: messages); // OSC 메시지 생성
    final bytes = message.toBytes(); // 바이트로 변환

    try {
      // oscSocket이 null일 경우 connect() 호출 후 재발송
      if (oscSocket == null) {
        print("OSC 소켓이 비어 있어 연결을 시도합니다...");
        await connect();
      }

      // 연결이 성공적으로 완료되었을 경우 메시지 발송
      if (oscSocket != null) {
        if (needResponse) {
          final resCompleter = Completer<OscResponse>();
          // OSC 메세지 발송
          oscSocket!.send(bytes, InternetAddress(address), port);

          print('OSC 발송 메세지: $message');

          return resCompleter.future.timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              return OscResponse(1, message: 'NDI OSC 응답 Time Out'); // 타임아웃 처리
            },
          ).whenComplete(() {
            if (afterComplete != null) {
              afterComplete();
            }
          });
        }

        // ✅ needResponse가 false일 경우 바로 메시지만 전송하고 종료
        print('🚀 OSC 메시지 발송(응답 필요 없음): $message');
        oscSocket!.send(bytes, InternetAddress(address), port);
      }
    } catch (e) {
      print("OSC 발송 실패: $e"); // 오류 발생 시 출력
      return OscResponse(1, message: "OSC 발송 실패: $e");
    }

    return OscResponse(0);
  }

  /// 컴페니언 3.3.1 이상 지원
  Future<OscResponse?> sendToCompanion({
    required int page,
    required int row,
    required int col,
    String? address,
    int? port,
    Command command = Command.press,
    List<Object> messages = const [],
    bool needResponse = false,
  }) async {
    address = address ?? this.address;
    port = port ?? sendPort;
    // 버튼과 페이지 데이터를 바탕으로 OSC 쿼리를 생성

    final query = "/location/$page/$row/$col/$command"; // 쿼리 생성

    return await sendString(
        query: query, address: address, port: port, needResponse: needResponse);
  }
}
