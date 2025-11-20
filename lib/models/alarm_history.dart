/// 알람 히스토리 항목 데이터 모델
class AlarmHistory {
  /// 스트림 URL
  final String streamUrl;

  /// 스트림 사용자 ID
  final String userId;

  /// 알람 발생 시각
  final DateTime timestamp;

  /// 알람이 울렸는지 여부 (true) 또는 수동 확인 기록 (false)
  final bool wasAlarmTriggered;

  AlarmHistory({
    required this.streamUrl,
    required this.userId,
    required this.timestamp,
    this.wasAlarmTriggered = true,
  });

  /// JSON에서 객체 생성
  factory AlarmHistory.fromJson(Map<String, dynamic> json) {
    return AlarmHistory(
      streamUrl: json['streamUrl'] as String,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      wasAlarmTriggered: json['wasAlarmTriggered'] as bool? ?? true,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'streamUrl': streamUrl,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'wasAlarmTriggered': wasAlarmTriggered,
    };
  }

  /// 시간 포맷팅 헬퍼 메서드
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
