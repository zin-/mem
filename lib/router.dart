import 'package:go_router/go_router.dart';
import 'package:mem/features/acts/counter/act_counter_configure.dart';
import 'package:mem/features/acts/line_chart/line_chart_page.dart';
import 'package:mem/dev/page.dart';
import 'package:mem/home_screen.dart';
import 'package:mem/mems/detail/page.dart';

const _memIdKey = 'memId';

const _homePath = '/';
const _memDetailPath = 'mems/:$_memIdKey';
const _memChartPath = 'chart';
const newActCountersPath = '${_homePath}act_counters/new';
const devPath = 'dev';

String buildMemDetailPath(int memId) => '${_homePath}mems/$memId';

String buildMemChartPath(int memId) => [
      buildMemDetailPath(memId),
      _memChartPath,
    ].join(_homePath);

GoRouter buildRouter([String? initialPath = _homePath]) => GoRouter(
      initialLocation: initialPath,
      routes: [
        GoRoute(
          path: _homePath,
          builder: (_, __) => HomeScreen(),
          routes: [
            GoRoute(
                path: _memDetailPath,
                builder: (_, state) => MemDetailPage(
                      int.parse(state.pathParameters[_memIdKey]!),
                    ),
                routes: [
                  GoRoute(
                    path: _memChartPath,
                    builder: (context, state) => ActLineChartPage(
                      memId: int.parse(state.pathParameters[_memIdKey]!),
                    ),
                  )
                ]),
            GoRoute(
              path: devPath,
// coverage:ignore-start
              builder: (_, __) => const DevPage(),
// coverage:ignore-end
            ),
          ],
        ),
        GoRoute(
          path: newActCountersPath,
          builder: (_, __) => const ActCounterConfigure(),
        ),
      ],
    );
