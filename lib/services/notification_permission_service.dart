import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// 알림 권한 관리 서비스 (Android 13+ 필수)
class NotificationPermissionService {
  /// 알림 권한 확인
  static Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 알림 권한 요청
  /// 반환값: true = 권한 허용됨, false = 권한 거부됨
  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    // 이미 권한이 있는지 확인
    if (await hasNotificationPermission()) {
      print('✅ 알림 권한 이미 허용됨');
      return true;
    }

    print('📍 알림 권한 요청 시작');
    final status = await Permission.notification.request();

    if (status.isGranted) {
      print('✅ 알림 권한 허용됨');
      return true;
    } else if (status.isDenied) {
      print('❌ 알림 권한 거부됨');
      return false;
    } else if (status.isPermanentlyDenied) {
      print('❌ 알림 권한 영구 거부됨 - 설정에서 수동으로 허용 필요');
      // 설정 화면으로 이동
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// 앱 설정 화면 열기
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
