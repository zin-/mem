import 'package:flutter/foundation.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';

import 'act_counter.dart';
import 'home_widget_accessor.dart';

// TODO constantsとして別で定義する
// see android\app\src\main\kotlin\zin\playground\mem\ActCounterConfigure.kt
const methodChannelName = 'zin.playground.mem/act_counter';
const initializeMethodName = 'initialize';
const widgetProviderName = 'ActCounterProvider';

class ActCounterRepository extends RepositoryV1<ActCounter, void> {
  final HomeWidgetAccessor? _homeWidgetAccessor;

  @override
  Future<void> receive(ActCounter entity) => v(
        () async {
          final homeWidgetId = await _homeWidgetAccessor?.initialize(
            methodChannelName,
            initializeMethodName,
          );

          if (homeWidgetId != null) {
            InitializedActCounter(homeWidgetId, entity)
                .widgetData()
                .forEach((key, value) async {
              await _homeWidgetAccessor?.saveWidgetData(key, value);
            });

            await _homeWidgetAccessor?.updateWidget(widgetProviderName);
          }
        },
        entity,
      );

  Future<ActCounter> replace(ActCounter entity) => v(
        () async {
          entity.widgetData().forEach((key, value) async {
            await _homeWidgetAccessor?.saveWidgetData(key, value);
          });

          await _homeWidgetAccessor?.updateWidget(widgetProviderName);

          return entity;
        },
        entity,
      );

  ActCounterRepository._(this._homeWidgetAccessor);

  static ActCounterRepository? _instance;

  factory ActCounterRepository() => _instance ??= ActCounterRepository._(
        defaultTargetPlatform == TargetPlatform.android
            ? HomeWidgetAccessor()
            : null,
      );
}
