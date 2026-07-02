import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/framework/view/synced_text_editing_controller.dart';
import 'package:mem/values/dimens.dart';

const keyMemRepeatByNDayNotification = Key("mem-repeat-by-n-day-notification");

class MemRepeatByNDayNotificationView extends ConsumerWidget {
  final int? _memId;

  const MemRepeatByNDayNotificationView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final notification =
              ref.watch(memRepeatByNDayNotificationByMemIdProvider(_memId));

          return _MemRepeatByNDayNotificationView(
            notification.value.time,
            (nDay) => ref
                .read(memNotificationsByMemIdProvider(_memId).notifier)
                .upsertAll(
              [
                notification.updatedWith(
                  (v) => MemNotification.by(
                    v.memId,
                    v.type,
                    nDay,
                    v.message,
                  ),
                ),
              ],
              (current, updating) => current.value.type == updating.value.type,
            ),
          );
        },
        {
          '_memId': _memId,
        },
      );
}

class _MemRepeatByNDayNotificationView extends StatefulWidget {
  final int? nDay;
  final ValueChanged<int?> onNDayChanged;

  const _MemRepeatByNDayNotificationView(
    this.nDay,
    this.onNDayChanged,
  );

  @override
  State<_MemRepeatByNDayNotificationView> createState() =>
      _MemRepeatByNDayNotificationViewState();
}

class _MemRepeatByNDayNotificationViewState
    extends State<_MemRepeatByNDayNotificationView> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllerText();
  }

  @override
  void didUpdateWidget(covariant _MemRepeatByNDayNotificationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nDay != widget.nDay) {
      _syncControllerText(postFrame: true);
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitValue();
    }
  }

  void _syncControllerText({bool postFrame = false}) {
    syncTextEditingController(
      controller: _controller,
      mounted: mounted,
      postFrame: postFrame,
      buildText: () => (widget.nDay ?? 0).toString(),
    );
  }

  void _commitValue() {
    final value = _controller.text;
    if (value.isEmpty) {
      widget.onNDayChanged(1);
      _syncControllerText(postFrame: true);
      return;
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      return;
    }

    widget.onNDayChanged(parsed == 0 ? null : parsed);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);
          final prefix = l10n.repeatByNDayPrefix;
          final suffix = l10n.repeatByNDaySuffix;

          return ListTile(
            key: keyMemRepeatByNDayNotification,
            title: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (prefix.isNotEmpty)
                  Flexible(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: defaultComponentPadding,
                      ),
                      child: Text(prefix),
                    ),
                  ),
                SizedBox(
                  width: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: defaultComponentPadding,
                    ),
                    child: TextFormField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isEmpty) {
                          return;
                        }

                        final parsed = int.tryParse(value);
                        if (parsed == null) {
                          return;
                        }

                        widget.onNDayChanged(parsed == 0 ? null : parsed);
                      },
                      onEditingComplete: _commitValue,
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: defaultComponentPadding,
                    ),
                    child: Text(suffix),
                  ),
                ),
              ],
            ),
          );
        },
        {
          'nDay': widget.nDay,
        },
      );
}
