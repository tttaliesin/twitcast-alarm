import 'package:flutter_test/flutter_test.dart';
import 'package:twitcast_alarm/models/alarm_history.dart';

void main() {
  group('AlarmHistory 모델 테스트', () {
    test('기본 생성자 테스트', () {
      final timestamp = DateTime(2025, 1, 15, 10, 30);
      final history = AlarmHistory(
        streamUrl: 'https://twitcasting.tv/test_user',
        userId: 'test_user',
        timestamp: timestamp,
        wasAlarmTriggered: true,
      );

      expect(history.streamUrl, 'https://twitcasting.tv/test_user');
      expect(history.userId, 'test_user');
      expect(history.timestamp, timestamp);
      expect(history.wasAlarmTriggered, true);
    });

    test('기본값 테스트 - wasAlarmTriggered', () {
      final history = AlarmHistory(
        streamUrl: 'https://twitcasting.tv/test_user',
        userId: 'test_user',
        timestamp: DateTime.now(),
      );

      expect(history.wasAlarmTriggered, true);
    });

    test('toJson 테스트', () {
      final timestamp = DateTime(2025, 1, 15, 10, 30);
      final history = AlarmHistory(
        streamUrl: 'https://twitcasting.tv/test_user',
        userId: 'test_user',
        timestamp: timestamp,
        wasAlarmTriggered: true,
      );

      final json = history.toJson();

      expect(json['streamUrl'], 'https://twitcasting.tv/test_user');
      expect(json['userId'], 'test_user');
      expect(json['timestamp'], timestamp.toIso8601String());
      expect(json['wasAlarmTriggered'], true);
    });

    test('fromJson 테스트', () {
      final timestampString = '2025-01-15T10:30:00.000';
      final json = {
        'streamUrl': 'https://twitcasting.tv/test_user',
        'userId': 'test_user',
        'timestamp': timestampString,
        'wasAlarmTriggered': false,
      };

      final history = AlarmHistory.fromJson(json);

      expect(history.streamUrl, 'https://twitcasting.tv/test_user');
      expect(history.userId, 'test_user');
      expect(history.timestamp, DateTime.parse(timestampString));
      expect(history.wasAlarmTriggered, false);
    });

    test('fromJson 테스트 - 기본값', () {
      final json = {
        'streamUrl': 'https://twitcasting.tv/test_user',
        'userId': 'test_user',
        'timestamp': '2025-01-15T10:30:00.000',
      };

      final history = AlarmHistory.fromJson(json);

      expect(history.wasAlarmTriggered, true);
    });

    test('JSON 직렬화/역직렬화 왕복 테스트', () {
      final original = AlarmHistory(
        streamUrl: 'https://twitcasting.tv/test_user',
        userId: 'test_user',
        timestamp: DateTime(2025, 1, 15, 10, 30),
        wasAlarmTriggered: false,
      );

      final json = original.toJson();
      final restored = AlarmHistory.fromJson(json);

      expect(restored.streamUrl, original.streamUrl);
      expect(restored.userId, original.userId);
      expect(restored.timestamp, original.timestamp);
      expect(restored.wasAlarmTriggered, original.wasAlarmTriggered);
    });

    group('getFormattedTime 테스트', () {
      test('방금 전 (1분 미만)', () {
        final history = AlarmHistory(
          streamUrl: 'https://twitcasting.tv/test_user',
          userId: 'test_user',
          timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
        );

        expect(history.getFormattedTime(), '방금 전');
      });

      test('N분 전 (1시간 미만)', () {
        final history = AlarmHistory(
          streamUrl: 'https://twitcasting.tv/test_user',
          userId: 'test_user',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        );

        expect(history.getFormattedTime(), '15분 전');
      });

      test('N시간 전 (1일 미만)', () {
        final history = AlarmHistory(
          streamUrl: 'https://twitcasting.tv/test_user',
          userId: 'test_user',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        );

        expect(history.getFormattedTime(), '3시간 전');
      });

      test('N일 전 (7일 미만)', () {
        final history = AlarmHistory(
          streamUrl: 'https://twitcasting.tv/test_user',
          userId: 'test_user',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        );

        expect(history.getFormattedTime(), '2일 전');
      });

      test('절대 시간 (7일 이상)', () {
        final timestamp = DateTime(2025, 1, 1, 14, 30);
        final history = AlarmHistory(
          streamUrl: 'https://twitcasting.tv/test_user',
          userId: 'test_user',
          timestamp: timestamp,
        );

        final formatted = history.getFormattedTime();
        expect(formatted, contains('2025-01-01'));
        expect(formatted, contains('14:30'));
      });

      test('자정 시간 포맷팅', () {
        final timestamp = DateTime(2025, 1, 1, 0, 5);
        final history = AlarmHistory(
          streamUrl: 'https://twitcasting.tv/test_user',
          userId: 'test_user',
          timestamp: timestamp,
        );

        final formatted = history.getFormattedTime();
        expect(formatted, contains('00:05'));
      });
    });

    test('다양한 사용자 ID 테스트', () {
      final history1 = AlarmHistory(
        streamUrl: 'https://twitcasting.tv/user_123',
        userId: 'user_123',
        timestamp: DateTime.now(),
      );

      final history2 = AlarmHistory(
        streamUrl: 'https://twitcasting.tv/starDream',
        userId: 'starDream',
        timestamp: DateTime.now(),
      );

      expect(history1.userId, 'user_123');
      expect(history2.userId, 'starDream');
    });
  });
}
