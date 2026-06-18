import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/levels_screen.dart';
import '../screens/play_screen.dart';
import 'theme.dart';

/// Two-tab app shell (Home + Levels) with the Play screen pushed on top.
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _ShellScaffold(
        location: state.uri.path,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (c, s) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/levels',
          pageBuilder: (c, s) => const NoTransitionPage(child: LevelsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/play/:level',
      builder: (c, s) => PlayScreen(
        levelNumber: int.tryParse(s.pathParameters['level'] ?? '1') ?? 1,
      ),
    ),
  ],
);

class _ShellScaffold extends StatelessWidget {
  final Widget child;
  final String location;
  const _ShellScaffold({required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final index = location.startsWith('/levels') ? 1 : 0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.accent, width: 2)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.accent.withValues(alpha: 0.18),
          selectedIndex: index,
          onDestinationSelected: (i) =>
              context.go(i == 0 ? '/home' : '/levels'),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Levels',
            ),
          ],
        ),
      ),
    );
  }
}
