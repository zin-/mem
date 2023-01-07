package zin.playground.mem

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

const val actCount = "act_count"
const val defaultActCount = "?"
const val lastActTime = "last_act_time"
const val defaultLastActTime = "??:??"
const val memName = "mem_name"
const val defaultMemName = "???"
//const val uriSchema = "mem"

class ActCounterProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(
                context.packageName,
                R.layout.act_counter
            ).apply {
                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                // Swap Title Text by calling Dart Code in the Background
                setTextViewText(
                    R.id.act_count,
                    widgetData.getString(actCount, defaultActCount)
                )
//                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
//                    context,
//                    Uri.parse("${uriSchema}://titleClicked")
//                )
//                setOnClickPendingIntent(R.id.widget_title, backgroundIntent)

                setTextViewText(
                    R.id.last_act_time,
                    widgetData.getString(lastActTime, defaultLastActTime)
                )
//                // Detect App opened via Click inside Flutter
//                val pendingIntentWithData = HomeWidgetLaunchIntent.getActivity(
//                    context,
//                    MainActivity::class.java,
//                    Uri.parse("${uriSchema}://message?message=$message")
//                )
//                setOnClickPendingIntent(
//                    R.id.widget_message,
//                    pendingIntentWithData
//                )

                setTextViewText(
                    R.id.mem_name,
                    widgetData.getString(memName, defaultMemName)
                )
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

}