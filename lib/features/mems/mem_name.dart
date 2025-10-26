import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/hero_view.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mem.dart';

Key keyMemName = const Key("mem-name");

String _memNameTag(int? memId) => heroTag('mem-name', memId);

class MemNameTextFormField extends ConsumerWidget {
  final int? _memId;

  const MemNameTextFormField(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final editingMem = ref.read(editingMemByMemIdProvider(_memId));

          return _MemNameTextFormField(
            _memId,
            editingMem.value.name,
            (value) =>
                ref.read(editingMemByMemIdProvider(_memId).notifier).updatedBy(
                      editingMem.updatedWith(
                        (mem) => Mem(mem.id, value, mem.doneAt, mem.period),
                      ),
                    ),
          );
        },
        {
          '_memId': _memId,
        },
      );
}

class _MemNameTextFormField extends StatelessWidget {
  final int? _memId;
  final String _memName;
  final void Function(String value) _onChanged;

  const _MemNameTextFormField(this._memId, this._memName, this._onChanged);

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return HeroView(
            _memNameTag(_memId),
            TextFormField(
              key: keyMemName,
              initialValue: _memName,
              decoration: InputDecoration(
                labelText: l10n.memNameLabel,
              ),
              autofocus: _memName.isEmpty,
              validator: (value) =>
                  (value?.isEmpty ?? false) ? l10n.requiredError : null,
              onChanged: _onChanged,
            ),
          );
        },
        {
          '_memId': _memId,
          '_memName': _memName,
        },
      );
}

class MemNameText extends ConsumerWidget {
  final int? _memId;

  const MemNameText(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemNameText(
          ref.watch(memStateProvider(_memId)).value?.name ?? '',
          _memNameTag(_memId),
          ref.watch(memStateProvider(_memId)).value?.isDone ?? false,
        ),
        {
          '_memId': _memId,
        },
      );
}

class _MemNameText extends StatelessWidget {
  final String _memName;
  final String _memNameTag;
  final bool _isDone;

  const _MemNameText(this._memName, this._memNameTag, this._isDone);

  @override
  Widget build(BuildContext context) => v(
        () => HeroView(
          _memNameTag,
          Text(
            _memName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _isDone
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
        ),
        {
          '_memName': _memName,
          '_memNameTag': _memNameTag,
          '_isDone': _isDone,
        },
      );
}
