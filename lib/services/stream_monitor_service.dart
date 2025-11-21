import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stream_info.dart';
import 'twitcast_api.dart';
import 'alarm_service.dart';
import 'background_service_manager.dart';
import 'platform_channel.dart';
import 'alarm_history_service.dart';

/// 스트림 모니터링의 핵심 로직을 담당하는 서비스
/// 스트림 상태 확인, 알람 재생, 설정 저장 등을 관리
class StreamMonitorService extends ChangeNotifier {
  final SharedPreferences _prefs;
  final List<StreamInfo> _streams = List.generate(4, (_) => StreamInfo(url: ''));
  double _alarmVolume = 1.0;
  int _maxRetries = 3;
  int _retryDelaySeconds = 2;
  int _checkIntervalSeconds = 30;
  Timer? _monitoringTimer;
  Timer? _alarmStopTimer;
  final Set<int> _alreadyNotified = {}; // 이미 알림을 보낸 스트림 인덱스
  bool _isAlarmPlaying = false;

  static const String _keyStreams = 'streams';
  static const String _keyVolume = 'volume';
  static const String _keyMaxRetries = 'max_retries';
  static const String _keyRetryDelay = 'retry_delay_seconds';
  static const String _keyCheckInterval = 'check_interval_seconds';

  StreamMonitorService(this._prefs) {
    _loadSettings();
    _startMonitoring();
    _initializeBackgroundServices();
  }

  /// 백그라운드 서비스 초기화
  Future<void> _initializeBackgroundServices() async {
    await BackgroundServiceManager.initialize();

    // Android 백그라운드 체크를 위한 핸들러 설정
    if (Platform.isAndroid) {
      PlatformChannel.setStreamCheckHandler(() {
        _checkAllStreams();
      });
    }
  }

  List<StreamInfo> get streams => List.unmodifiable(_streams);
  double get alarmVolume => _alarmVolume;
  int get maxRetries => _maxRetries;
  int get retryDelaySeconds => _retryDelaySeconds;
  int get checkIntervalSeconds => _checkIntervalSeconds;
  bool get isAlarmPlaying => _isAlarmPlaying;

  /// SharedPreferences에서 설정 로드
  Future<void> _loadSettings() async {
    try {
      // 스트림 로드
      final streamsJson = _prefs.getString(_keyStreams);
      if (streamsJson != null) {
        final List<dynamic> decoded = json.decode(streamsJson);
        for (int i = 0; i < decoded.length && i < 4; i++) {
          _streams[i] = StreamInfo.fromJson(decoded[i]);
        }
      }

      // 볼륨 로드
      _alarmVolume = _prefs.getDouble(_keyVolume) ?? 1.0;

      // 재시도 설정 로드
      _maxRetries = _prefs.getInt(_keyMaxRetries) ?? 3;
      _retryDelaySeconds = _prefs.getInt(_keyRetryDelay) ?? 2;
      _checkIntervalSeconds = _prefs.getInt(_keyCheckInterval) ?? 30;

      notifyListeners();
    } catch (e) {
      print('설정 로드 오류: $e');
    }
  }

  /// SharedPreferences에 설정 저장
  Future<void> _saveSettings() async {
    try {
      // 스트림 저장
      final streamsJson = json.encode(_streams.map((s) => s.toJson()).toList());
      await _prefs.setString(_keyStreams, streamsJson);

      // 볼륨 저장
      await _prefs.setDouble(_keyVolume, _alarmVolume);

      // 재시도 설정 저장
      await _prefs.setInt(_keyMaxRetries, _maxRetries);
      await _prefs.setInt(_keyRetryDelay, _retryDelaySeconds);
      await _prefs.setInt(_keyCheckInterval, _checkIntervalSeconds);
    } catch (e) {
      print('설정 저장 오류: $e');
    }
  }

  /// 스트림 URL 업데이트
  Future<void> updateStreamUrl(int index, String url) async {
    if (index >= 0 && index < _streams.length) {
      _streams[index] = _streams[index].copyWith(url: url, isLive: null);
      await _saveSettings();
      notifyListeners();
    }
  }

  /// 스트림 모니터링 토글 (시작/중지)
  Future<void> toggleMonitoring(int index) async {
    if (index >= 0 && index < _streams.length) {
      final stream = _streams[index];
      final newMonitoringState = !stream.isMonitoring;

      _streams[index] = stream.copyWith(
        isMonitoring: newMonitoringState,
        isLive: newMonitoringState ? null : stream.isLive,
      );

      // 모니터링 중지 시 알림 상태 초기화
      if (!newMonitoringState) {
        _alreadyNotified.remove(index);
      }

      await _saveSettings();
      notifyListeners();

      // 모니터링 시작 시 즉시 체크
      if (newMonitoringState && stream.url.isNotEmpty) {
        await _checkStream(index);
      }

      // 모니터링 중인 스트림 여부에 따라 백그라운드 서비스 시작/중지
      await _updateBackgroundService();
    }
  }

  /// 모니터링 상태에 따라 백그라운드 서비스 업데이트
  Future<void> _updateBackgroundService() async {
    final hasMonitoring = _streams.any((s) => s.isMonitoring);

    if (hasMonitoring) {
      await BackgroundServiceManager.startBackgroundMonitoring();
    } else {
      await BackgroundServiceManager.stopBackgroundMonitoring();
    }
  }

