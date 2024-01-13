import 'package:flutter/material.dart';
import 'package:mem/components/date_and_time/date_and_time_view.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/values/colors.dart';

class CreatedAndUpdatedAtTexts extends StatelessWidget {
  final Mem _entity;

  const CreatedAndUpdatedAtTexts(this._entity, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () {
          if (_entity is SavedMem) {
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
                        (_entity as SavedMem).createdAt,
                        timeOfDay: (_entity as SavedMem).createdAt,
                      ),
                      style: const TextStyle(
                        color: secondaryGreyColor,
                      ),
                    ),
                  ],
                ),
                (_entity as SavedMem).updatedAt == null
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          const Icon(
                            Icons.update,
                            color: secondaryGreyColor,
                          ),
                          DateAndTimeText(
                            DateAndTime.from(
                              (_entity as SavedMem).updatedAt!,
                              timeOfDay: (_entity as SavedMem).updatedAt,
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
