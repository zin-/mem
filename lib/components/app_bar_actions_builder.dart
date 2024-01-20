import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

import 'nullable_widget_builder.dart';

/// [https://m3.material.io/components/top-app-bar/guidelines#b1b64842-7d88-4c3f-8ffb-4183fe648c9e]
const maxShowCount = 3;

class AppBarActionsBuilder {
  final List<Widget Function()> _widgetBuilders;

  AppBarActionsBuilder(this._widgetBuilders);

  List<Widget>? build() => d(
        () {
          final widgetList = _widgetBuilders
              .map((e) => NullableWidgetBuilder(e).build())
              .whereType<Widget>()
              .toList(growable: false);

          // TODO 最終的なactionsの数によって、適切な数に省略する
          //  actionsには上限となる数がある、これは画面サイズの制約と認知・操作負荷によるものがある
          //  TODO 4超の場合、先頭から2つを残して残りをPopupMenuに押し込む
          //    この際、IconButtonではなく、PopupMenuItemに変換する必要がある
          //    TODO 元のwidgetを新しいクラスにして、以下の機能を実装する
          //    - IconButtonとPopupMenuItemに切り替えられるように実装する
          //    - buildする前に表示するかの判定をしたい
          //

          return widgetList;
        },
      );
}
