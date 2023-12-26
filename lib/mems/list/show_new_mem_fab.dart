import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/transitions.dart';
import 'package:mem/values/durations.dart';

class ShowNewMemFab extends StatefulWidget {
  final ScrollController _scrollController;

  const ShowNewMemFab(this._scrollController, {Key? key}) : super(key: key);

  @override
  State<ShowNewMemFab> createState() => _ShowNewMemFabState();
}

class _ShowNewMemFabState extends State<ShowNewMemFab>
    with SingleTickerProviderStateMixin {
  bool _show = true;

  void _toggleShowOnScroll() => v(
        () {
          switch (widget._scrollController.position.userScrollDirection) {
            case ScrollDirection.idle:
              break;
            case ScrollDirection.forward:
              setState(() => _show = true);
              break;
            case ScrollDirection.reverse:
              setState(() => _show = false);
              break;
          }
        },
        {'_show': _show},
      );

  @override
  void initState() {
    super.initState();
    widget._scrollController.addListener(_toggleShowOnScroll);
  }

  @override
  Widget build(BuildContext context) => v(
        () => AnimatedSlide(
          offset: _show ? Offset.zero : const Offset(0, 1),
          duration: defaultTransitionDuration,
          child: AnimatedOpacity(
            opacity: _show ? 1 : 0,
            duration: defaultTransitionDuration,
            child: Consumer(
              builder: (context, ref, child) {
                return FloatingActionButton(
                  onPressed: () => showMemDetailPage(context, ref, null),
                  child: const Icon(Icons.add),
                );
              },
            ),
          ),
        ),
        {'_show': _show},
      );

  @override
  void dispose() => v(
        () {
          widget._scrollController.removeListener(_toggleShowOnScroll);
          super.dispose();
        },
      );
}
