package com.nananeko.warranty_manager

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.ContextCompat
import androidx.core.content.IntentCompat
import androidx.core.content.PackageManagerCompat
import androidx.core.content.UnusedAppRestrictionsConstants
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createChannels()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HEALTH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "unusedRestrictionsOn" -> readUnusedRestrictions(result)
                    "openNotificationSettings" -> {
                        startActivity(notificationSettingsIntent())
                        result.success(null)
                    }
                    "openUnusedRestrictionsSettings" -> {
                        startActivity(
                            IntentCompat.createManageUnusedAppRestrictionsIntent(this, packageName),
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Channels used by push notifications: reminders and releases, apart so
    // that either can be silenced alone. Creating an existing channel is a no-op.
    private fun createChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channels = listOf(
            "warranties" to R.string.notification_channel_warranties,
            "updates" to R.string.notification_channel_updates,
        )
        for ((id, name) in channels) {
            manager.createNotificationChannel(
                NotificationChannel(id, getString(name), NotificationManager.IMPORTANCE_HIGH),
            )
        }
    }

    // Whether Android may reset the permissions of this app, or hibernate it,
    // once it goes unused for months. Hibernation also stops FCM, even high
    // priority messages, and a warranty app is rarely opened.
    private fun readUnusedRestrictions(result: MethodChannel.Result) {
        val future = PackageManagerCompat.getUnusedAppRestrictionsStatus(this)
        future.addListener(
            {
                val status = try {
                    future.get()
                } catch (_: Exception) {
                    UnusedAppRestrictionsConstants.ERROR
                }
                result.success(status in RESTRICTED)
            },
            ContextCompat.getMainExecutor(this),
        )
    }

    private fun notificationSettingsIntent(): Intent =
        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)

    private companion object {
        const val HEALTH_CHANNEL = "warranty_manager/reminder_health"
        val RESTRICTED = setOf(
            UnusedAppRestrictionsConstants.API_30_BACKPORT,
            UnusedAppRestrictionsConstants.API_30,
            UnusedAppRestrictionsConstants.API_31,
        )
    }
}
