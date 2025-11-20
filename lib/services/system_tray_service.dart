import 'dart:io';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

/// Windows 시스템 트레이 서비스
/// 최소화 시 트레이 아이콘과 메뉴를 제공
class SystemTrayService {
  static final SystemTray _systemTray = SystemTray();
  static bool _isInitialized = false;
  static Menu? _menu;

  /// 시스템 트레이 초기화
  static Future<void> initialize() async {
    if (!Platform.isWindows || _isInitialized) return;

    try {
      // 실행 파일이 있는 디렉토리 경로 추출
      String executablePath = Platform.resolvedExecutable;
      String executableDir = executablePath.substring(0, executablePath.lastIndexOf(Platform.pathSeparator));

      // 아이콘 파일 경로 구성
      // Debug 모드: build/windows/x64/runner/Debug/data/flutter_assets/assets/app_icon.ico
      // Release 모드: build/windows/x64/runner/Release/data/flutter_assets/assets/app_icon.ico
      String iconPath = '$executableDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}assets${Platform.pathSeparator}app_icon.ico';

      print('🎯 실행 파일 경로: $executablePath');
      print('🎯 실행 파일 디렉토리: $executableDir');
      print('🎯 시스템 트레이 아이콘 경로: $iconPath');
      print('🎯 아이콘 파일 존재 여부: ${File(iconPath).existsSync()}');

      // 시스템 트레이 초기화
      await _systemTray.initSystemTray(
        title: "Twitcast Alarm",
        iconPath: iconPath,
      );

      // 메뉴 생성
      _menu = Menu();

      await _menu!.buildFrom([
        MenuItemLabel(
          label: '창 표시',
          onClicked: (menuItem) {
            print('📌 메뉴: 창 표시 클릭됨');
            _showWindow();
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: '앱 완전 종료',
          onClicked: (menuItem) {
            print('📌 메뉴: 앱 완전 종료 클릭됨');
            _exitApp();
          },
        ),
      ]);

      print('🎯 컨텍스트 메뉴 설정 중...');
      await _systemTray.setContextMenu(_menu!);
      print('✅ 컨텍스트 메뉴 설정 완료');

      // 트레이 아이콘 클릭 이벤트 처리
      _systemTray.registerSystemTrayEventHandler((eventName) {
        print('🖱️ 시스템 트레이 이벤트: $eventName');

        if (eventName == kSystemTrayEventClick) {
          print('📌 왼쪽 클릭 감지');
          _showWindow();
        } else if (eventName == kSystemTrayEventRightClick) {
          print('📌 우클릭 감지 - 메뉴 표시 시도');
          // 명시적으로 메뉴 표시
          _systemTray.popUpContextMenu();
        }
      });

      _isInitialized = true;
      print('✅ 시스템 트레이 초기화 완료');
    } catch (e) {
      print('❌ 시스템 트레이 초기화 오류: $e');
    }
  }

  /// 윈도우 표시
  static Future<void> _showWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      print('❌ 윈도우 표시 오류: $e');
    }
  }

  /// 앱 완전 종료
  static Future<void> _exitApp() async {
    try {
      print('🛑 앱 종료 중...');

      // 시스템 트레이 아이콘 제거
      if (_isInitialized) {
        await _systemTray.destroy();
        _isInitialized = false;
      }

      // 윈도우 매니저 정리
      await windowManager.destroy();

      print('✅ 앱 종료 완료');

      // 프로세스 강제 종료
      exit(0);
    } catch (e) {
      print('❌ 앱 종료 오류: $e');
      // 오류가 발생해도 강제 종료
      exit(1);
    }
  }

  /// 리소스 해제
  static Future<void> dispose() async {
    if (_isInitialized) {
      await _systemTray.destroy();
      _isInitialized = false;
    }
  }
}
