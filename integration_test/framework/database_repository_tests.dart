import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/framework/repository/database_repository.dart';

import 'database_definitions.dart';

const _name = "DatabaseRepository";

void main() => group(
      _name,
      () {
        setUpAll(() async {
          setOnTest(true);
          final p = await getDatabaseFilePath();
          final f = File(p);
          if (await f.exists()) await f.delete();
        });

        test(
          ".receive",
          () {},
          skip: true,
        );

        group(
          ".shipFileByNameIs",
          () {
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
                final accessor =
                    await DatabaseRepository().receive(sampleDefDb);
                await accessor.driftDatabase
                    .select(accessor.driftDatabase.mems)
                    .get();

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
