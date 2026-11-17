import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/features/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/acts/period_menu_item.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/framework/view/async_value_view.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/values/dimens.dart';

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

  // 期間の種類を変えたらページ 0。PageStorage が前のページを戻さない
  final PageController _pageController = PageController(keepPage: false);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectPeriod(Period period) {
    setState(() => _period = period);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
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

    Widget page(int offset) => _PeriodPage(
          memId: widget.memId,
          period: _period,
          offset: offset,
          aggregationType: _aggregationType,
          startOfDay: startOfDay,
          pageController: _period == Period.all ? null : _pageController,
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
        child: _period == Period.all
            ? page(0)
            : PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                // ページ 0 が今の期間。先のページほど過去なので offset は負
                itemBuilder: (context, index) => page(-index),
              ),
      ),
    );
  }
}

class _PeriodPage extends ConsumerWidget {
  final int memId;
  final Period period;
  final int offset;
  final AggregationType aggregationType;
  final TimeOfDay startOfDay;
  final PageController? pageController;

  const _PeriodPage({
    required this.memId,
    required this.period,
    required this.offset,
    required this.aggregationType,
    required this.startOfDay,
    this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Iterable<Act> actsIn(DateAndTimePeriod? selectedPeriod) => ref
        .watch(actListProvider(memId).select(
          (value) => value.where((e) {
            if (selectedPeriod is! WithStartAndEnd) {
              return true;
            }
            final start = e.value.period?.start;
            return start != null && selectedPeriod.includesStart(start);
          }),
        ))
        .map((e) => e.value);

    final selectedPeriod = period.toPeriod(
      DateAndTime.now(),
      startOfDay,
      offset: offset,
    );

    return AsyncValueView(
      loadActListProvider(memId, period, offset),
      (_) {
        final actsSummary = ActsSummary(
          actsIn(selectedPeriod),
          aggregationType,
          period: selectedPeriod,
          startOfDay: startOfDay,
        );
        final chart = LineChartWrapper(
          actsSummary,
          aggregationType.format,
        );
        final paging = pageController;

        return Flex(
          direction: Axis.vertical,
          children: [
            if (selectedPeriod is WithStartAndEnd)
              Text(
                selectedPeriod.formatCompactRange(
                  MaterialLocalizations.of(context),
                ),
                textAlign: TextAlign.center,
              ),
            _SummaryStats(actsSummary, aggregationType.format),
            Expanded(
              child: paging == null
                  ? chart
                  : _ChartVerticalDrag(
                      controller: paging,
                      child: chart,
                    ),
            ),
          ],
        );
      },
    );
  }
}

// fl_chart の pan が縦ドラッグを取る。タップのツールチップは残し、縦の移動だけページへ渡す
class _ChartVerticalDrag extends StatefulWidget {
  final PageController controller;
  final Widget child;

  const _ChartVerticalDrag({
    required this.controller,
    required this.child,
  });

  @override
  State<_ChartVerticalDrag> createState() => _ChartVerticalDragState();
}

class _ChartVerticalDragState extends State<_ChartVerticalDrag> {
  Drag? _drag;
  Offset? _start;
  VelocityTracker? _tracker;

  @override
  void dispose() {
    _drag?.cancel();
    _drag = null;
    super.dispose();
  }

  void _down(PointerDownEvent event) {
    _drag?.cancel();
    _drag = null;
    _start = event.position;
    _tracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _move(PointerMoveEvent event) {
    final start = _start;
    final tracker = _tracker;
    if (start == null || tracker == null) {
      return;
    }
    tracker.addPosition(event.timeStamp, event.position);
    if (_drag == null) {
      final moved = event.position - start;
      if (moved.dy.abs() < kTouchSlop || moved.dy.abs() <= moved.dx.abs()) {
        return;
      }
      if (!widget.controller.hasClients) {
        return;
      }
      _drag = widget.controller.position.drag(
        DragStartDetails(
          sourceTimeStamp: event.timeStamp,
          globalPosition: start,
          kind: event.kind,
        ),
        () => _drag = null,
      );
    }
    _drag?.update(
      DragUpdateDetails(
        sourceTimeStamp: event.timeStamp,
        globalPosition: event.position,
        delta: Offset(0, event.delta.dy),
        primaryDelta: event.delta.dy,
      ),
    );
  }

  void _up(PointerUpEvent event) {
    final drag = _drag;
    final tracker = _tracker;
    _drag = null;
    _start = null;
    _tracker = null;
    if (drag == null || tracker == null) {
      return;
    }
    tracker.addPosition(event.timeStamp, event.position);
    final dy = tracker.getVelocity().pixelsPerSecond.dy;
    drag.end(
      DragEndDetails(
        primaryVelocity: dy,
        velocity: Velocity(pixelsPerSecond: Offset(0, dy)),
      ),
    );
  }

  void _cancel(PointerCancelEvent event) {
    _drag?.cancel();
    _drag = null;
    _start = null;
    _tracker = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: widget.child,
      );
}

class _SummaryStats extends StatelessWidget {
  final ActsSummary _actsSummary;
  final String Function(double) _formatValue;

  const _SummaryStats(this._actsSummary, this._formatValue);

  @override
  Widget build(BuildContext context) => Padding(
        padding: defaultPadding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Flex(
            direction: Axis.horizontal,
            spacing: 4.0,
            children: [
              const Text('Min : '),
              Text(_formatValue(_actsSummary.min)),
              const Text('Max : '),
              Text(_formatValue(_actsSummary.max)),
              const Text('Avg : '),
              Text(_formatValue(_actsSummary.average)),
            ],
          ),
        ),
      );
}
