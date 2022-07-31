import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/async_value_view.dart';
import 'package:mem/views/mem_detail/mem_detail_page.dart';
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
                  itemBuilder: (context, index) {
                    final mem = allMem[index];
                    return ListTile(
                      title: Text(mem.name),
                      onTap: () => Navigator.of(context)
                          .push(buildRouteToMemDetailPage(mem.id)),
                    );
                  },
                ),
              ),
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.save_alt),
                onPressed: () =>
                    Navigator.of(context).push(buildRouteToMemDetailPage(null)),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
            ),
          ),
        ),
      );
}

Route buildRouteToMemDetailPage(int? memId) => v(
      {'memId': memId},
      () => PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MemDetailPage(memId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
    );
