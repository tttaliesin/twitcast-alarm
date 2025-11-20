import 'dart:async';
import 'dart:io';

/// Windows 백그라운드 모니터링 서비스
/// 윈도우가 최소화되어도 계속 실행되는 간단한 Timer 방식 사용
/// 참고: Windows에서는 Flutter 앱이 최소화되어도 계속 실행되므로 Timer.periodic이 정상 작동
class WindowsBackgroundService {
  static bool _isMonitoring = false;

  /// 모니터링 활성화 여부 확인
  static bool get isMonitoring => _isMonitoring;

  /// Windows 백그라운드 모니터링 시작
  /// 참고: Windows에서는 앱이 최소화되어도 계속 실행되므로,
  /// StreamMonitorService의 기존 Timer가 정상적으로 작동함
  static Future<void> startMonitoring() async {
    if (!Platform.isWindows) return;

    _isMonitoring = true;
    print('✅ Windows 백그라운드 모니터링 활성화됨');
  }

  /// Windows 백그라운드 모니터링 중지
  static void stopMonitoring() {
    if (!Platform.isWindows) return;

    _isMonitoring = false;
    print('✅ Windows 백그라운드 모니터링 비활성화됨');
  }
}
