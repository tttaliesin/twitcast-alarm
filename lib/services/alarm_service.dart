import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// 알람 사운드 재생/중지를 담당하는 서비스
class AlarmService {
  static AudioPlayer? _audioPlayer;
  static bool _isPlaying = false;

  /// 지정된 볼륨으로 알람 사운드 재생
  static Future<void> playAlarm(double volume) async {
    try {
      // 기존 재생 중이면 먼저 중지
      if (_isPlaying) {
        await stopAlarm();
      }

      // 새 AudioPlayer 인스턴스 생성
      _audioPlayer = AudioPlayer();

      // 볼륨 설정 (0.0 ~ 1.0)
      await _audioPlayer!.setVolume(volume);

      // 반복 재생 설정
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);

      // 알람 사운드 재생
      // assets에서 로드 시도
      try {
        await _audioPlayer!.play(AssetSource('war_sound.mp3'));
        _isPlaying = true;
        print('✅ war_sound.mp3 재생 시작');
      } catch (e) {
        print('❌ war_sound.mp3 재생 오류: $e');
        // 시스템 비프음으로 fallback
        await _playSystemBeep();
        _isPlaying = false;
      }
    } catch (e) {
      print('❌ 알람 재생 오류: $e');
      _isPlaying = false;
    }
  }

  /// 알람 중지
  static Future<void> stopAlarm() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      _isPlaying = false;
      print('✅ 알람 중지됨');
    } catch (e) {
      print('❌ 알람 중지 오류: $e');
    }
  }

  /// 현재 알람이 재생 중인지 확인
  static bool get isPlaying => _isPlaying;

  /// 시스템 삐 소리를 재생하는 fallback 메서드
  static Future<void> _playSystemBeep() async {
    // 간단한 알림음 생성
    // assets 폴더에 war_sound.mp3 파일이 있어야 함
    await SystemChannels.platform.invokeMethod('SystemSound.play');
  }

  /// 오디오 플레이어 리소스 해제
  static Future<void> dispose() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.dispose();
      _audioPlayer = null;
    }
  }
}
