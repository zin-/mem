import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/view/_atom/async_value_view.dart';
import 'package:mem/view/colors.dart';
import 'package:mem/view/dimens.dart';
import 'package:mem/view/constants.dart';
import 'package:mem/view/mems/mem_detail/mem_detail_body.dart';
import 'package:mem/view/mems/mem_detail/mem_detail_menu.dart';
import 'package:mem/view/mems/mem_detail/mem_detail_states.dart';
import 'package:mem/view/mems/mem_list/mem_list_page.dart';
import 'package:mem/view/mems/mems_action.dart';

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
          builder: (context, ref, child) {
            ref.read(
              initialize((memId) => showMemDetailPage(context, ref, memId)),
            );

            return Consumer(
              builder: (context, ref, child) {
                final mem = ref.watch(memProvider(_memId));

                return mem == null
                    ? AsyncValueView(
                        ref.watch(fetchMemById(_memId)),
                        (value) => _build(),
                      )
                    : _build();
              },
            );
          },
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
                    child: MemDetailBody(_memId),
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
                            final savedMemFuture = _memId == null && mem == null
                                ? ref.read(createMem(_memId))
                                : ref.read(updateMem(_memId));

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(L10n().saveMemSuccessMessage(
                                  (await savedMemFuture).name,
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
}