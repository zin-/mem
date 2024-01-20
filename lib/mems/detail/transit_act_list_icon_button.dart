import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/list/page.dart';
import 'package:mem/components/nullable_widget_builder.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';

class TransitActListIconButton extends ConsumerWidget {
  final int? _memId;

  const TransitActListIconButton(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.read(memByMemIdProvider(_memId));

          return mem is SavedMem
              ? _TransitActListIconButton(mem.id)
              : nullableWidget;
        },
        {"_memId": _memId},
      );
}

class _TransitActListIconButton extends StatelessWidget {
  final int _memId;

  const _TransitActListIconButton(this._memId);

  @override
  Widget build(BuildContext context) => v(
        () => IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => v(
            () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ActListPage(_memId),
              ),
            ),
          ),
        ),
        {"_memId": _memId},
      );
}
