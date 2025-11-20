package com.twitcast.alarm

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * 스트림 모니터링 백그라운드 서비스
 * Foreground Service로 실행되어 앱이 백그라운드에 있어도 지속적으로 스트림 상태를 확인
 */
class StreamMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var checkRunnable: Runnable? = null
    private val CHANNEL_ID = "stream_monitor_foreground"
    private val NOTIFICATION_ID = 1

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startMonitoring()
            ACTION_STOP -> stopMonitoring()
        }
        return START_STICKY
    }

    private fun startMonitoring() {
        val notification = createNotification("스트림 모니터링 중...")
        startForeground(NOTIFICATION_ID, notification)

        // 30초마다 주기적으로 체크 스케줄링
        checkRunnable = object : Runnable {
            override fun run() {
                // Flutter 앱에 스트림 체크 브로드캐스트 전송
                val intent = Intent(ACTION_CHECK_STREAMS)
                sendBroadcast(intent)

                handler.postDelayed(this, 30000) // 30초
            }
        }
        handler.post(checkRunnable!!)
    }

    private fun stopMonitoring() {
        checkRunnable?.let { handler.removeCallbacks(it) }
        stopForeground(true)
        stopSelf()
    }

    // 알림 채널 생성 (Android 8.0 이상 필수)
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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
    fun updateNotification(text: String) {
        val notification = createNotification(text)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    companion object {
        const val ACTION_START = "com.twitcast.alarm.START_MONITORING"
        const val ACTION_STOP = "com.twitcast.alarm.STOP_MONITORING"
        const val ACTION_CHECK_STREAMS = "com.twitcast.alarm.CHECK_STREAMS"

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
    }
}
