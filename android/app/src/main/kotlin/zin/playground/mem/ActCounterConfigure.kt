package zin.playground.mem

import io.flutter.embedding.android.FlutterActivity

const val entryPointFunctionName = "launchActCounterConfigure"

class ActCounterConfigure : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String {
        return entryPointFunctionName
    }
//    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//        MethodChannel(
//            flutterEngine.dartExecutor.binaryMessenger,
//            "jp.zin.mem/act_counter"
//        ).setMethodCallHandler { call, result ->
//            if (call.method == "initialize") {
//                result.success(initialize())
//            } else {
//                result.notImplemented()
//            }
//            finish()
//        }
//    }
//
//    private fun initialize(): Int {
//        val appWidgetId = intent?.extras?.getInt(
//            AppWidgetManager.EXTRA_APPWIDGET_ID,
//            AppWidgetManager.INVALID_APPWIDGET_ID
//        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
//
//        val appWidgetManager: AppWidgetManager =
//            AppWidgetManager.getInstance(context)
//
//        RemoteViews(
//            context.packageName,
//            R.layout.act_counter
//        ).also { views ->
//            appWidgetManager.updateAppWidget(
//                appWidgetId,
//                views
//            )
//        }
//
//        setResult(RESULT_OK)
//        return appWidgetId
//    }
}