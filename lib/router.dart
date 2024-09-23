import 'package:go_router/go_router.dart';
import 'package:mem/acts/counter/act_counter_configure.dart';
import 'package:mem/home_screen.dart';
import 'package:mem/mems/detail/page.dart';

const _memIdKey = 'memId';

const _homePath = '/';
const _memDetailPath = 'mems/:$_memIdKey';
const newActCountersPath = '${_homePath}act_counters/new';

String buildMemDetailPath(int memId) => '${_homePath}mems/$memId';

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
            ),
          ],
        ),
        GoRoute(
          path: newActCountersPath,
          builder: (_, __) => const ActCounterConfigure(),
        ),
      ],
    );
