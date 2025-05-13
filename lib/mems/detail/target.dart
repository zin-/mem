import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/line_chart/states.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/transitions.dart';
import 'package:mem/values/dimens.dart';
import 'package:mem/values/durations.dart';

class TargetText extends ConsumerWidget {
  final int? _memId;

  const TargetText(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.check_circle),
      // 1日20回以下、週40時間以上、1ヶ月に5時間以下みたいな感じ
      title: Text("Less than 20 times per a day"),
      trailing: IconButton(
        onPressed: () => Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MemDetailTargetScreen(_memId),
            transitionsBuilder: detailTransitionsBuilder,
            transitionDuration: defaultTransitionDuration,
            reverseTransitionDuration: defaultTransitionDuration,
          ),
        ),
        icon: Icon(Icons.edit),
      ),
    );
  }
}

class MemDetailTargetScreen extends ConsumerWidget {
  final int? _memId;

  const MemDetailTargetScreen(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    return _MemDetailTargetScreen(
      ref.watch(
        editingMemByMemIdProvider(_memId).select(
          (value) => value.value.name,
        ),
      ),
    );
  }
}

enum TargetType { equalTo, lessThan, moreThan }

enum TargetUnit { count, time }

class _MemDetailTargetScreen extends StatelessWidget {
  final String _memName;

  const _MemDetailTargetScreen(this._memName);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(_memName),
      ),
      body: Padding(
        padding: defaultPadding,
        child: Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton(
              value: TargetType.equalTo.index,
              items: TargetType.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.index,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {},
            ),
            DropdownButton(
              value: TargetUnit.count.index,
              items: TargetUnit.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.index,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {},
            ),
            TextFormField(),
            DropdownButton(
              // aDayが欲しい
              value: Period.aWeek.index,
              items: Period.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.index,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {},
            ),
          ],
        ),
      ),
    );
  }
}
