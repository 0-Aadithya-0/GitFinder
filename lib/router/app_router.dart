import 'package:go_router/go_router.dart';
import '../analyze/presentation/pages/home_page.dart';
import '../analyze/presentation/pages/vibe_map_page.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomePage(),
        ),
      ),
      GoRoute(
        path: '/vibe-map',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: VibeMapPage(),
        ),
      ),
    ],
  );
}
