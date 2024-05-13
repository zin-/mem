import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/values/durations.dart';

const Key keySaveMemFab = Key("save-mem");

class MemDetailFab extends ConsumerWidget {
  final GlobalKey<FormState> _formKey;
  final int? _memId;

  const MemDetailFab(this._formKey, this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO select(name)
    final memName = ref.watch(editingMemByMemIdProvider(_memId)).name;

    return _MemDetailFabComponent(
      _formKey,
      () => ref.read(saveMem(_memId)),
      memName,
    );
  }
}

class _MemDetailFabComponent extends StatelessWidget {
  final GlobalKey<FormState> _formKey;
  final Future<void> Function() _saveMem;
  final String _memName;

  const _MemDetailFabComponent(this._formKey, this._saveMem, this._memName);

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return FloatingActionButton(
            key: keySaveMemFab,
            child: const Icon(Icons.save_alt),
            onPressed: () => v(() {
              if (_formKey.currentState?.validate() ?? false) {
                _saveMem();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.saveMemSuccessMessage(
                      _memName,
                    )),
                    duration: defaultDismissDuration,
                    dismissDirection: DismissDirection.horizontal,
                  ),
                );
              }
            }),
          );
        },
        _memName,
      );
}
