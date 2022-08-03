import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/async_value_view.dart';
import 'package:mem/views/constants.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';

class MemDetailPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  final int? _memId;

  MemDetailPage(this._memId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () => Consumer(
          builder: (context, ref, child) => v(
            {},
            () {
              final memMap = ref.watch(memMapProvider(_memId));

              return WillPopScope(
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('Detail'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.archive),
                        color: Colors.white,
                        onPressed: () {
                          if (Mem.isSavedMap(memMap)) {
                            ref.read(archiveMem(memMap)).then((archived) =>
                                Navigator.of(context).pop(archived));
                          } else {
                            Navigator.of(context).pop(null);
                          }
                        },
                      )
                    ],
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: AsyncValueView(
                        ref.watch(fetchMemById(_memId)),
                        (Map<String, dynamic> memDataMap) => Column(
                          children: [
                            TextFormField(
                              initialValue: memMap['name'] ?? '',
                              validator: (value) => (value?.isEmpty ?? false)
                                  ? 'Name is required.'
                                  : null,
                              onChanged: (value) => ref
                                  .read(memMapProvider(_memId).notifier)
                                  .updatedBy(Map.of(memMap..['name'] = value)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  floatingActionButton: Consumer(
                    builder: (context, ref, child) {
                      return FloatingActionButton(
                        child: const Icon(Icons.save_alt),
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            ref.read(saveMem(memMap)).then((saveSuccess) {
                              if (saveSuccess) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content:
                                      Text('Save success. ${memMap['name']}'),
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
                ),
                onWillPop: () async {
                  Navigator.of(context).pop(Mem.fromMap(memMap));
                  return true;
                },
              );
            },
          ),
        ),
      );
}
