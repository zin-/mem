import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/constants.dart';

import 'package:mem/views/mem_detail/mem_detail_states.dart';

class MemDetailPage extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();

  final int? _memId;

  MemDetailPage(this._memId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        {},
        () {
          final memMapAsyncValue = ref.watch(fetchMemById(_memId));

          return Scaffold(
            appBar: AppBar(
              title: const Text('Detail'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: memMapAsyncValue.when(
                  data: (memDataMap) => Column(
                    children: [
                      TextFormField(
                        initialValue: memDataMap['name'] ?? '',
                        validator: (value) => (value?.isEmpty ?? false)
                            ? 'Name is required.'
                            : null,
                        onChanged: (value) => ref
                            .read(memMapProvider(_memId).notifier)
                            .updatedBy(memDataMap..['name'] = value),
                      ),
                    ],
                  ),
                  error: (e, s) => const Text('error'),
                  loading: () => const Text('loading'),
                ),
              ),
            ),
            floatingActionButton: Consumer(
              builder: (context, ref, child) {
                return FloatingActionButton(
                  child: const Icon(Icons.save_alt),
                  onPressed: () {
                    final memMap = ref.watch(memMapProvider(_memId));

                    if (_formKey.currentState?.validate() ?? false) {
                      ref.read(saveMem(memMap)).then((saveSuccess) {
                        if (saveSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Save success. ${memMap['name']}'),
                            duration: const Duration(
                              seconds: defaultDismissDurationSeconds,
                            ),
                            dismissDirection: DismissDirection.horizontal,
                          ));
                        }
                      });
                    }
                  },
                );
              },
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      );
}
