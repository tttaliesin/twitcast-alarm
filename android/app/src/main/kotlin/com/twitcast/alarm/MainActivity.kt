package com.twitcast.alarm

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 메인 액티비티
 * Flutter와 Android 네이티브 코드 간의 플랫폼 채널 통신을 처리
 */
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.twitcast.alarm/background"
    private var methodChannel: MethodChannel? = null

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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundService" -> {
                    StreamMonitorService.start(this)
                    result.success(true)
                }
                "stopBackgroundService" -> {
                    StreamMonitorService.stop(this)
                    result.success(true)
                }
                "isBackgroundServiceRunning" -> {
                    val isRunning = isServiceRunning(StreamMonitorService::class.java)
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

        // Register broadcast receiver
        val filter = IntentFilter(StreamMonitorService.ACTION_CHECK_STREAMS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(streamCheckReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(streamCheckReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(streamCheckReceiver)
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
}
