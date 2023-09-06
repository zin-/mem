import 'package:flutter/material.dart';
import 'package:mem/components/date_and_time/date_and_time_view.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/entity_value.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/values/colors.dart';

class CreatedAndUpdatedAtTexts extends StatelessWidget {
  final EntityValue _entity;

  const CreatedAndUpdatedAtTexts(this._entity, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () {
          if (_entity.isSaved()) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Icon(
                      Icons.more_time,
                      color: secondaryGreyColor,
                    ),
                    DateAndTimeText(
                      DateAndTime.from(
                        _entity.createdAt!,
                        timeOfDay: _entity.createdAt!,
                      ),
                      style: const TextStyle(
                        color: secondaryGreyColor,
                      ),
                    ),
                  ],
                ),
                _entity.updatedAt == null
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          const Icon(
                            Icons.update,
                            color: secondaryGreyColor,
                          ),
                          DateAndTimeText(
                            DateAndTime.from(
                              _entity.updatedAt!,
                              timeOfDay: _entity.updatedAt,
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
