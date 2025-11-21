import 'dart:convert';
import 'package:http/http.dart' as http;

/// 트위캐스트 API 통신을 담당하는 서비스
class TwitcastApi {
  /// 트위캐스트 스트림이 라이브 상태인지 확인
  /// yt-dlp와 유사하게 스트림 정보를 가져오는 함수
  /// 네트워크 오류 시 자동으로 재시도
  static Future<bool> isStreamLive(
    String url, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _checkStreamLiveInternal(url);
      } catch (e) {
        if (attempt == maxRetries) {
          print('❌ 최대 재시도 횟수($maxRetries) 도달. 스트림 확인 실패: $e');
          return false;
        }
        print('⚠️ 시도 $attempt/$maxRetries 실패: $e');
        print('🔄 ${retryDelay.inSeconds}초 후 재시도...');
        await Future.delayed(retryDelay);
      }
    }
    return false;
  }

  /// 내부 스트림 확인 메서드 (재시도 로직에서 사용)
  static Future<bool> _checkStreamLiveInternal(String url) async {
    try {
      // URL 유효성 검사
      if (!url.contains('twitcasting.tv')) {
        print('❌ 잘못된 트위캐스트 URL: $url');
        throw Exception('Invalid Twitcast URL');
      }

      // URL에서 사용자 ID 추출
      // URL 형식:
      // - https://twitcasting.tv/USER_ID
      // - https://twitcasting.tv/USER_ID/movie/MOVIE_ID
      final userId = _extractUserId(url);
      if (userId.isEmpty) {
        print('❌ URL에서 사용자 ID를 추출할 수 없음: $url');
        throw Exception('Could not extract user ID from URL');
      }

      print('🔍 사용자 스트림 확인 중: $userId');

      // 먼저 API 메서드 시도 (더 빠르고 안정적)
      try {
        final apiResult = await checkStreamApiMethod(url);
        print('✅ API 메서드 결과: $apiResult');
        return apiResult;
      } catch (apiError) {
        print('⚠️ API 메서드 실패, HTML 메서드 시도: $apiError');
      }

      // Fallback: 메인 페이지에서 라이브 표시자 확인
      final response = await http.get(
        Uri.parse('https://twitcasting.tv/$userId'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 HTTP 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body;
        print('📄 응답 본문 길이: ${body.length}');

        // HTML에서 라이브 스트림 표시자 확인
        // 스트림이 라이브 상태일 때 페이지에 특정 마커가 포함됨:
        // - "is_live":true 또는 "isOnLive":true
        // - tw-player-stream-is-live 클래스
        // - movie_id 페이지 내 존재

        final hasIsLiveTrue = body.contains('"is_live":true');
        final hasTwPlayerLive = body.contains('tw-player-stream-is-live');
        final hasDataOnlive = body.contains('data-is-onlive="true"');
        final hasIsOnLiveTrue = body.contains('"isOnLive":true');
        final hasMovieId = body.contains('movie_id');

        print('🔎 라이브 표시자:');
        print('  - is_live:true = $hasIsLiveTrue');
        print('  - tw-player-stream-is-live = $hasTwPlayerLive');
        print('  - data-is-onlive = $hasDataOnlive');
        print('  - isOnLive:true = $hasIsOnLiveTrue');
        print('  - movie_id = $hasMovieId');

        final isLive = hasIsLiveTrue || hasTwPlayerLive || hasDataOnlive ||
                      hasIsOnLiveTrue || hasMovieId;

        print(isLive ? '🟢 스트림 라이브 상태!' : '🔴 스트림 오프라인');
        return isLive;
      } else if (response.statusCode == 404) {
        print('❌ 사용자를 찾을 수 없음 (404)');
        return false;
      } else {
        print('⚠️ 예상치 못한 상태 코드: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 스트림 상태 확인 오류: $e');
      // 재시도 로직을 위해 예외를 재전송
      rethrow;
    }
  }

  /// 트위캐스트 URL에서 사용자 ID 추출
  static String _extractUserId(String url) {
    try {
      // 프로토콜과 www 제거
      url = url.replaceAll('https://', '').replaceAll('http://', '').replaceAll('www.', '');

      // twitcasting.tv/ 제거
      if (url.startsWith('twitcasting.tv/')) {
        url = url.substring('twitcasting.tv/'.length);
      }

      // 사용자 ID 추출 (첫 번째 세그먼트)
      final parts = url.split('/');
      if (parts.isNotEmpty) {
        return parts[0];
      }

      return '';
    } catch (e) {
      print('사용자 ID 추출 오류: $e');
      return '';
    }
  }

  /// 대체 방법: 스트림 API를 직접 가져오기 시도
  /// 이 메서드는 스트림에 대한 JSON 데이터를 가져오려고 시도
  static Future<bool> checkStreamApiMethod(String url) async {
    try {
      final userId = _extractUserId(url);
      if (userId.isEmpty) {
        print('❌ API: 빈 사용자 ID');
        return false;
      }

      print('🔄 사용자에 대해 API 메서드 시도 중: $userId');

      // streamserver API 엔드포인트 시도
      final apiUrl = 'https://twitcasting.tv/streamserver.php?target=$userId&mode=client';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': 'https://twitcasting.tv/$userId',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 API 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('📄 API 응답 본문: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

        final data = json.decode(response.body);

        // movie 객체가 존재하고 live가 true인지 확인
        if (data is Map && data.containsKey('movie')) {
          final movie = data['movie'];
          if (movie != null && movie is Map) {
            // movie 객체의 'live' 필드 확인
            final isLive = movie['live'] == true;
            print(isLive ? '🟢 API: 스트림 라이브 상태 (live=true)' : '🔴 API: 스트림 오프라인 (live=false)');
            return isLive;
          }
        }
      }

      print('⚠️ API: 유효한 응답 없음');
      return false;
    } catch (e) {
      print('❌ API 메서드 오류: $e');
      rethrow; // fallback을 트리거하기 위해 재전송
    }
  }
}
