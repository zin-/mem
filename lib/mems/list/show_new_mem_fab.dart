import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/gui/constants.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/mems/list/page.dart';

class ShowNewMemFab extends StatefulWidget {
  final ScrollController _scrollController;

  const ShowNewMemFab(this._scrollController, {Key? key}) : super(key: key);

  @override
  State<ShowNewMemFab> createState() => _ShowNewMemFabState();
}

class _ShowNewMemFabState extends State<ShowNewMemFab>
    with SingleTickerProviderStateMixin {
  bool _show = true;

  @override
  void initState() {
    super.initState();
    widget._scrollController.addListener(() => v(
          () {
            if (widget._scrollController.position.userScrollDirection ==
                    ScrollDirection.forward &&
                !_show) {
              setState(() {
                _show = true;
              });
            } else if (widget._scrollController.position.userScrollDirection ==
                    ScrollDirection.reverse &&
                _show) {
              setState(() {
                _show = false;
              });
            }
          },
          {'_show': _show},
        ));
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
}
