import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/scroll_controllable_widget.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/transitions.dart';
import 'package:mem/values/durations.dart';

class ShowNewMemFab extends ScrollControllableWidget {
  const ShowNewMemFab(
    super.scrollController, {
    super.key,
  });

  @override
  State<ShowNewMemFab> createState() => _ShowNewMemFabState();
}

class _ShowNewMemFabState extends State<ShowNewMemFab>
    with ScrollControllableStateMixin {
  @override
  Widget build(BuildContext context) => v(
        () {
          final isHidden = scrollDirection == ScrollDirection.reverse;

          return AnimatedSlide(
            offset: isHidden ? const Offset(0, 1) : Offset.zero,
            duration: defaultTransitionDuration,
            child: AnimatedOpacity(
              opacity: isHidden ? 0.0 : 1.0,
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
          );
        },
        {
          "scrollDirection": scrollDirection,
        },
      );
}
