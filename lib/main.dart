import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'services/stream_monitor_service.dart';
import 'services/background_service_manager.dart';
import 'services/system_tray_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows용 윈도우 매니저 초기화
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      minimumSize: Size(600, 400),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // 윈도우 타이틀 설정
      await windowManager.setTitle('스드트캐안놓앱');
      // 윈도우 닫기 방지 - 닫기 이벤트를 가로챔
      await windowManager.setPreventClose(true);
    });

    // 시스템 트레이 초기화
    await SystemTrayService.initialize();
  }

  // SharedPreferences 초기화
  final prefs = await SharedPreferences.getInstance();

  // 백그라운드 서비스 초기화
  await BackgroundServiceManager.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => StreamMonitorService(prefs),
      child: const TwitcastAlarmApp(),
    ),
  );
}

class TwitcastAlarmApp extends StatelessWidget {
  const TwitcastAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '스드트캐안놓앱',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
