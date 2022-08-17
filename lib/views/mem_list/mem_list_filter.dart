import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/views/dimens.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/mem_list/mem_list_page_states.dart';

const height = 250.0;

class MemListFilter extends StatelessWidget {
  const MemListFilter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {},
        () => Container(
          height: height,
          padding: bottomSheetPadding,
          child: Consumer(
            builder: (context, ref, child) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch(
                      value: ref.watch(showNotArchivedProvider),
                      onChanged: (value) {
                        ref
                            .read(showNotArchivedProvider.notifier)
                            .updatedBy(value);
                      },
                    ),
                    const Text('Show Not Archived'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch(
                      value: ref.watch(showArchivedProvider),
                      onChanged: (value) {
                        ref
                            .read(showArchivedProvider.notifier)
                            .updatedBy(value);
                      },
                    ),
                    const Text('Show Archived'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
