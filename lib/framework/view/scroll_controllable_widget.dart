import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:mem/logger/log_service.dart';

abstract class ScrollControllableWidget extends StatefulWidget {
  final ScrollController scrollController;
  final double shouldNotifyScrollRatio;

  const ScrollControllableWidget(
    this.scrollController, {
    this.shouldNotifyScrollRatio = 0.8,
    super.key,
  });
}

mixin ScrollControllableStateMixin<T extends ScrollControllableWidget>
    on State<T> {
  ScrollDirection scrollDirection = ScrollDirection.idle;
  double pixels = 0.0;
  double maxScrollExtent = 0.0;

  @override
  void initState() => v(
        () {
          super.initState();
          widget.scrollController.addListener(_onScrolled);
        },
      );

  @override
  void dispose() => v(
        () {
          widget.scrollController.removeListener(_onScrolled);
          super.dispose();
        },
      );

  void _onScrolled() => v(
        () {
          if (scrollDirection !=
              widget.scrollController.position.userScrollDirection) {
            setState(() {
              scrollDirection =
                  widget.scrollController.position.userScrollDirection;
            });
          }

          if (widget.scrollController.position.pixels >
              widget.scrollController.position.maxScrollExtent *
                  widget.shouldNotifyScrollRatio) {
            setState(() {
              pixels = widget.scrollController.position.pixels;
              maxScrollExtent =
                  widget.scrollController.position.maxScrollExtent;
            });
          }
        },
        {
          "latestScrollDirection": scrollDirection,
          "userScrollDirection":
              widget.scrollController.position.userScrollDirection,
        },
      );
}
