package zin.playground.mem

import android.appwidget.AppWidgetManager
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * {@see} lib/main.dart
 */
const val entryPointFunctionName = "launchActCounterConfigure"
const val methodChannelName = "zin.playground.mem/act_counter"
const val initializeMethodName = "initialize"

class ActCounterConfigure : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String {
        return entryPointFunctionName
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName
        ).setMethodCallHandler { call, result ->
            if (call.method == initializeMethodName) {
                result.success(initialize())
            } else {
                result.notImplemented()
            }
            finish()
        }
    }

    private fun initialize(): Int {
        val appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        val appWidgetManager: AppWidgetManager =
            AppWidgetManager.getInstance(context)

        RemoteViews(
            context.packageName,
            R.layout.act_counter
        ).also { views ->
            appWidgetManager.updateAppWidget(
                appWidgetId,
                views
            )
        }

        setResult(RESULT_OK)
        return appWidgetId
    }
}