import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/line_chart/line_chart_page.dart';
import 'package:mem/components/nullable_widget_builder.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';

class TransitChartIconButton extends ConsumerWidget {
  final int? _memId;

  const TransitChartIconButton(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.read(memByMemIdProvider(_memId));

          return mem is SavedMem
              ? _TransitChartIconButton(mem.id)
              : nullableWidget;
        },
        {"_memId": _memId},
      );
}

class _TransitChartIconButton extends StatelessWidget {
  final int _memId;

  const _TransitChartIconButton(this._memId);

  @override
  Widget build(BuildContext context) => v(
        () => IconButton(
          icon: const Icon(Icons.show_chart),
          onPressed: () => v(
            () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ActLineChartPage(_memId),
              ),
            ),
          ),
        ),
        {"_memId": _memId},
      );
}
