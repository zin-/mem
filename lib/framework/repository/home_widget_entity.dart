import 'package:mem/framework/repository/entity.dart';

mixin HomeWidgetEntity on EntityV1 {
  String get methodChannelName;

  String get initializeMethodName;

  String get widgetProviderName;

  Map<String, dynamic> get toWidgetData;
}
mixin SavedHomeWidgetEntity on HomeWidgetEntity {
  late final int homeWidgetId;
}
