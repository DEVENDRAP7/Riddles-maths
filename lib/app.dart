import 'package:flutter/material.dart';

import 'core/router.dart';
import 'core/theme.dart';

class RiddlesMathsApp extends StatelessWidget {
  const RiddlesMathsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Riddles - Maths',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
