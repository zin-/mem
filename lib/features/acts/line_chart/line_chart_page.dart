import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/features/acts/line_chart/line_chart_period.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/acts/period_menu_item.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/values/dimens.dart';

// PageView の先頭。今の期間で、その offset も同じ
const _currentPeriodPage = 0;

// 本文が最大高さ以下なら、期間を分割しない
const _onePeriodCount = 1;

class ActLineChartPage extends ConsumerStatefulWidget {
  final int memId;

  const ActLineChartPage({
    super.key,
    required this.memId,
  });

  @override
  ConsumerState<ActLineChartPage> createState() => _ActLineChartPageState();
}

class _ActLineChartPageState extends ConsumerState<ActLineChartPage> {
  Period _period = Period.aWeek;
  AggregationType _aggregationType = AggregationType.count;

  // 期間の種類を変えたら今の期間へ戻す。PageStorage が前のページを戻さない
  PageController? _pageController;

  // 期間の種類を変えた直後。未接続のコントローラは今の期間で作り直す
  int? _forcedPage;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _selectPeriod(Period period) {
    setState(() {
      _period = period;
      _forcedPage = _currentPeriodPage;
    });
    final controller = _pageController;
    if (controller != null && controller.hasClients) {
      controller.jumpToPage(_currentPeriodPage);
    }
  }

  int _visiblePeriodCount(double bodyHeight) {
    if (bodyHeight <= lineChartPeriodMaxHeight) {
      return _onePeriodCount;
    }
    return (bodyHeight / lineChartPeriodMaxHeight).ceil();
  }

  PageController _pageControllerFor(int periodCount) {
    final fraction = 1 / periodCount;
    final current = _pageController;
    final forcedPage = _forcedPage;
    if (current != null &&
        current.viewportFraction == fraction &&
        (forcedPage == null || current.hasClients)) {
      _forcedPage = null;
      return current;
    }

    // viewportFraction はコンストラクタでしか渡せない
    final page = forcedPage ??
        (current != null && current.hasClients
            ? (current.page?.round() ?? _currentPeriodPage)
            : _currentPeriodPage);
    _forcedPage = null;
    final next = PageController(
      initialPage: page,
      keepPage: false,
      viewportFraction: fraction,
    );
    _pageController = next;
    if (current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        current.dispose();
      });
    }
    return next;
  }

  @override
  Widget build(BuildContext context) => v(
        () {
          final startOfDay = ref.watch(preferenceProvider(startOfDayKey));

          return _buildScaffold(context, startOfDay);
        },
        {
          'memId': widget.memId,
        },
      );

  Widget _buildScaffold(
    BuildContext context,
    TimeOfDay startOfDay,
  ) {
    final memName = ref.read(
      editingMemByMemIdProvider(widget.memId).select((v) => v.value.name),
    );

    Widget periodPage(int offset, PageController? pageController) =>
        LineChartPeriod(
          memId: widget.memId,
          period: _period,
          offset: offset,
          aggregationType: _aggregationType,
          startOfDay: startOfDay,
          pageController: pageController,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('$memName : ${_aggregationType.name}'),
        actions: [
          PopupMenuButton<Period>(
            itemBuilder: (context) => <PopupMenuEntry<Period>>[
              ...AggregationType.values.map(
                (e) => PopupMenuItem<Period>(
                  enabled: e != _aggregationType,
                  onTap: () => setState(() => _aggregationType = e),
                  child: Text(e.name),
                ),
              ),
              const PopupMenuDivider(),
              ...Period.values.map(
                (e) => PeriodMenuItem(
                  period: e,
                  selected: _period,
                  onTap: () => _selectPeriod(e),
                ),
              ),
            ],
            tooltip: buildL10n(context).timePeriod,
            padding: defaultPadding,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Padding(
        padding: defaultPadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_period == Period.all) {
              // 比べる隣がないので 1 枚。最大高さを超えた分は下を空ける
              final height = constraints.maxHeight <= lineChartPeriodMaxHeight
                  ? constraints.maxHeight
                  : lineChartPeriodMaxHeight;
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: height,
                  child: periodPage(_currentPeriodPage, null),
                ),
              );
            }

            final controller = _pageControllerFor(
              _visiblePeriodCount(constraints.maxHeight),
            );
            return PageView.builder(
              scrollDirection: Axis.vertical,
              controller: controller,
              // 今の期間を上端に揃える。先のページほど過去なので offset は負
              padEnds: false,
              itemBuilder: (context, index) => periodPage(-index, controller),
            );
          },
        ),
      ),
    );
  }
}
