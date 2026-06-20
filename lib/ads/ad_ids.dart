/// Central place for AdMob ad unit IDs (Android only).
///
/// These are Google's official **test** ad unit IDs — they always return test
/// ads and are safe to use during development. Replace them with your real
/// AdMob ad unit IDs before publishing to the Play Store.
///
/// See: https://developers.google.com/admob/android/test-ads
class AdIds {
  AdIds._();

  /// Whether to serve test ads. Keep `true` until release wiring is ready.
  static const bool useTestAds = true;

  // --- Google's official Android test ad unit IDs ---
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedInterstitial =
      'ca-app-pub-3940256099942544/5354046379';
  static const String _testAppOpen =
      'ca-app-pub-3940256099942544/9257395921';

  // --- Your real production ad unit IDs go here ---
  static const String _prodBanner = '';
  static const String _prodInterstitial = '';
  static const String _prodRewarded = '';
  static const String _prodRewardedInterstitial = '';
  static const String _prodAppOpen = '';

  static String get banner => useTestAds ? _testBanner : _prodBanner;
  static String get interstitial =>
      useTestAds ? _testInterstitial : _prodInterstitial;
  static String get rewarded => useTestAds ? _testRewarded : _prodRewarded;
  static String get rewardedInterstitial =>
      useTestAds ? _testRewardedInterstitial : _prodRewardedInterstitial;
  static String get appOpen => useTestAds ? _testAppOpen : _prodAppOpen;
}
