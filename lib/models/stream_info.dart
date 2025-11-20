/// 스트림 정보를 담는 데이터 모델
class StreamInfo {
  final String url;
  final bool isMonitoring;
  final bool? isLive; // null = 아직 확인 안 됨, true = 라이브, false = 오프라인

  StreamInfo({
    required this.url,
    this.isMonitoring = false,
    this.isLive,
  });

  StreamInfo copyWith({
    String? url,
    bool? isMonitoring,
    bool? isLive,
  }) {
    return StreamInfo(
      url: url ?? this.url,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      isLive: isLive ?? this.isLive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'isMonitoring': isMonitoring,
      'isLive': isLive,
    };
  }

  factory StreamInfo.fromJson(Map<String, dynamic> json) {
    return StreamInfo(
      url: json['url'] ?? '',
      isMonitoring: json['isMonitoring'] ?? false,
      isLive: json['isLive'],
    );
  }
}
