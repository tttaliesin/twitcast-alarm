import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_history.dart';

/// 알람 히스토리 저장 및 관리 서비스
class AlarmHistoryService {
  static const String _historyKey = 'alarm_history';
  static const int _maxHistoryItems = 100; // 최대 저장 개수

  /// 새로운 알람 히스토리 항목 추가
  static Future<void> addHistory({
    required String streamUrl,
    required String userId,
    bool wasAlarmTriggered = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 기존 히스토리 로드
      final historyList = await getHistory();

      // 새 항목 추가
      final newHistory = AlarmHistory(
        streamUrl: streamUrl,
        userId: userId,
        timestamp: DateTime.now(),
        wasAlarmTriggered: wasAlarmTriggered,
      );

      historyList.insert(0, newHistory); // 최신 항목을 맨 앞에

      // 최대 개수 제한
      if (historyList.length > _maxHistoryItems) {
        historyList.removeRange(_maxHistoryItems, historyList.length);
      }

      // 저장
      final jsonList = historyList.map((h) => h.toJson()).toList();
      await prefs.setString(_historyKey, json.encode(jsonList));

      print('✅ 알람 히스토리 저장됨: $userId at ${newHistory.timestamp}');
    } catch (e) {
      print('❌ 알람 히스토리 저장 오류: $e');
    }
  }

  /// 모든 히스토리 항목 가져오기
  static Future<List<AlarmHistory>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(historyJson);
      return jsonList.map((json) => AlarmHistory.fromJson(json)).toList();
    } catch (e) {
      print('❌ 알람 히스토리 로드 오류: $e');
      return [];
    }
  }

  /// 특정 스트림의 히스토리만 가져오기
  static Future<List<AlarmHistory>> getHistoryForStream(String streamUrl) async {
    final allHistory = await getHistory();
    return allHistory.where((h) => h.streamUrl == streamUrl).toList();
  }

  /// 특정 기간의 히스토리 가져오기
  static Future<List<AlarmHistory>> getHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final allHistory = await getHistory();
    return allHistory.where((h) {
      return h.timestamp.isAfter(startDate) && h.timestamp.isBefore(endDate);
    }).toList();
  }

  /// 히스토리 전체 삭제
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      print('✅ 알람 히스토리 전체 삭제됨');
    } catch (e) {
      print('❌ 알람 히스토리 삭제 오류: $e');
    }
  }

  /// 특정 항목 삭제 (인덱스 기반)
  static Future<void> deleteHistoryAt(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await getHistory();

      if (index >= 0 && index < historyList.length) {
        historyList.removeAt(index);

        final jsonList = historyList.map((h) => h.toJson()).toList();
        await prefs.setString(_historyKey, json.encode(jsonList));

        print('✅ 알람 히스토리 항목 삭제됨: index $index');
      }
    } catch (e) {
      print('❌ 알람 히스토리 항목 삭제 오류: $e');
    }
  }

  /// 히스토리 통계 정보 가져오기
  static Future<Map<String, dynamic>> getStatistics() async {
    final allHistory = await getHistory();

    if (allHistory.isEmpty) {
      return {
        'totalAlarms': 0,
        'todayAlarms': 0,
        'weekAlarms': 0,
        'mostActiveStream': null,
      };
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));

    final todayAlarms = allHistory.where((h) => h.timestamp.isAfter(todayStart)).length;
    final weekAlarms = allHistory.where((h) => h.timestamp.isAfter(weekStart)).length;

    // 가장 많이 알람이 울린 스트림 찾기
    final streamCounts = <String, int>{};
    for (final history in allHistory) {
      streamCounts[history.userId] = (streamCounts[history.userId] ?? 0) + 1;
    }

    String? mostActiveStream;
    int maxCount = 0;
    streamCounts.forEach((userId, count) {
      if (count > maxCount) {
        maxCount = count;
        mostActiveStream = userId;
      }
    });

    return {
      'totalAlarms': allHistory.length,
      'todayAlarms': todayAlarms,
      'weekAlarms': weekAlarms,
      'mostActiveStream': mostActiveStream,
      'mostActiveStreamCount': maxCount,
    };
  }
}
