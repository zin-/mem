import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/values/dimens.dart';

const keyMemRepeatByNDayNotification = Key("mem-repeat-by-n-day-notification");

class MemRepeatByNDayNotificationView extends StatelessWidget {
  const MemRepeatByNDayNotificationView({super.key});

  @override
  Widget build(BuildContext context) => v(
        () {
          // TODO: implement build
          final l10n = buildL10n(context);
          final prefix = l10n.repeat_by_n_day_prefix;

          return ListTile(
            key: keyMemRepeatByNDayNotification,
            title: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (prefix.isNotEmpty) Text(prefix),
                TextFormField(
                  initialValue: 1.toString(),
                  keyboardType: TextInputType.number,
                ),
                Text(l10n.repeat_by_n_day_suffix),
              ]
                  .map(
                    (e) => Flexible(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: defaultComponentPadding,
                        ),
                        child: e,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          );
        },
      );
}
