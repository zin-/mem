package zin.playground.mem

import android.app.AlarmManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.Manifest
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "zin.playground.mem"
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    // 再登録は mem ごとに要求する。設定画面は戻るまで一度だけ開く
    private var exactAlarmSettingsOpen = false

    override fun onResume() {
        super.onResume()
        exactAlarmSettingsOpen = false
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )

        channel.setMethodCallHandler { call, result ->
            if (call.method == "requestPermissions") {
                requestPermissions(
                    call.argument<ArrayList<String>>("permissionNames"),
                    result,
                )
            } else {
                result.notImplemented()
            }
        }
    }

    private fun requestPermissions(
        permissionNames: ArrayList<String>?,
        result: MethodChannel.Result,
    ) {
        if (permissionNames is ArrayList<String>) {
            val permissions = mutableListOf<String>()

            if (Build.VERSION.SDK_INT >= 28) {
                if (permissionNames.contains("foregroundService") && !isPermissionGranted(
                        Manifest
                            .permission
                            .FOREGROUND_SERVICE
                    )
                ) {
                    permissions.add(Manifest.permission.FOREGROUND_SERVICE)
                }
            }

            if (Build.VERSION.SDK_INT >= 29) {
                if (permissionNames.contains("activityRecognition")
                    && !isPermissionGranted(
                        Manifest.permission.ACTIVITY_RECOGNITION
                    )
                ) {
                    permissions.add(Manifest.permission.ACTIVITY_RECOGNITION)
                }
            }

            if (Build.VERSION.SDK_INT >= 33) {
                if (permissionNames.contains("notification") &&
                    !isPermissionGranted(
                        Manifest
                            .permission
                            .POST_NOTIFICATIONS
                    )
                ) {
                    permissions.add(Manifest.permission.POST_NOTIFICATIONS)
                }
            }

            if (Build.VERSION.SDK_INT >= 34) {
                if (permissionNames.contains("foregroundServiceHealth")
                    && !isPermissionGranted(
                        Manifest.permission
                            .FOREGROUND_SERVICE_HEALTH
                    )
                ) {
                    permissions.add(Manifest.permission.FOREGROUND_SERVICE_HEALTH)
                }
            }

            // SCHEDULE_EXACT_ALARM はランタイム権限のダイアログでは付与できない
            val exactAlarmMissing = permissionNames.contains("scheduleExactAlarm") &&
                !canScheduleExactAlarms()

            if (permissions.isEmpty() && !exactAlarmMissing) {
                result.success(true)
            } else if (permissions.isNotEmpty()) {
                val results = ActivityCompat.requestPermissions(
                    this,
                    permissions.toTypedArray(),
                    PERMISSION_REQUEST_CODE,
                )
                println("results: $results")
                result.success(false)
            } else {
                if (!exactAlarmSettingsOpen) {
                    exactAlarmSettingsOpen = true
                    startActivity(
                        Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                            data = Uri.parse("package:$packageName")
                        },
                    )
                }
                result.success(false)
            }
        } else {
            result.success(false)
        }
    }

    private fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true
        }
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        return alarmManager.canScheduleExactAlarms()
    }

    private fun isPermissionGranted(
        permission: String,
    ): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            permission,
        ) == PackageManager.PERMISSION_GRANTED
    }
}
