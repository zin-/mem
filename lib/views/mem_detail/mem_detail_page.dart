import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_item_repository.dart'; // FIXME repositoryを見るのはおかしい気がする
import 'package:mem/views/atoms/async_value_view.dart';
import 'package:mem/views/colors.dart';
import 'package:mem/views/dimens.dart';
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
              final mem = ref.watch(memProvider(_memId));

              return mem == null
                  ? AsyncValueView(
                      ref.watch(fetchMemById(_memId)),
                      (value) => _build(),
                    )
                  : _build();
            },
          ),
        ),
      );

  _build() => v(
        {},
        () => Consumer(
          builder: (context, ref, child) {
            final mem = ref.watch(memProvider(_memId));

            return WillPopScope(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(L10n().memDetailPageTitle()),
                  actions: [
                    MemDetailMenu(_memId),
                  ],
                  backgroundColor:
                      mem?.isArchived() ?? false ? archivedColor : primaryColor,
                ),
                body: Padding(
                  padding: pagePadding,
                  child: Form(
                    key: _formKey,
                    child: _buildBody(),
                  ),
                ),
                floatingActionButton: Consumer(
                  builder: (context, ref, child) {
                    return FloatingActionButton(
                      child: const Icon(Icons.save_alt),
                      onPressed: () => v(
                        {},
                        () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            final savedFuture = _memId == null && mem == null
                                ? ref.read(createMem(_memId))
                                : ref.read(updateMem(_memId));

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(L10n().saveMemSuccessMessage(
                                  (await savedFuture).name,
                                )),
                                duration: defaultDismissDuration,
                                dismissDirection: DismissDirection.horizontal,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerFloat,
              ),
              onWillPop: () async => v(
                {},
                () {
                  Navigator.of(context).pop(mem);
                  return true;
                },
              ),
            );
          },
        ),
      );

  Widget _buildBody() => v(
        {},
        () {
          return Consumer(
            builder: (context, ref, child) {
              final editingMem = ref.watch(editingMemProvider(_memId));
              final memItems = ref.watch(memItemsProvider(_memId));

              return Column(
                children: [
                  MemNameTextFormField(
                    editingMem.name,
                    editingMem.id,
                    (value) => (value?.isEmpty ?? false)
                        ? L10n().memNameIsRequiredWarn()
                        : null,
                    (value) => ref
                        .read(editingMemProvider(_memId).notifier)
                        .updatedBy(editingMem..name = value),
                  ),
                  memItems == null
                      ? AsyncValueView(
                          ref.watch(fetchMemById(_memId)),
                          (value) => _buildMemItemViews(),
                        )
                      : _buildMemItemViews(),
                ],
              );
            },
          );
        },
      );

  Widget _buildMemItemViews() => v(
        {},
        () {
          return Consumer(
            builder: (context, ref, child) {
              final memItems = ref.watch(memItemsProvider(_memId));

              return SingleChildScrollView(
                child: Column(
                  children: [
                    ...(memItems == null || memItems.isEmpty
                            ? [
                                MemItemEntity(
                                  memId: _memId,
                                  type: MemItemType.memo,
                                ),
                              ]
                            : memItems)
                        .map((memItem) {
                      return TextFormField(
                        decoration: InputDecoration(
                          icon: const Icon(Icons.subject),
                          labelText: L10n().memMemoTitle(),
                        ),
                        maxLines: null,
                        initialValue: memItem.value,
                        onChanged: (value) =>
                            ref.read(memItemsProvider(_memId).notifier).upsert(
                                  memItem..value = value,
                                  (item) => item.id == memItem.id,
                                ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      );
}
