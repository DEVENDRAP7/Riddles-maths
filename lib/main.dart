import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'data/progress_repository.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob (Android only). Safe to await; serves Google test ads in debug.
  await MobileAds.instance.initialize();

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
