import 'package:flutter/foundation.dart';
import 'package:mem/act_counter/home_widget_accessor.dart';
import 'package:mem/framework/repository/home_widget_entity.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';

abstract class HomeWidgetRepository<E extends HomeWidgetEntity,
    Saved extends SavedHomeWidgetEntity> extends Repository<E> {
  static final _homeWidgetAccessor =
      defaultTargetPlatform == TargetPlatform.android
          ? HomeWidgetAccessor()
          : null;

  Saved pack(Map<String, dynamic> map);

  Future<void> receive(
    E entity,
  ) =>
      v(
        () async {
          final homeWidgetId = await _homeWidgetAccessor?.initialize(
            entity.methodChannelName,
            entity.initializeMethodName,
          );

          if (homeWidgetId != null) {
            final saved = pack(entity.toMap
              ..addAll({
                'homeWidgetId': homeWidgetId,
              }));

            saved.toWidgetData.forEach(
              (key, value) async =>
                  await _homeWidgetAccessor?.saveWidgetData(key, value),
            );
            await _homeWidgetAccessor?.updateWidget(saved.widgetProviderName);
          }
        },
        {
          'entity': entity,
        },
      );

  Future<void> replace(
    E entity,
  ) =>
      v(
        () async {
          entity.toWidgetData.forEach((key, value) async {
            await _homeWidgetAccessor?.saveWidgetData(key, value);
          });

          await _homeWidgetAccessor?.updateWidget(entity.widgetProviderName);
        },
        {
          'entity': entity,
        },
      );
}
