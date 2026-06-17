# Riddles - Maths

Part of the **Riddles** brand (5-app family). See brand strategy in `../PLAN.md`.

## Brand Brief (the big picture)
**Riddles** is a brand umbrella over 5 separate Android puzzle apps — Brain, Maths, Fun, Words, Pics — published under one developer account so they read as one family (tree model: brand = trunk, each app = branch, same DNA, different content). The format is modeled on the proven **Math | Riddle and Puzzle Game** by Black Games (10M+ downloads, 100 levels, type-the-answer, ad-gated hints, 100% free).

**What we are building:** a single clean **template app**, then cloning it into the other repos by swapping content JSON + theme color + icon + name. Same code, 5 independent GitHub repos, 5 Play listings, cross-promoted via a "More Riddles →" section in each.

**Core loop (identical in all 5):** 100 sequential levels, ascending difficulty (no easy/med/hard labels) → see puzzle → type answer (no MCQ) → correct unlocks next level. Stuck → watch **3 rewarded ads** to unlock a hint; still stuck → **1 more rewarded ad** reveals the solution (user still types it to mark solved).

**Monetization:** ads only — rewarded (hints/solution), app-open, banner, interstitial (placement TBD). AdMob + GDPR consent. **No IAP, no premium, no subscriptions.**

**Data/Backend:** Firebase Analytics + Crashlytics only (5 separate projects), **no Firestore**. All user data (progress, settings, onboarding flag) **local-only via Hive** — no login, no cloud sync.

**Tech:** Flutter, **Android only**. Riverpod (state), Hive (local DB), go_router (nav), google_mobile_ads, firebase_core/analytics/crashlytics. Per-app: own applicationId, icon, name, accent color, content JSON, privacy-policy URL.

**Flow:** Splash → app-open ad → 3 animated game-styled onboarding screens (first run only) → home (level grid: locked/unlocked/solved + "More Riddles") → play screen. Plus settings (theme/sound/rate/share/privacy) and a rate-app popup every 3rd home visit.

**Goal/outcome:** ship 5 lightweight, offline, ad-funded puzzle apps fast by reusing one battle-tested template, building a recognizable brand family on the Play Store. **This (Maths) is the first app being built — the template the other 4 clone from.**

## This App
- **Category:** number / math pattern puzzles (closest to the proven Black Games reference).
- **Repo:** https://github.com/DEVENDRAP7/Riddles-maths.git
- **Package id (FINAL, permanent):** `com.devendrap7.riddles.maths`
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
