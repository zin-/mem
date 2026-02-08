import 'package:flutter/material.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/values/colors.dart';

import 'date_and_time.dart';
import 'date_and_time_view.dart';

class CreatedAndUpdatedAtTexts extends StatelessWidget {
  final Object _entity;

  const CreatedAndUpdatedAtTexts(this._entity, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () {
          if (_entity is DatabaseTupleEntityV1) {
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
                        _entity.createdAt,
                        timeOfDay: _entity.createdAt,
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
                              (_entity).updatedAt!,
                              timeOfDay: (_entity).updatedAt,
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
        {
          '_entity': _entity,
        },
      );
}
