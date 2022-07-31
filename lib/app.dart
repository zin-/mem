import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/views/mem_list/mem_list_page.dart';

class MemApplication extends StatelessWidget {
  const MemApplication({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () => ProviderScope(
          child: MaterialApp(
            title: 'Mem',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: MemListPage(),
          ),
        ),
      );
}
