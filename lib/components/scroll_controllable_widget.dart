import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:mem/logger/log_service.dart';

abstract class ScrollControllableWidget extends StatefulWidget {
  final ScrollController scrollController;

  const ScrollControllableWidget(
    this.scrollController, {
    super.key,
  });
}

mixin ScrollControllableStateMixin<T extends ScrollControllableWidget>
    on State<T> {
  ScrollDirection scrollDirection = ScrollDirection.idle;

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
        },
        {
          "latestScrollDirection": scrollDirection,
          "userScrollDirection":
              widget.scrollController.position.userScrollDirection,
        },
      );
}
