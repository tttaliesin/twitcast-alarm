package com.twitcast.alarm

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 메인 액티비티
 * Flutter와 Android 네이티브 코드 간의 플랫폼 채널 통신을 처리
 */
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.twitcast.alarm/background"
    private val ALARM_CHANNEL = "com.twitcast.alarm/native_alarm"
    private val BATTERY_CHANNEL = "com.twitcast.alarm/battery"
    private var methodChannel: MethodChannel? = null
    private var alarmChannel: MethodChannel? = null
    private var batteryChannel: MethodChannel? = null

    companion object {
        private const val TAG = "MainActivity"
    }

    // 스트림 체크 브로드캐스트 리시버
    // 백그라운드 서비스에서 스트림 체크가 필요할 때 이 리시버가 호출됨
    private val streamCheckReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == StreamMonitorService.ACTION_CHECK_STREAMS) {
                // Flutter에 스트림 체크 요청 전달
                methodChannel?.invokeMethod("checkStreams", null)
            }
        }
    }

    // 알람 재생 브로드캐스트 리시버
    // 백그라운드 서비스에서 알람이 재생될 때 Flutter에 알림
    private val alarmPlayingReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == StreamMonitorService.ACTION_ALARM_PLAYING) {
                val streamUrl = intent.getStringExtra("streamUrl") ?: ""
                Log.d(TAG, "🔴 백그라운드 알람 재생 감지: $streamUrl")
                // Flutter에 알람 재생 상태 전달
                methodChannel?.invokeMethod("onAlarmPlaying", mapOf("streamUrl" to streamUrl))
            }
        }
    }

    // 알람 상태 응답 리시버
    // 백그라운드 서비스의 알람 재생 상태를 받음
    private val alarmStatusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == StreamMonitorService.ACTION_ALARM_STATUS_RESPONSE) {
                val isPlaying = intent.getBooleanExtra("isPlaying", false)
                Log.d(TAG, "📊 알람 상태 응답 수신: isPlaying=$isPlaying")
                if (isPlaying) {
                    // Flutter에 알람 재생 상태 전달
                    methodChannel?.invokeMethod("onAlarmPlaying", mapOf("streamUrl" to ""))
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 백그라운드 서비스 채널
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundService" -> {
                    Log.d(TAG, "🔵 startBackgroundService 호출됨")
                    try {
                        StreamMonitorService.start(this)
                        Log.d(TAG, "✅ StreamMonitorService.start() 호출 완료")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ startBackgroundService 실패: ${e.message}", e)
                        result.error("START_FAILED", e.message, null)
                    }
                }
                "stopBackgroundService" -> {
                    Log.d(TAG, "🔵 stopBackgroundService 호출됨")
                    try {
                        StreamMonitorService.stop(this)
                        Log.d(TAG, "✅ StreamMonitorService.stop() 호출 완료")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ stopBackgroundService 실패: ${e.message}", e)
                        result.error("STOP_FAILED", e.message, null)
                    }
                }
                "isBackgroundServiceRunning" -> {
                    val isRunning = isServiceRunning(StreamMonitorService::class.java)
                    Log.d(TAG, "📍 isBackgroundServiceRunning: $isRunning")
                    result.success(isRunning)
                }
                "updateNotification" -> {
                    val text = call.argument<String>("text") ?: "Monitoring..."
                    // Note: This would require a reference to the service
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 네이티브 알람 채널 - 백그라운드 서비스로 중지 요청만 전달
        alarmChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
        alarmChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "stopAlarm" -> {
                    Log.d(TAG, "🔵 stopAlarm 호출됨 - 백그라운드 서비스 알람 중지")
                    // 백그라운드 서비스의 알람 중지
                    try {
                        if (StreamMonitorService.isAlarmPlaying()) {
                            Log.d(TAG, "🔴 백그라운드 서비스 알람 재생 중 - 브로드캐스트 전송")
                            val intent = Intent(StreamMonitorService.ACTION_STOP_ALARM).apply {
                                setPackage(packageName) // 명시적 브로드캐스트
                            }
                            sendBroadcast(intent)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ 백그라운드 알람 중지 실패: ${e.message}", e)
                    }

                    Log.d(TAG, "✅ 알람 중지 완료")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 배터리 최적화 채널
        batteryChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
        batteryChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    val isIgnoring = isIgnoringBatteryOptimizations()
                    result.success(isIgnoring)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Register broadcast receivers
        val streamCheckFilter = IntentFilter(StreamMonitorService.ACTION_CHECK_STREAMS)
        val alarmPlayingFilter = IntentFilter(StreamMonitorService.ACTION_ALARM_PLAYING)
        val alarmStatusFilter = IntentFilter(StreamMonitorService.ACTION_ALARM_STATUS_RESPONSE)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(streamCheckReceiver, streamCheckFilter, Context.RECEIVER_NOT_EXPORTED)
            registerReceiver(alarmPlayingReceiver, alarmPlayingFilter, Context.RECEIVER_NOT_EXPORTED)
            registerReceiver(alarmStatusReceiver, alarmStatusFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(streamCheckReceiver, streamCheckFilter)
            registerReceiver(alarmPlayingReceiver, alarmPlayingFilter)
            registerReceiver(alarmStatusReceiver, alarmStatusFilter)
        }
        Log.d(TAG, "✅ 브로드캐스트 리시버 등록 완료")
    }

    override fun onResume() {
        super.onResume()
        // 앱이 포그라운드로 돌아올 때 백그라운드 서비스의 알람 상태 확인
        Log.d(TAG, "📱 onResume - 알람 상태 확인")

        // Flutter Engine이 준비될 때까지 대기 후 상태 확인
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            val isPlaying = StreamMonitorService.isAlarmPlaying()
            Log.d(TAG, "📊 백그라운드 알람 상태: isPlaying=$isPlaying")
            if (isPlaying) {
                // Flutter에 알람 재생 상태 전달
                methodChannel?.invokeMethod("onAlarmPlaying", mapOf("streamUrl" to ""))
            }
        }, 500) // 500ms 대기
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(streamCheckReceiver)
            unregisterReceiver(alarmPlayingReceiver)
            unregisterReceiver(alarmStatusReceiver)
        } catch (e: Exception) {
            // Receiver might not be registered
        }
    }

    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        @Suppress("DEPRECATION")
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                return true
            }
        }
        return false
    }

    // 배터리 최적화가 비활성화되어 있는지 확인
    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            return powerManager.isIgnoringBatteryOptimizations(packageName)
        }
        return true
    }

    // 배터리 최적화 예외 요청
    @Suppress("DEPRECATION")
    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }
    }
}
