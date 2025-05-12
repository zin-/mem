import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TargetText extends ConsumerWidget {
  const TargetText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.check_circle),
      // 1日20回以下、週40時間以上、1ヶ月に5時間以下みたいな感じ
      title: Text("20 times per a day"),
      trailing: Icon(Icons.edit),
    );
  }
}
