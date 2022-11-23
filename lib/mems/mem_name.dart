import 'package:flutter/material.dart';
import 'package:mem/gui/hero_view.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger/i/api.dart';

String memNameTag(int? memId) => heroTag('mem-name', memId);

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
  final void Function(String value) _onChanged;

  const MemNameTextFormField(
    this._memName,
    this._memId,
    this._onChanged, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {
          '_memName': _memName,
          '_memId': _memId,
          '_onChanged': _onChanged,
        },
        () => HeroView(
          memNameTag(_memId),
          TextFormField(
            initialValue: _memName,
            decoration: InputDecoration(
              labelText: L10n().memNameTitle(),
            ),
            validator: (value) =>
                (value?.isEmpty ?? false) ? L10n().requiredError() : null,
            onChanged: _onChanged,
          ),
        ),
      );
}
