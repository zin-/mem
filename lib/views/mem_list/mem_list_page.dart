import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/views/mem_list/mem_list_page_states.dart';

class MemListPage extends StatelessWidget {
  const MemListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () => Consumer(
          builder: (context, ref, child) => v(
            {},
            () {
              final allMemAsyncValue = ref.watch(fetchAllMem);
              dev(allMemAsyncValue);

              return Scaffold(
                appBar: AppBar(
                  title: const Text('List'),
                ),
                body: Container(
                  color: Colors.green,
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('check'),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        debug: true,
      );
}
