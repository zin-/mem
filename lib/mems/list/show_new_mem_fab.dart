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

class _ShowNewMemFabState extends State<ShowNewMemFab> {
  bool _isHidden = false;

  @override
  void initState() => v(
        () {
          super.initState();
          widget._scrollController.addListener(_toggleShowOnScroll);
        },
        {"_isHidden": _isHidden},
      );

  @override
  void dispose() => v(
        () {
          widget._scrollController.removeListener(_toggleShowOnScroll);
          super.dispose();
        },
      );

  @override
  Widget build(BuildContext context) => v(
        () => AnimatedSlide(
          offset: _isHidden ? const Offset(0, 1) : Offset.zero,
          duration: defaultTransitionDuration,
          child: AnimatedOpacity(
            opacity: _isHidden ? 0 : 1,
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
        {"_isHidden": _isHidden},
      );

  void _toggleShowOnScroll() => v(
        () {
          switch (widget._scrollController.position.userScrollDirection) {
            case ScrollDirection.idle:
              break;
            case ScrollDirection.forward:
              _isHidden ? setState(() => _isHidden = false) : null;
              break;
            case ScrollDirection.reverse:
              _isHidden ? null : setState(() => _isHidden = true);
              break;
          }
        },
        {
          "_isHidden": _isHidden,
          "userScrollDirection":
              widget._scrollController.position.userScrollDirection,
        },
      );
}
