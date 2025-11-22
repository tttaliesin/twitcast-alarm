import 'dart:io';
import 'platform_channel.dart';
import 'windows_background_service.dart';

/// 모든 플랫폼을 위한 통합 백그라운드 서비스 관리자
class BackgroundServiceManager {
  static bool _isInitialized = false;
  static Function()? _streamCheckCallback;

  /// 백그라운드 서비스 초기화
  static Future<void> initialize({
    Function()? onStreamCheck,
  }) async {
    if (_isInitialized) return;

    _streamCheckCallback = onStreamCheck;

    if (Platform.isAndroid) {
      // Android 전용 초기화
      print('Android 백그라운드 서비스 초기화 중');
      PlatformChannel.setStreamCheckHandler(() {
        print('🔔 백그라운드 브로드캐스트 수신 -> 스트림 체크 실행');
        _streamCheckCallback?.call();
      });
    } else if (Platform.isWindows) {
      // Windows 전용 초기화
      print('Windows 백그라운드 서비스 초기화 중');
    }

    _isInitialized = true;
  }

  /// 백그라운드 모니터링 시작
  static Future<void> startBackgroundMonitoring() async {
    if (Platform.isAndroid) {
      await PlatformChannel.startBackgroundService();
      print('Android 백그라운드 서비스 시작됨');
    } else if (Platform.isWindows) {
      await WindowsBackgroundService.startMonitoring();
      print('Windows 백그라운드 모니터링 시작됨');
    }
  }

  /// 백그라운드 모니터링 중지
  static Future<void> stopBackgroundMonitoring() async {
    if (Platform.isAndroid) {
      await PlatformChannel.stopBackgroundService();
      print('Android 백그라운드 서비스 중지됨');
    } else if (Platform.isWindows) {
      WindowsBackgroundService.stopMonitoring();
      print('Windows 백그라운드 모니터링 중지됨');
    }
  }

  /// 백그라운드 모니터링이 활성화되어 있는지 확인
  static Future<bool> isBackgroundMonitoringActive() async {
    if (Platform.isAndroid) {
      return await PlatformChannel.isBackgroundServiceRunning();
    } else if (Platform.isWindows) {
      return WindowsBackgroundService.isMonitoring;
    }
    return false;
  }

  /// 알림 텍스트 업데이트 (Android 전용)
  static Future<void> updateNotification(String text) async {
    if (Platform.isAndroid) {
      await PlatformChannel.updateNotification(text);
    }
  }
}
