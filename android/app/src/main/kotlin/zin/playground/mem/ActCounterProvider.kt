package zin.playground.mem

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.DateFormat
import java.text.SimpleDateFormat
import java.time.Instant
import java.util.*

const val actCount = "act_count"
const val defaultActCount = "?"
const val lastActTime = "last_act_time"
const val defaultLastActTime = "??:??"
const val memName = "mem_name"
const val defaultMemName = "???"
const val uriSchema = "mem"

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
                val memId = widgetData.getInt(
                    "memId-$appWidgetId",
                    -1,
                )
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse(
                        "$uriSchema://${methodChannelName}s" +
                                "?mem_id=$memId"
                    )
                )
                setOnClickPendingIntent(R.id.widget_container, backgroundIntent)

                setTextViewText(
                    R.id.act_count,
                    widgetData.getInt(
                        "actCount-$memId",
                        -1,
                    ).toString(),
                )

                setTextViewText(
                    R.id.last_act_time,
                    widgetData.getInt(
                        "lastUpdatedAt-$memId",
                        -1,
                    ).let {
                        if (it == 0) {
                            "--:--"
                        } else {
//                            throw Error(it.toString())
//                            it.toString()
                            SimpleDateFormat
                                .getTimeInstance(DateFormat.SHORT)
                                .format(
                                    Date.from(
                                        Instant.ofEpochMilli(
                                            it.toLong() * 1000
                                        )
                                    )
//                                    ZonedDateTime.ofInstant(
//                                        Instant.ofEpochMilli(it),
//                                        ZoneId.systemDefault(),
//                                    )
                                )
//                            SimpleDateFormat
//                                .getTimeInstance(
//                                    DateFormat.SHORT,
//                                    Locale.getDefault(),
//                                )
//                                .format(it)
//                            Calendar.getInstance().apply {
//                                timeInMillis = it
//                            }.let {
//                                SimpleDateFormat
//                                    .getTimeInstance(DateFormat.SHORT)
//                                    .format(it.time)
//                            }
                        }
                    },
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
                    widgetData.getString("memName-$memId", defaultMemName),
                )
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

}