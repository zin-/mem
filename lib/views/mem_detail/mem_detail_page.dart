import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/dimens.dart';
import 'package:mem/views/atoms/async_value_view.dart';
import 'package:mem/views/constants.dart';
import 'package:mem/views/mem_detail/mem_detail_menu.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mem_name.dart';

class MemDetailPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  final int? _memId;

  MemDetailPage(
    this._memId, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {'_memId': _memId},
        () => Consumer(
          builder: (context, ref, child) => v(
            {'_memId': _memId},
            () {
              // dev fetchMemByIdするのと、編集を監視するためのwatchMemMapする範囲が間違っている
              final mem = dev(ref.watch(memProvider(_memId)));
              final memMap = dev(ref.watch(memMapProvider(_memId)));

              return WillPopScope(
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(L10n().memDetailPageTitle()),
                    actions: [
                      MemDetailMenu(memMap),
                    ],
                  ),
                  body: Padding(
                    padding: pagePadding,
                    child: Form(
                      key: _formKey,
                      child: memMap.length < 2
                          // dev まずこっちを通ってる
                          ? AsyncValueView(
                              ref.watch(fetchMemById(_memId)),
                              (Map<String, dynamic> memDataMap) =>
                                  _buildBody(ref, memMap),
                            )
                          // dev で、編集されたときはすでにmemMapがあるのでこっち？
                          : _buildBody(ref, memMap),
                    ),
                  ),
                  floatingActionButton: Consumer(
                    builder: (context, ref, child) {
                      return FloatingActionButton(
                        child: const Icon(Icons.save_alt),
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            await ref.read(saveMem(memMap)).then((saveSuccess) {
                              if (saveSuccess) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(L10n()
                                      .saveMemSuccessMessage(memMap['name'])),
                                  duration: defaultDismissDuration,
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
                  Navigator.of(context).pop(mem);
                  return true;
                },
              );
            },
            debug: true,
          ),
        ),
      );

  Widget _buildBody(
    WidgetRef ref,
    Map<String, dynamic> memMap,
  ) =>
      v(
        {'memMap': memMap, 'ref': ref},
        () => Column(
          children: [
            MemNameTextFormField(
              memMap['name'] ?? '',
              memMap['id'],
              (value) => (value?.isEmpty ?? false)
                  ? L10n().memNameIsRequiredWarn()
                  : null,
              (value) => ref
                  .read(memMapProvider(_memId).notifier)
                  .updatedBy(Map.of(memMap..['name'] = value)),
            ),
          ],
        ),
        debug: true,
      );
}
