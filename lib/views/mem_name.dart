import 'package:flutter/material.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/atoms/hero_view.dart';

class MemNameText extends StatelessWidget {
  final String _memName;
  final int? _memId;

  const MemNameText(this._memName, this._memId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {'_memName': _memName, '_memId': _memId},
        () => HeroView(memNameTag(_memId), Text(_memName)),
      );
}

class MemNameTextFormField extends StatelessWidget {
  final String? _memName;
  final int? _memId;
  final String? Function(String? value) _validator;
  final void Function(String value) _onChanged;

  const MemNameTextFormField(
    this._memName,
    this._memId,
    this._validator,
    this._onChanged, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {
          '_memName': _memName,
          '_memId': _memId,
          '_validator': _validator,
          '_onChanged': _onChanged,
        },
        () => HeroView(
          memNameTag(_memId),
          TextFormField(
            decoration: InputDecoration(
              labelText: L10n().memNameTitle(),
            ),
            initialValue: _memName,
            validator: _validator,
            onChanged: _onChanged,
          ),
        ),
      );
}

String memNameTag(int? memId) => heroTag('mem-name', memId);
