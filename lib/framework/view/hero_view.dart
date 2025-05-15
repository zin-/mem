import 'package:flutter/material.dart';
import 'package:mem/features/logger/log_service.dart';

class HeroView extends StatelessWidget {
  final String _tag;
  final Widget _child;

  const HeroView(
    this._tag,
    this._child, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () => Hero(
          tag: _tag,
          child: Material(
            color: Colors.transparent,
            child: _child,
          ),
        ),
        {'_tag': _tag, '_child': _child},
      );
}

String heroTag(String tag, dynamic id) => '$tag${id == null ? '' : '-$id'}';
