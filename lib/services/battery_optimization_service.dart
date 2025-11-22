import 'dart:io';
import 'package:flutter/services.dart';

/// 배터리 최적화 관리 서비스
/// Android에서 백그라운드 실행을 위해 배터리 최적화 예외 요청
class BatteryOptimizationService {
  static const _platform = MethodChannel('com.twitcast.alarm/battery');

  /// 배터리 최적화가 비활성화되어 있는지 확인
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await _platform.invokeMethod('isIgnoringBatteryOptimizations');
      return result as bool;
    } catch (e) {
      print('❌ 배터리 최적화 상태 확인 오류: $e');
      return false;
    }
  }

  /// 배터리 최적화 예외 설정 화면으로 이동
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;

    try {
      await _platform.invokeMethod('requestIgnoreBatteryOptimizations');
      print('✅ 배터리 최적화 예외 요청 화면 표시');
    } catch (e) {
      print('❌ 배터리 최적화 예외 요청 오류: $e');
    }
  }
}
