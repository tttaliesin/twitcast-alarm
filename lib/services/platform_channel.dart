import 'package:flutter/services.dart';
import 'dart:io';

/// Android 플랫폼 채널 통신을 담당하는 서비스
/// Dart와 Android 네이티브 코드(Kotlin/Java) 간의 통신을 처리
class PlatformChannel {
  static const MethodChannel _channel = MethodChannel('com.twitcast.alarm/background');

  /// 백그라운드 모니터링 서비스 시작 (Android 전용)
  static Future<void> startBackgroundService() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('startBackgroundService');
      print('✅ 백그라운드 서비스 시작됨');
    } catch (e) {
      print('❌ 백그라운드 서비스 시작 오류: $e');
    }
  }

  /// 백그라운드 모니터링 서비스 중지 (Android 전용)
  static Future<void> stopBackgroundService() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('stopBackgroundService');
      print('✅ 백그라운드 서비스 중지됨');
    } catch (e) {
      print('❌ 백그라운드 서비스 중지 오류: $e');
    }
  }

  /// 알림 텍스트 업데이트 (Android 전용)
  /// Foreground Service의 알림 내용을 동적으로 변경
  static Future<void> updateNotification(String text) async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('updateNotification', {'text': text});
    } catch (e) {
      print('❌ 알림 업데이트 오류: $e');
    }
  }

  /// 백그라운드 서비스 실행 여부 확인 (Android 전용)
  static Future<bool> isBackgroundServiceRunning() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod('isBackgroundServiceRunning');
      return result as bool;
    } catch (e) {
      print('❌ 백그라운드 서비스 상태 확인 오류: $e');
      return false;
    }
  }

  /// 스트림 체크 콜백 등록 (Android 전용)
  /// 백그라운드에서 스트림을 체크해야 할 때 호출될 핸들러 설정
  static void setStreamCheckHandler(Function() handler) {
    if (!Platform.isAndroid) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'checkStreams') {
        handler();
      }
    });
  }
}
