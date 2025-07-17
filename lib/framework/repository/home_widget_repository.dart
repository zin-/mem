import 'package:flutter/foundation.dart';
import 'package:mem/features/acts/counter/home_widget_accessor.dart';
import 'package:mem/framework/repository/home_widget_entity.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/features/logger/log_service.dart';

abstract class HomeWidgetRepository<ENTITY extends HomeWidgetEntity,
    SAVED extends SavedHomeWidgetEntity> extends RepositoryV2<ENTITY> {
  static final _homeWidgetAccessor =
      defaultTargetPlatform == TargetPlatform.android
          ? HomeWidgetAccessor()
          : null;

  SAVED pack(Map<String, dynamic> map);

  Future<void> receive(
    ENTITY entity,
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
    ENTITY entity,
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
