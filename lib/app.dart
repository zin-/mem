import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/mem_detail/mem_detail_page.dart';

class MemApplication extends StatelessWidget {
  const MemApplication({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Mem',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MemDetailPage(1),
      ),
    );
  }
}
