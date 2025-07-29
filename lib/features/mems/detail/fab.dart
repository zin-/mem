import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/actions.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/values/durations.dart';

const Key keySaveMemFab = Key("save-mem");

class MemDetailFab extends ConsumerWidget {
  final GlobalKey<FormState> _formKey;
  final int? _memId;

  const MemDetailFab(
    this._formKey,
    this._memId, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemDetailFabComponent(
          _formKey,
          () => ref.read(saveMem(_memId)),
          ref.watch(editingMemByMemIdProvider(_memId).select(
            (v) => v.value.name,
          )),
        ),
        {
          "_memId": _memId,
        },
      );
}

class _MemDetailFabComponent extends StatelessWidget {
  final GlobalKey<FormState> _formKey;
  final Future<(Object, DateTime?)> Function() _saveMem;
  final String _memName;

  const _MemDetailFabComponent(this._formKey, this._saveMem, this._memName);

  @override
  Widget build(BuildContext context) => v(
        () => FloatingActionButton(
          key: keySaveMemFab,
          child: const Icon(Icons.save_alt),
          onPressed: () => v(() async {
            if (_formKey.currentState?.validate() ?? false) {
              final (_, nextNotifyAt) = await _saveMem();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    nextNotifyAt == null
                        ? buildL10n(context).saveMemSuccessMessage(
                            _memName,
                          )
                        : buildL10n(context).saveMemSuccessMessage2(
                            _memName,
                            nextNotifyAt,
                            nextNotifyAt,
                          ),
                  ),
                  duration: defaultDismissDuration,
                  dismissDirection: DismissDirection.horizontal,
                ),
              );
            }
          }),
        ),
        {
          "_memName": _memName,
        },
      );
}
