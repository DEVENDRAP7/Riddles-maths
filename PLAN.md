# Riddles - Maths

Part of the **Riddles** brand (5-app family). See brand strategy in `../PLAN.md`.

## This App
- **Category:** number / math pattern puzzles (closest to the proven Black Games reference).
- **Repo:** https://github.com/DEVENDRAP7/Riddles-maths.git
- **Package id (planned):** `com.riddles.maths` (confirm before build).
- **Accent color:** blue. Glyph: numbers.
- **Privacy policy URL:** TBD (separate per app).

## Brand Constraints (all 5 apps)
- Android only — no iOS.
- No login / signup. Progress local only.
- Splash → 3 animated game-styled onboarding screens (visual only, first run) → home.
- No premium plans / subscriptions. Ads only.
- Firebase Analytics + Crashlytics (own separate Firebase project + google-services.json). No Firestore.
- User data LOCAL only (Hive) — no cloud sync.
- AdMob: own App ID + own ad unit IDs (not shared with other apps).

## Core Loop (same across brand)
- 100 levels, sequential unlock, ascending difficulty (no easy/med/hard labels).
- See puzzle → type answer (no MCQ) → check.
- Hint: watch 3 rewarded ads → unlock hint.
- Solution: watch 1 more rewarded ad → shows answer, user still types it to solve.

## Monetization — Ads only (no IAP)
- Rewarded (hint/solution), app-open, banner, interstitial (placement TBD). AdMob + consent.

## Content
- 100 math/number puzzles, AI-generated + verified, bundled as local JSON.
- Numeric answers → exact match (simplest validation of the 5 apps).

## Stack
- Flutter, Riverpod, Hive, go_router, google_mobile_ads.

## Status
- [ ] Not started. Awaiting build command. Do NOT code until user says go.
