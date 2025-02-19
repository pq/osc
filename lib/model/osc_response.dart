
class OscResponse {
  /// code def
  /// 0 : 성공
  /// 1 : 실패

  final int code;
  final String? message;

  OscResponse(
      this.code, {
        this.message,
      });
}