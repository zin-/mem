import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/mem_list/mem_list_page.dart';
import 'package:mem/views/mem_list/mem_list_page_states.dart';

class ShowNewMemFab extends StatefulWidget {
  final ScrollController _scrollController;

  ShowNewMemFab(this._scrollController, {Key? key}) : super(key: key) {
    dev('ShowNewMemFab');
  }

  @override
  State<ShowNewMemFab> createState() => _ShowNewMemFabState();
}

class _ShowNewMemFabState extends State<ShowNewMemFab>
    with SingleTickerProviderStateMixin {
  _ShowNewMemFabState() {
    dev('_ShowNewMemFabState');
    // _animationController = AnimationController(
    //   value: _show ? 1.0 : 0.0,
    //   duration: const Duration(milliseconds: 250),
    //   vsync: this,
    // );
  }

  // late final AnimationController _animationController;
  // late final Animation<double> _expandAnimation;
  bool _show = true;

  @override
  void initState() {
    super.initState();
    // TODO: implement initState
    dev('initState');
    widget._scrollController.addListener(() {
      dev('listen');
      if (widget._scrollController.position.userScrollDirection ==
              ScrollDirection.forward &&
          !_show) {
        dev(1);
        setState(() {
          _show = true;
        });
      } else if (widget._scrollController.position.userScrollDirection ==
              ScrollDirection.reverse &&
          _show) {
        dev(2);
        setState(() {
          _show = false;
        });
      }
    });
  }

  @override
  void dispose() {
    dev('dispose');
    // _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => v(
        {'_show': _show},
        () {
          const duration = Duration(milliseconds: 750);

          return AnimatedSlide(
            offset: _show ? Offset.zero : Offset(0, 2),
            duration: duration,
            child: AnimatedOpacity(
              opacity: _show ? 1 : 0,
              duration: duration,
              child: Consumer(
                builder: (context, ref, child) {
                  return FloatingActionButton(
                    onPressed: () {
                      dev('onPressed');
                      setState(() {
                        _show = !_show;
                      });
                    },
                    // onPressed: () => showMemDetailPage(context, ref, null),
                    child: const Icon(Icons.add),
                  );
                  const duration = Duration(milliseconds: 750);
                  final showFab = !ref.watch(onScrollReversedProvider);
                  return AnimatedSlide(
                    offset: showFab ? Offset.zero : Offset(0, 2),
                    duration: duration,
                    child: AnimatedOpacity(
                      opacity: showFab ? 1 : 0,
                      duration: duration,
                      child: FloatingActionButton(
                        onPressed: () => showMemDetailPage(context, ref, null),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  );

                  return FloatingActionButton(
                    onPressed: () => showMemDetailPage(context, ref, null),
                    child: const Icon(Icons.add),
                  );
                },
              ),
            ),
          );
        },
        debug: true,
      );
}
