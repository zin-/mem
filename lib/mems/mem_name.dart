import 'package:flutter/material.dart';
import 'package:mem/gui/hero_view.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/logger/log_service_v2.dart';

String memNameTag(int? memId) => heroTag('mem-name', memId);

class MemNameText extends StatelessWidget {
  final String _memName;
  final int? _memId;

  const MemNameText(this._memName, this._memId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        () => HeroView(
          memNameTag(_memId),
          Text(
            _memName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        {'_memName': _memName, '_memId': _memId},
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
        {
          '_memName': _memName,
          '_memId': _memId,
          '_onChanged': _onChanged,
        },
      );
}
