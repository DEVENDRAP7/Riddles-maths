import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ads/banner_ad_widget.dart';
import '../screens/home_screen.dart';
import '../screens/levels_screen.dart';
import '../screens/play_screen.dart';
import '../widgets/scene_background.dart';
import '../widgets/walking_navbar.dart';

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

class _ShellScaffold extends StatefulWidget {
  final Widget child;
  final String location;
  const _ShellScaffold({required this.child, required this.location});

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
    value: _indexFor(widget.location).toDouble(),
  );

  int _indexFor(String loc) => loc.startsWith('/levels') ? 1 : 0;

  @override
  void didUpdateWidget(covariant _ShellScaffold old) {
    super.didUpdateWidget(old);
    final target = _indexFor(widget.location).toDouble();
    if (_pan.value != target) {
      _pan.animateTo(target, curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() {
    _pan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexFor(widget.location);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Scene + content + walking navbar fill the space above the ad.
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pan,
                    builder: (context, _) => SceneBackground(pan: _pan.value),
                  ),
                ),
                Positioned.fill(child: widget.child),
                // Navbar merged into the scene (transparent, on the road).
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: WalkingNavBar(
                    index: index,
                    onTap: (i) => context.go(i == 0 ? '/home' : '/levels'),
                  ),
                ),
              ],
            ),
          ),
          // Banner ad anchored right below the walking human navbar.
          const SafeArea(top: false, child: BannerAdWidget()),
        ],
      ),
    );
  }
}
