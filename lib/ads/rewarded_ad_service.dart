import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Loads and shows AdMob rewarded ads, keeping one preloaded so the next show
/// is instant. Create one per screen, call [load] early, [dispose] when done.
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

  /// Shows the preloaded ad. [onEarned] fires only if the user earns the
  /// reward (watches enough of the ad). [onUnavailable] fires if no ad was
  /// ready or it failed to show. A fresh ad is preloaded afterwards either way.
  void show({
    required void Function() onEarned,
    void Function()? onUnavailable,
  }) {
    final ad = _ad;
    if (ad == null) {
      load();
      onUnavailable?.call();
      return;
    }
    _ad = null;

    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        load();
        if (earned) onEarned();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        load();
        onUnavailable?.call();
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) => earned = true);
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
