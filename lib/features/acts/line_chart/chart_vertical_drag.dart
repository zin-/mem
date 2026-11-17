import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

// fl_chart の pan が縦ドラッグを取る。タップのツールチップは残し、縦の移動だけページへ渡す
class ChartVerticalDrag extends StatefulWidget {
  final PageController controller;
  final Widget child;

  const ChartVerticalDrag({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<ChartVerticalDrag> createState() => _ChartVerticalDragState();
}

class _ChartVerticalDragState extends State<ChartVerticalDrag> {
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
