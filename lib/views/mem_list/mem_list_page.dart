import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/async_value_view.dart';
import 'package:mem/views/mem_list/mem_list_page_states.dart';

class MemListPage extends StatelessWidget {
  const MemListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () => Consumer(
          builder: (context, ref, child) => v(
            {},
            () => Scaffold(
              appBar: AppBar(
                title: const Text('List'),
              ),
              body: AsyncValueView(
                ref.watch(fetchAllMem),
                (List<Mem> allMem) => ListView.builder(
                  itemCount: allMem.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(allMem[index].name),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
