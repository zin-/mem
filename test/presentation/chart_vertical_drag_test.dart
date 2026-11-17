import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/line_chart/chart_vertical_drag.dart';

const _name = 'ChartVerticalDrag test';

// px/秒。ページ送りの速度閾値より大きいので、離したページの隣へスナップする
const _flingSpeed = 1000.0;

// px。テスト画面（高さ 600）の1ページより短い。超えると2ページ進む
const _pageFlingDistance = 300.0;

// Y が負だと指は上へ動く。上へ払うと隣のページへ進む
const _verticalFling = Offset(0, -_pageFlingDistance);

// X だけ動く。縦の移動が無いのでページは進まない
const _horizontalFling = Offset(_pageFlingDistance, 0);

// 今のページと隣。2枚ないと進んだことが分からない
const _pageCount = 2;

// ページ番号。払う前
const _currentPage = 0.0;

// ページ番号。縦に1回払った隣
const _nextPage = 1.0;

// PageView 自身のドラッグを外す。縦の移動は ChartVerticalDrag だけが渡す
const _pagePhysics = NeverScrollableScrollPhysics();

// 不透明な面。ポインタが当たり、縦ドラッグの対象になる
const _hitTarget = ColoredBox(color: Colors.white);

void main() {
  group(_name, () {
    testWidgets(
      'advances to the next page on a vertical fling.',
      (tester) async {
        final controller = await _pump(tester);

        await _fling(tester, _verticalFling);

        expect(controller.page, _nextPage);
      },
    );

    testWidgets(
      'stays on the page on a horizontal fling.',
      (tester) async {
        final controller = await _pump(tester);

        await _fling(tester, _horizontalFling);

        expect(controller.page, _currentPage);
      },
    );
  });
}

Future<PageController> _pump(WidgetTester tester) async {
  final controller = PageController();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: controller,
        physics: _pagePhysics,
        itemCount: _pageCount,
        itemBuilder: (context, _) => ChartVerticalDrag(
          controller: controller,
          child: _hitTarget,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _fling(WidgetTester tester, Offset offset) async {
  await tester.fling(
    find.byType(ChartVerticalDrag).hitTestable().first,
    offset,
    _flingSpeed,
  );
  await tester.pumpAndSettle();
}
