import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Loads and shows AdMob rewarded ads, keeping one preloaded so the next show
/// is instant. Create one per screen, call [load] early, [dispose] when done.
///
/// [show] is async and resolves to whether the user earned the reward, which
/// makes it easy to chain several ads back to back (e.g. 3 ads to unlock a
/// hint) with a simple `await` loop.
class RewardedAdService {
  RewardedAd? _ad;
  bool _loading = false;

  /// Whether an ad is loaded and ready to show right now.
  bool get isReady => _ad != null;

  /// Begin loading a rewarded ad if one isn't already loaded or loading.
  void load() {
    if (_ad != null || _loading) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) {
          _ad = null;
          _loading = false;
        },
      ),
    );
  }

  /// Ensures an ad is loaded (waiting briefly if needed), then shows it.
  /// Resolves `true` only if the user earned the reward; `false` if no ad
  /// could be shown or it was dismissed before completing. A fresh ad is
  /// preloaded afterwards either way.
  Future<bool> show() async {
    if (_ad == null) {
      load();
      if (!await _waitUntilReady()) return false;
    }
    final ad = _ad;
    if (ad == null) return false;
    _ad = null;

    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        load();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        load();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    return completer.future;
  }

  /// Polls for up to ~10s for a load to finish. Returns whether an ad is ready.
  Future<bool> _waitUntilReady() async {
    const step = Duration(milliseconds: 250);
    for (var i = 0; i < 40; i++) {
      if (_ad != null) return true;
      if (!_loading) return false; // load failed
      await Future<void>.delayed(step);
    }
    return _ad != null;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
