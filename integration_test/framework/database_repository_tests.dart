import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/framework/repository/database_repository.dart';

import 'database_definitions.dart';

const _name = "DatabaseRepository";

void main() => group(
      _name,
      () {
        setUpAll(() async {
          await DatabaseFactory
              // ignore: deprecated_member_use_from_same_package
              .nativeFactory
              .deleteDatabase(
                  await DatabaseFactory.buildDatabasePath(sampleDefDb.name));
        });

        test(
          ".receive",
          () {},
          skip: true,
        );

        group(
          ".shipFileByNameIs",
          () {
            setUpAll(() async {
              await DatabaseRepository().receive(sampleDefDb);
            });

            test(
              " on no receive.",
              () async {
                final databaseFile =
                    await DatabaseRepository().shipFileByNameIs(
                  "on_no_receive",
                );

                expect(databaseFile, isNull);
              },
            );

            test(
              " received.",
              () async {
                final databaseFile =
                    await DatabaseRepository().shipFileByNameIs(
                  sampleDefDb.name,
                );

                expect(databaseFile, isNotNull);
              },
            );
          },
        );
      },
    );
