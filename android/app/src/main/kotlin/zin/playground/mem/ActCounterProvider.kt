package zin.playground.mem

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

const val actCount = "act_count"
const val defaultActCount = "?"
const val lastActTime = "last_act_time"
const val defaultLastActTime = "--:--"
const val memName = "mem_name"
const val defaultMemName = "???"
const val uriSchema = "mem"
const val memIdIsNotFound = -11
const val actCountIsNotFound = -12
const val lastActTimeIsNotFound = -13L

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
                    memIdIsNotFound,
                )
                if (memId != memIdIsNotFound) {
                    setOnClickPendingIntent(
                        R.id.widget_container,
                        HomeWidgetBackgroundIntent.getBroadcast(
                            context,
                            Uri.parse(
                                "$uriSchema://${methodChannelName}s" +
                                        "?mem_id=$memId"
                            )
                        )
                    )

                    val actCount = widgetData.getInt(
                        "actCount-$memId",
                        actCountIsNotFound,
                    )
                    setTextViewText(
                        R.id.act_count,
                        if (actCount == actCountIsNotFound)
                            defaultActCount
                        else
                            actCount.toString(),
                    )

                    val lastUpdatedAtSeconds = widgetData.getLong(
                        "lastUpdatedAtSeconds-$memId",
                        lastActTimeIsNotFound,
                    ).let {
                        if (it == lastActTimeIsNotFound) null else java.lang.Double.longBitsToDouble(
                            it
                        ).toLong()
                    }.let {
                        if (it == null)
                            defaultLastActTime
                        else
                            ZonedDateTime.ofInstant(
                                Instant.ofEpochMilli(it),
                                ZoneId.systemDefault(),
                            ).format(
                                DateTimeFormatter.ofLocalizedTime(
                                    FormatStyle.SHORT
                                )
                            ).toString()
                    }
                    setTextViewText(
                        R.id.last_act_time,
                        lastUpdatedAtSeconds,
                    )

                    setTextViewText(
                        R.id.mem_name,
                        widgetData.getString(
                            "memName-$memId",
                            defaultMemName,
                        ),
                    )
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

}