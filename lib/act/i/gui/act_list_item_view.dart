import 'package:flutter/material.dart';
import 'package:mem/logger/i/api.dart';

import '../../core/act.dart';

class ActListItemView extends StatelessWidget {
  final Act act;

  const ActListItemView(this.act, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'act': act},
        () {
          return Text(act.toString());
        },
      );
}