  /// 알람 볼륨 업데이트
  Future<void> updateVolume(double volume) async {
    _alarmVolume = volume.clamp(0.0, 1.0);
    await _saveSettings();
    notifyListeners();
  }

  /// 재시도 횟수 업데이트
  Future<void> updateMaxRetries(int retries) async {
    _maxRetries = retries.clamp(1, 10);
    await _saveSettings();
    notifyListeners();
  }

  /// 재시도 간격 업데이트
  Future<void> updateRetryDelay(int seconds) async {
    _retryDelaySeconds = seconds.clamp(1, 10);
    await _saveSettings();
    notifyListeners();
  }

  /// 확인 간격 업데이트
  Future<void> updateCheckInterval(int seconds) async {
    _checkIntervalSeconds = seconds.clamp(10, 300);
    await _saveSettings();
    // 타이머 재시작
    _startMonitoring();
    notifyListeners();
  }

  /// 모니터링 타이머 시작
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      Duration(seconds: _checkIntervalSeconds),
      (_) => _checkAllStreams(),
    );
  }

  /// 모든 모니터링 중인 스트림 확인
  Future<void> _checkAllStreams() async {
    for (int i = 0; i < _streams.length; i++) {
      final stream = _streams[i];
      if (stream.isMonitoring && stream.url.isNotEmpty) {
        await _checkStream(i);
      }
    }
  }

  /// 단일 스트림 상태 확인
  Future<void> _checkStream(int index) async {
    if (index < 0 || index >= _streams.length) return;

    final stream = _streams[index];
    if (stream.url.isEmpty) return;

    try {
      // 스트림 상태 확인 (설정된 재시도 값 사용)
      final isLive = await TwitcastApi.isStreamLive(
        stream.url,
        maxRetries: _maxRetries,
        retryDelay: Duration(seconds: _retryDelaySeconds),
      );

      _streams[index] = stream.copyWith(isLive: isLive);

      // 스트림이 라이브이고 아직 알림을 보내지 않았다면 알람 트리거
      if (isLive) {
        if (!_alreadyNotified.contains(index)) {
          _alreadyNotified.add(index);
          await _triggerAlarm(index);

          // ✅ 개선: 모니터링을 중지하지 않고 계속 유지
          // 이제 스트림이 종료되고 다시 시작해도 자동으로 알림을 받을 수 있음
        }
      } else {
        // 스트림이 오프라인이 되면 알림 상태 리셋
        // 이렇게 하면 스트림이 종료 후 다시 라이브 상태가 되면 다시 알림을 받음
        _alreadyNotified.remove(index);
      }

      notifyListeners();
    } catch (e) {
      print('스트림 $index 확인 오류: $e');
    }
  }

  /// 스트림이 라이브 상태가 되었을 때 알람 트리거
  Future<void> _triggerAlarm(int index) async {
    final stream = _streams[index];
    print('🔴 스트림 $index이(가) 라이브 상태입니다! 알람 재생 중...');

    // 기존 알람 타이머가 있으면 취소하고 재시작
    _alarmStopTimer?.cancel();

    _isAlarmPlaying = true;
    notifyListeners();

    await AlarmService.playAlarm(_alarmVolume);

    // 히스토리에 기록
    await _recordAlarmHistory(stream.url);

    // 30초 후 자동으로 알람 중지
    _alarmStopTimer = Timer(const Duration(seconds: 30), () {
      stopAlarm();
    });
  }

  /// 알람 히스토리에 기록
  Future<void> _recordAlarmHistory(String streamUrl) async {
    try {
      // URL에서 사용자 ID 추출
      final userId = _extractUserId(streamUrl);
      if (userId.isEmpty) {
        print('⚠️ 사용자 ID를 추출할 수 없어 히스토리 기록 실패');
        return;
      }

      await AlarmHistoryService.addHistory(
        streamUrl: streamUrl,
        userId: userId,
        wasAlarmTriggered: true,
      );
    } catch (e) {
      print('❌ 알람 히스토리 기록 오류: $e');
    }
  }

  /// URL에서 사용자 ID 추출
  String _extractUserId(String url) {
    try {
      url = url.replaceAll('https://', '').replaceAll('http://', '').replaceAll('www.', '');
      if (url.startsWith('twitcasting.tv/')) {
        url = url.substring('twitcasting.tv/'.length);
      }
      final parts = url.split('/');
      if (parts.isNotEmpty) {
        return parts[0];
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// 알람 수동 중지
  Future<void> stopAlarm() async {
    _alarmStopTimer?.cancel();
    await AlarmService.stopAlarm();
    _isAlarmPlaying = false;
    notifyListeners();
  }

  /// 단일 스트림 수동 체크 (테스트/새로고침용)
  Future<void> manualCheckStream(int index) async {
    await _checkStream(index);
  }

  /// 모든 스트림 수동 체크
  Future<void> manualCheckAll() async {
    await _checkAllStreams();
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    _alarmStopTimer?.cancel();
    BackgroundServiceManager.stopBackgroundMonitoring();
    AlarmService.dispose();
    super.dispose();
  }
}
