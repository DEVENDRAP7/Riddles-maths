import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/progress_repository.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local-only progress (Hive). No cloud, no accounts.
  final progress = ProgressRepository();
  await progress.init();

  runApp(
    ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(progress),
      ],
      child: const RiddlesMathsApp(),
    ),
  );
}
