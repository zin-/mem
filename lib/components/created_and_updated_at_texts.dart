import 'package:flutter/material.dart';
import 'package:mem/components/date_and_time/date_and_time_view.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/values/colors.dart';

class CreatedAndUpdatedAtTexts extends StatelessWidget {
  final MemV2 _entity;

  const CreatedAndUpdatedAtTexts(this._entity, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () {
          if (_entity is SavedMemV2) {
            return Wrap(
              direction: Axis.horizontal,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.more_time,
                      color: secondaryGreyColor,
                    ),
                    DateAndTimeText(
                      DateAndTime.from(
                        (_entity as SavedMemV2).createdAt,
                        timeOfDay: (_entity as SavedMemV2).createdAt,
                      ),
                      style: const TextStyle(
                        color: secondaryGreyColor,
                      ),
                    ),
                  ],
                ),
                (_entity as SavedMemV2).updatedAt == null
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          const Icon(
                            Icons.update,
                            color: secondaryGreyColor,
                          ),
                          DateAndTimeText(
                            DateAndTime.from(
                              (_entity as SavedMemV2).updatedAt!,
                              timeOfDay: (_entity as SavedMemV2).updatedAt,
                            ),
                            style: const TextStyle(
                              color: secondaryGreyColor,
                            ),
                          ),
                        ],
                      ),
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        },
        _entity,
      );
}
