import 'package:flutter_test/flutter_test.dart';
import 'package:twitcast_alarm/models/stream_info.dart';

void main() {
  group('StreamInfo 모델 테스트', () {
    test('기본 생성자 테스트', () {
      final streamInfo = StreamInfo(
        url: 'https://twitcasting.tv/test_user',
        isMonitoring: true,
        isLive: false,
      );

      expect(streamInfo.url, 'https://twitcasting.tv/test_user');
      expect(streamInfo.isMonitoring, true);
      expect(streamInfo.isLive, false);
    });

    test('기본값 테스트', () {
      final streamInfo = StreamInfo(url: 'https://twitcasting.tv/test_user');

      expect(streamInfo.isMonitoring, false);
      expect(streamInfo.isLive, null);
    });

    test('copyWith 테스트 - 일부 필드만 변경', () {
      final original = StreamInfo(
        url: 'https://twitcasting.tv/test_user',
        isMonitoring: false,
        isLive: null,
      );

      final updated = original.copyWith(isMonitoring: true);

      expect(updated.url, 'https://twitcasting.tv/test_user');
      expect(updated.isMonitoring, true);
      expect(updated.isLive, null);
    });

    test('copyWith 테스트 - 모든 필드 변경', () {
      final original = StreamInfo(
        url: 'https://twitcasting.tv/user1',
        isMonitoring: false,
        isLive: null,
      );

      final updated = original.copyWith(
        url: 'https://twitcasting.tv/user2',
        isMonitoring: true,
        isLive: true,
      );

      expect(updated.url, 'https://twitcasting.tv/user2');
      expect(updated.isMonitoring, true);
      expect(updated.isLive, true);
    });

    test('toJson 테스트', () {
      final streamInfo = StreamInfo(
        url: 'https://twitcasting.tv/test_user',
        isMonitoring: true,
        isLive: false,
      );

      final json = streamInfo.toJson();

      expect(json['url'], 'https://twitcasting.tv/test_user');
      expect(json['isMonitoring'], true);
      expect(json['isLive'], false);
    });

    test('toJson 테스트 - null 값', () {
      final streamInfo = StreamInfo(
        url: 'https://twitcasting.tv/test_user',
      );

      final json = streamInfo.toJson();

      expect(json['url'], 'https://twitcasting.tv/test_user');
      expect(json['isMonitoring'], false);
      expect(json['isLive'], null);
    });

    test('fromJson 테스트', () {
      final json = {
        'url': 'https://twitcasting.tv/test_user',
        'isMonitoring': true,
        'isLive': true,
      };

      final streamInfo = StreamInfo.fromJson(json);

      expect(streamInfo.url, 'https://twitcasting.tv/test_user');
      expect(streamInfo.isMonitoring, true);
      expect(streamInfo.isLive, true);
    });

    test('fromJson 테스트 - 누락된 필드 기본값', () {
      final json = {
        'url': 'https://twitcasting.tv/test_user',
      };

      final streamInfo = StreamInfo.fromJson(json);

      expect(streamInfo.url, 'https://twitcasting.tv/test_user');
      expect(streamInfo.isMonitoring, false);
      expect(streamInfo.isLive, null);
    });

    test('fromJson 테스트 - 빈 URL', () {
      final json = <String, dynamic>{};

      final streamInfo = StreamInfo.fromJson(json);

      expect(streamInfo.url, '');
      expect(streamInfo.isMonitoring, false);
      expect(streamInfo.isLive, null);
    });

    test('JSON 직렬화/역직렬화 왕복 테스트', () {
      final original = StreamInfo(
        url: 'https://twitcasting.tv/test_user',
        isMonitoring: true,
        isLive: false,
      );

      final json = original.toJson();
      final restored = StreamInfo.fromJson(json);

      expect(restored.url, original.url);
      expect(restored.isMonitoring, original.isMonitoring);
      expect(restored.isLive, original.isLive);
    });
  });
}
