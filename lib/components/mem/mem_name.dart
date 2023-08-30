import 'package:flutter/material.dart';
import 'package:mem/components/hero_view.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';

String _memNameTag(int? memId) => heroTag('mem-name', memId);

class MemNameText extends StatelessWidget {
  final Mem _mem;

  const MemNameText(this._mem, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        () => HeroView(
          _memNameTag(_mem.id),
          Text(
            _mem.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _mem.isDone()
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
        ),
        _mem,
      );
}

class MemNameTextFormField extends StatelessWidget {
  final String? _memName;
  final int? _memId;
  final void Function(String value) _onChanged;

  const MemNameTextFormField(
    this._memName,
    this._memId,
    this._onChanged, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return HeroView(
            _memNameTag(_memId),
            TextFormField(
              initialValue: _memName,
              decoration: InputDecoration(
                labelText: l10n.memNameLabel,
              ),
              validator: (value) =>
                  (value?.isEmpty ?? false) ? l10n.requiredError : null,
              onChanged: _onChanged,
            ),
          );
        },
        {
          '_memName': _memName,
          '_memId': _memId,
        },
      );
}
