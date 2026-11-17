import 'package:flutter/rendering.dart';

const _pagePaddingValue = 16.0;
const bottomSheetPadding = EdgeInsets.all(10.0);
const defaultPadding = EdgeInsets.all(_pagePaddingValue);
const pageTopPadding = EdgeInsets.fromLTRB(
  _pagePaddingValue,
  _pagePaddingValue,
  _pagePaddingValue,
  4,
);
const pageBottomPadding = EdgeInsets.fromLTRB(
  _pagePaddingValue,
  0,
  _pagePaddingValue,
  _pagePaddingValue,
);

const zeroHeight = 0.0;
const defaultNavigationBarHeight = 80.0;

const defaultComponentPadding = 4.0;

const cardMargin = EdgeInsets.symmetric(
  horizontal: _pagePaddingValue,
  vertical: defaultComponentPadding,
);
const cardListPadding = EdgeInsets.symmetric(
  vertical: _pagePaddingValue - defaultComponentPadding,
);

const memSelectDialogContentHeightFactor = 1 / 2;

const memPrePostListItemHeight = 60.0;
const _memPrePostListMaxVisibleItemCount = 3;
const memPrePostListMaxHeight =
    memPrePostListItemHeight * _memPrePostListMaxVisibleItemCount;

// 論理px。チャートの1期間（範囲、Min / Max / Avg、チャート）の最大高さ。
// 本文がこれを超えると、超えない高さで複数期間を並べる
const lineChartPeriodMaxHeight = 480.0;
