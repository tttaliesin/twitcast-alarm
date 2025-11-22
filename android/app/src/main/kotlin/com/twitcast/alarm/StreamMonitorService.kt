package com.twitcast.alarm

import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * 스트림 모니터링 백그라운드 서비스
 * Foreground Service로 실행되어 앱이 백그라운드에 있어도 지속적으로 스트림 상태를 확인
 */
class StreamMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var checkRunnable: Runnable? = null
    private val CHANNEL_ID = "stream_monitor_foreground"
    private val NOTIFICATION_ID = 1
    private var checkIntervalSeconds = 30 // 기본값
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var nativeAlarmPlayer: NativeAlarmPlayer? = null
    private val streamStatusMap = mutableMapOf<String, Boolean>() // URL -> 이전 라이브 상태

    // 알람 중지 브로드캐스트 리시버
    private val alarmStopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_STOP_ALARM -> {
                    Log.d(TAG, "🔴 알람 중지 브로드캐스트 수신됨")
                    nativeAlarmPlayer?.stopAlarm()
                }
                ACTION_GET_ALARM_STATUS -> {
                    Log.d(TAG, "📊 알람 상태 요청 수신됨")
                    val isPlaying = nativeAlarmPlayer?.isPlaying() ?: false
                    val responseIntent = Intent(ACTION_ALARM_STATUS_RESPONSE)
                    responseIntent.putExtra("isPlaying", isPlaying)
                    sendBroadcast(responseIntent)
                    Log.d(TAG, "📤 알람 상태 응답 전송: isPlaying=$isPlaying")
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        serviceInstance = this
        createNotificationChannel()
        try {
            nativeAlarmPlayer = NativeAlarmPlayer(applicationContext)
            Log.d(TAG, "✅ StreamMonitorService 생성됨")
        } catch (e: Exception) {
            Log.e(TAG, "❌ NativeAlarmPlayer 초기화 실패: ${e.message}", e)
        }

        // 알람 중지 브로드캐스트 리시버 등록
        val filter = IntentFilter()
        filter.addAction(ACTION_STOP_ALARM)
        filter.addAction(ACTION_GET_ALARM_STATUS)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(alarmStopReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(alarmStopReceiver, filter)
        }
        Log.d(TAG, "✅ 알람 중지 리시버 등록 완료")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "🔵 onStartCommand 호출됨 - action: ${intent?.action}")
        when (intent?.action) {
            ACTION_START -> startMonitoring()
            ACTION_STOP -> stopMonitoring()
            else -> {
                Log.w(TAG, "⚠️ 알 수 없는 action: ${intent?.action}")
                // action이 null이어도 서비스 시작
                startMonitoring()
            }
        }
        return START_STICKY
    }

    private fun startMonitoring() {
        try {
            Log.d(TAG, "📍 startMonitoring() 시작")

            // 먼저 Foreground로 올리기 (Android 8.0+ 필수)
            val notification = createNotification("서비스 시작 중...")
            Log.d(TAG, "📍 startForeground() 호출 전")
            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "✅ startForeground() 호출 완료")

            // SharedPreferences에서 설정값 로드
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            // Flutter는 int를 Long으로 저장하므로 Long으로 읽어서 Int로 변환
            checkIntervalSeconds = prefs.getLong("flutter.check_interval_seconds", 30L).toInt()
            Log.d(TAG, "📍 설정값 로드 완료: ${checkIntervalSeconds}초 간격")

            // 알림 텍스트 업데이트
            updateNotification("스트림 모니터링 중... (${checkIntervalSeconds}초 간격)")

            Log.d(TAG, "🚀 백그라운드 모니터링 시작 (${checkIntervalSeconds}초 간격)")

            // 설정된 주기로 체크 스케줄링
            checkRunnable = object : Runnable {
                override fun run() {
                    try {
                        // Flutter 앱에 브로드캐스트 전송 (앱이 실행 중이면 Flutter가 처리)
                        val intent = Intent(ACTION_CHECK_STREAMS)
                        sendBroadcast(intent)

                        // 네이티브에서도 직접 체크 (앱이 죽었을 때 대비)
                        checkStreamsNatively()

                        handler.postDelayed(this, checkIntervalSeconds * 1000L)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ 스트림 체크 실행 오류: ${e.message}", e)
                        handler.postDelayed(this, checkIntervalSeconds * 1000L)
                    }
                }
            }
            handler.post(checkRunnable!!)
            Log.d(TAG, "✅ 스케줄링 설정 완료")
        } catch (e: Exception) {
            Log.e(TAG, "❌ 백그라운드 모니터링 시작 실패: ${e.message}", e)
            e.printStackTrace()
        }
    }

    /**
     * 네이티브 코드에서 직접 스트림 체크
     * Flutter 앱이 죽었을 때도 동작하도록
     */
    private fun checkStreamsNatively() {
        serviceScope.launch {
            try {
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                // Flutter SharedPreferences는 double을 String으로 저장하는 경우가 있음
                val alarmVolume = try {
                    prefs.getFloat("flutter.alarm_volume", 1.0f)
                } catch (e: ClassCastException) {
                    // String으로 저장된 경우
                    prefs.getString("flutter.alarm_volume", "1.0")?.toFloatOrNull() ?: 1.0f
                }
                Log.d(TAG, "📍 네이티브 스트림 체크 시작 (볼륨: $alarmVolume)")

                // SharedPreferences에서 모니터링 중인 스트림 URL 읽기
                var checkedCount = 0
                var anyLive = false // 하나라도 라이브 중인지 추적

                for (i in 0..3) {
                    val url = prefs.getString("flutter.stream_${i}_url", "") ?: ""
                    val isMonitoring = prefs.getBoolean("flutter.stream_${i}_monitoring", false)

                    Log.d(TAG, "📍 스트림 $i: url='$url', monitoring=$isMonitoring")

                    if (url.isNotEmpty() && isMonitoring) {
                        checkedCount++
                        Log.d(TAG, "📡 스트림 체크 중: $url")
                        val isLive = checkIfStreamIsLive(url)

                        // 하나라도 라이브면 추적
                        if (isLive) {
                            anyLive = true
                        }

                        // 현재 라이브 상태를 SharedPreferences에 저장 (Flutter와 공유)
                        prefs.edit().putBoolean("flutter.stream_${i}_is_live", isLive).apply()

                        // SharedPreferences에서 알림 여부 확인 (Flutter와 공유)
                        val alreadyNotified = prefs.getBoolean("flutter.stream_${i}_already_notified", false)

                        Log.d(TAG, "📍 스트림 상태: isLive=$isLive, alreadyNotified=$alreadyNotified")

                        // 라이브 상태이고 아직 알림을 보내지 않았다면 알람
                        if (isLive && !alreadyNotified) {
                            Log.d(TAG, "🔴 라이브 감지! 알람 실행: $url (볼륨: $alarmVolume)")
                            withContext(Dispatchers.Main) {
                                try {
                                    nativeAlarmPlayer?.playAlarm(alarmVolume)
                                    Log.d(TAG, "✅ 알람 재생 완료")

                                    // Flutter 앱에 알람 재생 상태 브로드캐스트 (명시적)
                                    val alarmIntent = Intent(ACTION_ALARM_PLAYING).apply {
                                        putExtra("streamUrl", url)
                                        setPackage(packageName) // 명시적 브로드캐스트
                                    }
                                    sendBroadcast(alarmIntent)
                                    Log.d(TAG, "📢 Flutter에 알람 재생 상태 전송: $url")

                                    // 알림 보냈음을 SharedPreferences에 저장
                                    prefs.edit().putBoolean("flutter.stream_${i}_already_notified", true).apply()
                                    Log.d(TAG, "💾 알림 상태 저장: stream_${i}_already_notified = true")
                                } catch (e: Exception) {
                                    Log.e(TAG, "❌ 알람 재생 실패: ${e.message}", e)
                                }
                            }
                        } else if (!isLive && alreadyNotified) {
                            Log.d(TAG, "⚫ 라이브 종료: $url - 알림 상태 리셋")
                            // 라이브 종료 시 알림 상태 리셋
                            prefs.edit().putBoolean("flutter.stream_${i}_already_notified", false).apply()
                        } else if (isLive && alreadyNotified) {
                            Log.d(TAG, "🔴 이미 라이브 중 (알림 이미 보냄): $url")
                        } else {
                            Log.d(TAG, "⚪ 오프라인: $url")
                        }

                        streamStatusMap[url] = isLive
                    }
                }

                // 알림 상태 업데이트
                if (anyLive) {
                    updateNotification("🔴 라이브 감지! (${checkedCount}개 확인 중)")
                } else {
                    updateNotification("모니터링 중... (${checkedCount}개 확인 중)")
                }

                Log.d(TAG, "✅ 네이티브 스트림 체크 완료: ${checkedCount}개 확인됨, anyLive=$anyLive")
            } catch (e: Exception) {
                Log.e(TAG, "❌ 네이티브 스트림 체크 오류: ${e.message}", e)
                e.printStackTrace()
            }
        }
    }

    /**
     * 트위캐스트 스트림이 라이브 중인지 확인
     * Flutter의 checkStreamApiMethod와 동일한 로직 사용
     */
    private suspend fun checkIfStreamIsLive(streamUrl: String): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // URL 유효성 검사
                if (!streamUrl.contains("twitcasting.tv")) {
                    Log.e(TAG, "❌ 잘못된 트위캐스트 URL: $streamUrl")
                    return@withContext false
                }

                // URL에서 사용자 ID 추출
                val userId = extractUserId(streamUrl)
                if (userId.isEmpty()) {
                    Log.e(TAG, "❌ URL에서 사용자 ID를 추출할 수 없음: $streamUrl")
                    return@withContext false
                }

                Log.d(TAG, "🔍 사용자 스트림 확인 중: $userId")

                // 먼저 API 메서드 시도 (더 빠르고 안정적)
                try {
                    val apiResult = checkStreamApiMethod(userId)
                    Log.d(TAG, "✅ API 메서드 결과: $apiResult")
                    return@withContext apiResult
                } catch (apiError: Exception) {
                    Log.w(TAG, "⚠️ API 메서드 실패, HTML 메서드 시도: ${apiError.message}")
                }

                // Fallback: HTML 메서드
                val url = URL("https://twitcasting.tv/$userId")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                connection.setRequestProperty("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8")
                connection.setRequestProperty("Accept-Language", "en-US,en;q=0.9")

                Log.d(TAG, "📡 HTTP 응답: ${connection.responseCode}")

                val responseCode = connection.responseCode
                if (responseCode == 200) {
                    val html = connection.inputStream.bufferedReader().use { it.readText() }
                    connection.disconnect()

                    Log.d(TAG, "📄 응답 본문 길이: ${html.length}")

                    // HTML에서 라이브 스트림 표시자 확인
                    val hasIsLiveTrue = html.contains("\"is_live\":true", ignoreCase = true)
                    val hasTwPlayerLive = html.contains("tw-player-stream-is-live", ignoreCase = true)
                    val hasDataOnlive = html.contains("data-is-onlive=\"true\"", ignoreCase = true)
                    val hasIsOnLiveTrue = html.contains("\"isOnLive\":true", ignoreCase = true)
                    val hasMovieId = html.contains("movie_id", ignoreCase = true)

                    Log.d(TAG, "🔎 라이브 표시자:")
                    Log.d(TAG, "  - is_live:true = $hasIsLiveTrue")
                    Log.d(TAG, "  - tw-player-stream-is-live = $hasTwPlayerLive")
                    Log.d(TAG, "  - data-is-onlive = $hasDataOnlive")
                    Log.d(TAG, "  - isOnLive:true = $hasIsOnLiveTrue")
                    Log.d(TAG, "  - movie_id = $hasMovieId")

                    val isLive = hasIsLiveTrue || hasTwPlayerLive || hasDataOnlive || hasIsOnLiveTrue || hasMovieId

                    Log.d(TAG, if (isLive) "🟢 스트림 라이브 상태!" else "🔴 스트림 오프라인")
                    isLive
                } else if (responseCode == 404) {
                    Log.e(TAG, "❌ 사용자를 찾을 수 없음 (404)")
                    connection.disconnect()
                    false
                } else {
                    Log.w(TAG, "⚠️ 예상치 못한 상태 코드: $responseCode")
                    connection.disconnect()
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ 스트림 상태 확인 오류: ${e.message}", e)
                false
            }
        }
    }

    /**
     * 트위캐스트 URL에서 사용자 ID 추출
     */
    private fun extractUserId(url: String): String {
        return try {
            // 프로토콜과 www 제거
            var cleanUrl = url.replace("https://", "").replace("http://", "").replace("www.", "")

            // twitcasting.tv/ 제거
            if (cleanUrl.startsWith("twitcasting.tv/")) {
                cleanUrl = cleanUrl.substring("twitcasting.tv/".length)
            }

            // 사용자 ID 추출 (첫 번째 세그먼트)
            val parts = cleanUrl.split("/")
            if (parts.isNotEmpty()) {
                parts[0]
            } else {
                ""
            }
        } catch (e: Exception) {
            Log.e(TAG, "사용자 ID 추출 오류: ${e.message}")
            ""
        }
    }

    /**
     * API 메서드로 스트림 상태 확인
     * streamserver.php API 엔드포인트 사용
     */
    private suspend fun checkStreamApiMethod(userId: String): Boolean {
        return withContext(Dispatchers.IO) {
            Log.d(TAG, "🔄 사용자에 대해 API 메서드 시도 중: $userId")

            val apiUrl = "https://twitcasting.tv/streamserver.php?target=$userId&mode=client"
            val url = URL(apiUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
            connection.setRequestProperty("Accept", "application/json, text/javascript, */*; q=0.01")
            connection.setRequestProperty("Accept-Language", "en-US,en;q=0.9")
            connection.setRequestProperty("Referer", "https://twitcasting.tv/$userId")

            Log.d(TAG, "📡 API 응답: ${connection.responseCode}")

            val responseCode = connection.responseCode
            if (responseCode == 200) {
                val responseBody = connection.inputStream.bufferedReader().use { it.readText() }
                connection.disconnect()

                val preview = if (responseBody.length > 200) responseBody.substring(0, 200) else responseBody
                Log.d(TAG, "📄 API 응답 본문: $preview...")

                // JSON 파싱
                val jsonObject = JSONObject(responseBody)

                // movie 객체가 존재하고 live가 true인지 확인
                if (jsonObject.has("movie")) {
                    val movie = jsonObject.getJSONObject("movie")
                    val isLive = movie.optBoolean("live", false)
                    Log.d(TAG, if (isLive) "🟢 API: 스트림 라이브 상태 (live=true)" else "🔴 API: 스트림 오프라인 (live=false)")
                    isLive
                } else {
                    Log.w(TAG, "⚠️ API: movie 객체 없음")
                    connection.disconnect()
                    false
                }
            } else {
                connection.disconnect()
                throw Exception("HTTP $responseCode")
            }
        }
    }

    private fun stopMonitoring() {
        Log.d(TAG, "🛑 백그라운드 모니터링 중지")
        checkRunnable?.let { handler.removeCallbacks(it) }
        serviceScope.cancel()
        nativeAlarmPlayer?.stopAlarm()
        stopForeground(true)
        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceInstance = null
        try {
            unregisterReceiver(alarmStopReceiver)
            Log.d(TAG, "✅ 알람 중지 리시버 해제 완료")
        } catch (e: Exception) {
            Log.e(TAG, "⚠️ 리시버 해제 오류: ${e.message}")
        }
        serviceScope.cancel()
        nativeAlarmPlayer?.dispose()
        Log.d(TAG, "❌ StreamMonitorService 종료됨")
    }

    // 알림 채널 생성 (Android 8.0 이상 필수)
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d(TAG, "📍 알림 채널 생성 시작")
            try {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "스트림 모니터",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "백그라운드에서 스트림 모니터링을 유지합니다"
                    setShowBadge(false)
                }

                val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.createNotificationChannel(channel)
                Log.d(TAG, "✅ 알림 채널 생성 완료")
            } catch (e: Exception) {
                Log.e(TAG, "❌ 알림 채널 생성 실패: ${e.message}", e)
            }
        } else {
            Log.d(TAG, "📍 Android 8.0 미만 - 알림 채널 불필요")
        }
    }

    // Foreground 알림 생성
    private fun createNotification(contentText: String): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("트위캐스트 알람")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    // 알림 텍스트 업데이트
    private fun updateNotification(text: String) {
        val notification = createNotification(text)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    companion object {
        private const val TAG = "StreamMonitorService"
        const val ACTION_START = "com.twitcast.alarm.START_MONITORING"
        const val ACTION_STOP = "com.twitcast.alarm.STOP_MONITORING"
        const val ACTION_CHECK_STREAMS = "com.twitcast.alarm.CHECK_STREAMS"
        const val ACTION_STOP_ALARM = "com.twitcast.alarm.STOP_ALARM"
        const val ACTION_ALARM_PLAYING = "com.twitcast.alarm.ALARM_PLAYING"
        const val ACTION_GET_ALARM_STATUS = "com.twitcast.alarm.GET_ALARM_STATUS"
        const val ACTION_ALARM_STATUS_RESPONSE = "com.twitcast.alarm.ALARM_STATUS_RESPONSE"

        private var serviceInstance: StreamMonitorService? = null

        fun start(context: Context) {
            val intent = Intent(context, StreamMonitorService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, StreamMonitorService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun isAlarmPlaying(): Boolean {
            return serviceInstance?.nativeAlarmPlayer?.isPlaying() ?: false
        }
    }
}
