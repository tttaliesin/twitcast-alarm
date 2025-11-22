package com.twitcast.alarm

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.util.Log

/**
 * 네이티브 알람 플레이어
 * USAGE_ALARM을 사용하여 무음모드/진동모드에서도 알람 재생
 */
class NativeAlarmPlayer(private val context: Context) {
    private var mediaPlayer: MediaPlayer? = null
    private var isPlaying = false

    /**
     * 알람 재생
     * @param volume 볼륨 (0.0 ~ 1.0)
     */
    fun playAlarm(volume: Float) {
        try {
            // 기존 재생 중이면 먼저 중지
            stopAlarm()

            // assets에서 알람 사운드 로드
            val assetFileDescriptor = context.assets.openFd("flutter_assets/assets/war_sound.mp3")

            mediaPlayer = MediaPlayer().apply {
                // USAGE_ALARM 설정: 무음모드에서도 재생됨
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )

                // 데이터 소스 설정
                setDataSource(
                    assetFileDescriptor.fileDescriptor,
                    assetFileDescriptor.startOffset,
                    assetFileDescriptor.length
                )
                assetFileDescriptor.close()

                // 볼륨 설정 (0.0 ~ 1.0)
                setVolume(volume, volume)

                // 반복 재생
                isLooping = true

                // 준비 및 재생
                prepare()
                start()
            }

            isPlaying = true
            Log.d("NativeAlarmPlayer", "✅ 알람 재생 시작 (볼륨: $volume)")
        } catch (e: Exception) {
            Log.e("NativeAlarmPlayer", "❌ 알람 재생 오류: ${e.message}", e)
            isPlaying = false
        }
    }

    /**
     * 알람 중지
     */
    fun stopAlarm() {
        try {
            mediaPlayer?.apply {
                if (isPlaying()) {
                    stop()
                }
                release()
            }
            mediaPlayer = null
            isPlaying = false
            Log.d("NativeAlarmPlayer", "✅ 알람 중지됨")
        } catch (e: Exception) {
            Log.e("NativeAlarmPlayer", "❌ 알람 중지 오류: ${e.message}", e)
        }
    }

    /**
     * 알람 재생 중 여부
     */
    fun isPlaying(): Boolean = isPlaying

    /**
     * 리소스 해제
     */
    fun dispose() {
        stopAlarm()
    }
}
