# MuscleDaddies Handoff Log

## Scope
- iOS app in `/Users/tj/MuscleDaddies` with HealthKit + Firebase.
- Implemented HealthKit data reads, XP/HP/recovery models, class system, and UI surfaces.

## Core Data Model Changes
- `Workout` now includes:
  - `energyBurned`, `distance`, `averageHeartRate`, `estimatedHeartRate`
  - `strengthExercise`, `strengthReps`, `strengthWeightKg`
  - File: `/Users/tj/MuscleDaddies/MuscleDaddies/Models/Workout.swift`
- `UserStats` now includes:
  - `xpCurrent`, `xpToNext`, `xpMultiplier`
  - `hpCurrent`, `hpMax`
  - File: `/Users/tj/MuscleDaddies/MuscleDaddies/Models/User.swift`
- `AppUser` now includes:
  - `classTheme` and `selectedClass`
  - File: `/Users/tj/MuscleDaddies/MuscleDaddies/Models/User.swift`
- Added `RecoveryMetrics` with `capturedAt`
  - File: `/Users/tj/MuscleDaddies/MuscleDaddies/Models/RecoveryMetrics.swift`

## HealthKit
- Expanded read types to include energy, HR metrics, HRV, sleep, mindful, distances, etc.
- Workout sync now pulls `energyBurned`, `distance`, and avg HR (via `HKStatisticsQuery`).
- Recovery metrics fetched from HealthKit and persisted daily.
- File: `/Users/tj/MuscleDaddies/MuscleDaddies/Services/HealthKitService.swift`

## Stat / XP System
- `StatCalculator` now:
  - Computes XP per workout with energy + distance + HR + optional strength load factor.
  - Applies class weights to stat point distribution.
  - Adds streak multiplier to XP for leveling (`xpMultiplier`).
  - Computes HP based on 7-day load + recovery score.
  - Includes `xpForWorkout()` helper.
  - File: `/Users/tj/MuscleDaddies/MuscleDaddies/Services/StatCalculator.swift`

## Strength Metric
- Manual logging in `LogWorkoutView` includes optional strength set:
  - Exercise name, reps, weight (lb/kg).
- Epley 1RM estimate used in XP scoring for strength workouts.
- File: `/Users/tj/MuscleDaddies/MuscleDaddies/Views/Workout/LogWorkoutView.swift`

## Manual HR Estimate
- If HealthKit isn’t authorized, manual logs estimate HR by intensity.
- Stored as `estimatedHeartRate`, used in XP scoring.
- Files: `Workout.swift`, `LogWorkoutView.swift`, `StatCalculator.swift`

## Class System
- Added `ClassTheme` (Fantasy/Sports/Sci‑Fi) and `MuscleClass` list with stat weights.
- Mapped class theme to card theme:
  - Fantasy → Pixel
  - Sports → Trading
  - Sci‑Fi → Modern
- File: `/Users/tj/MuscleDaddies/MuscleDaddies/Utilities/Constants.swift`
- Class selection UI added in Settings.
- Card theme is now derived and hidden in Settings.
- File: `/Users/tj/MuscleDaddies/MuscleDaddies/Views/Settings/SettingsView.swift`

## UI
- Character cards show:
  - XP bar, REC bar, HP bar
  - Class name display
  - Files:
    - `/Users/tj/MuscleDaddies/MuscleDaddies/Views/Card/CardThemes/ModernTheme.swift`
    - `/Users/tj/MuscleDaddies/MuscleDaddies/Views/Card/CardThemes/PixelArtTheme.swift`
    - `/Users/tj/MuscleDaddies/MuscleDaddies/Views/Card/CardThemes/TradingCardTheme.swift`
- New “Progress” tab:
  - XP overview, recovery signals, HP/load, XP history chart with 14/30 toggle, tooltips.
  - XP history uses streak multiplier.
  - File: `/Users/tj/MuscleDaddies/MuscleDaddies/Views/Progress/XPRecoveryView.swift`
- Tab added in `/Users/tj/MuscleDaddies/MuscleDaddies/App/ContentView.swift`

## Firestore
- Added `recovery` collection with daily docs:
  - `recovery/{userId}/daily/{yyyy-MM-dd}`
  - Saved on sync and on manual log.
  - File: `/Users/tj/MuscleDaddies/MuscleDaddies/Services/FirestoreService.swift`
- Firestore rules updated for recovery:
  - File: `/Users/tj/MuscleDaddies/firestore.rules`

## Important Behaviors
- Stats recalculated after:
  - HealthKit sync
  - Manual workout log
  - Class selection change
- XP leveling now uses streak multiplier (1% per day, cap 25%).
- HP shows danger colors in Progress screen.

## Not Done / Open Ideas
- Tuning estimate constants for HR/strength.
- Recovery history chart from stored daily snapshots (not yet displayed).

## 2026-02-07 Update: Class Onboarding
- Onboarding now includes class theme + class selection (not just display name).
- AuthService.completeOnboarding now accepts class theme and class, and sets derived card theme.
- Onboarding view is scrollable to fit on smaller devices.
- Files:
  - /Users/tj/MuscleDaddies/MuscleDaddies/Services/AuthService.swift
  - /Users/tj/MuscleDaddies/MuscleDaddies/Views/Auth/LoginView.swift

## 2026-02-07 Update: Recovery History UI
- Progress screen now shows a Recovery History chart (14/30 day toggle).
- Reads persisted recovery snapshots from Firestore via FirestoreService.getRecoveryMetrics.
- Uses local recovery score calc to normalize to 0-100 for charting.
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Views/Progress/XPRecoveryView.swift

## 2026-02-07 Update: Recovery Tuning (Balanced)
- Reduced mindfulness impact (small bonus).
- Slightly eased sleep penalty curve.
- HRV/RHR/HRR scaled for moderate sensitivity.
- HP penalty softened and minimum HP raised.
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Services/StatCalculator.swift

## 2026-02-07 Update: HealthKit Permission UX
- Added a HealthKit education screen before requesting authorization.
- Settings “Connect” now opens the explainer sheet, then triggers HealthKit auth on Continue.
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Views/Settings/SettingsView.swift

## 2026-02-07 Update: Privacy Policy Draft
- Added privacy policy draft at /Users/tj/MuscleDaddies/PRIVACY_POLICY.md
- Includes HealthKit usage, group sharing, and location handling notes.

## 2026-02-07 Update: Theme Unlocks
- Class themes now have XP unlock thresholds: Sports 25,000 XP; Sci‑Fi 60,000 XP.
- Fantasy is default; other themes locked until XP thresholds met.
- Settings shows locked themes and prevents selection when not unlocked.
- Onboarding locked to Fantasy theme (no theme picker).
- Files:
  - /Users/tj/MuscleDaddies/MuscleDaddies/Utilities/Constants.swift
  - /Users/tj/MuscleDaddies/MuscleDaddies/Views/Settings/SettingsView.swift
  - /Users/tj/MuscleDaddies/MuscleDaddies/Views/Auth/LoginView.swift
  - /Users/tj/MuscleDaddies/MuscleDaddies/Models/User.swift
  - /Users/tj/MuscleDaddies/MuscleDaddies/Services/StatCalculator.swift

## 2026-02-07 Update: Theme Unlock Badges
- Added theme badges in Settings showing unlock state and XP requirement.
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Views/Settings/SettingsView.swift

## 2026-02-07 Update: Theme Unlock Badges (Onboarding)
- Added theme unlock badges to onboarding screen (Fantasy unlocked, others locked).
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Views/Auth/LoginView.swift

## 2026-02-07 Update: XP Constants (Option B)
- XP formulas implemented in StatCalculator using mph-based speed scaling.
- Endurance: XP = kcal * 1.0
- Speed: XP = minutes * (mph / 7.5) * 10
- Strength: XP = minutes * (HR/140) * (RPE/10) * 14
- Recovery: XP = minutes * 4
- Speed vs endurance for run/cycle/swim is based on intensity >= 4.
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Services/StatCalculator.swift

## 2026-02-07 Update: Class Weights (Softer)
- Updated class weights to softer slot weighting (0.35 / 0.30 / 0.20 / 0.15).
- Recovery stat remains Intelligence.
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Utilities/Constants.swift

## 2026-02-07 Update: Recovery Tuning (Sleep Stricter)
- Tightened sleep sensitivity: delta divisor changed from 4.5 to 3.5 (bad sleep impacts recovery more).
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Services/StatCalculator.swift

## 2026-02-07 Update: Recovery Tuning (Biometrics More Forgiving)
- Reduced HRV/RHR/HRR contribution weights (HRV 25→15, RHR 25→15, HRR 15→10).
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Services/StatCalculator.swift

## 2026-02-07 Update: HP Forgiving at Low Levels
- HP penalty/bonus now scale by level (more forgiving for low levels, normal by level 25).
- Added level-based novice factor in healthFrom.
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Services/StatCalculator.swift

## 2026-02-07 Update: Onboarding UI Pass
- Redesigned onboarding screen with custom typography, card sections, and animated glow.
- Replaced basic layout with structured steps, themed cards, and a stronger primary CTA.
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Views/Auth/LoginView.swift

## 2026-02-07 Update: Card Previews
- Added SwiftUI previews for Modern, Pixel, and Trading card themes.
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Views/Card/CharacterCardView.swift

## 2026-02-07 Update: Preview App Target
- Added MuscleDaddiesPreview app target via XcodeGen.
- New preview entry point: /Users/tj/MuscleDaddies/MuscleDaddiesPreview/PreviewApp.swift
- project.yml updated; xcodegen run to regenerate Xcode project.

## 2026-02-07 Update: Handoff Log
- Confirmed preview app target added and documented.

## 2026-02-07 Update: Fantasy Class Art
- Imported fantasy class images into Assets.xcassets (Warrior, Wizard, Berserker, Knight, Swordmaster, Elf, Scout, Thief).
- Fixed typo: Thief..png → Thief.png.
- Added fantasyArtAsset mapping in Constants.MuscleClass.
- Pixel (Fantasy) card now displays class art.
- Files:
  - /Users/tj/MuscleDaddies/MuscleDaddies/Resources/Assets.xcassets/*
  - /Users/tj/MuscleDaddies/MuscleDaddies/Utilities/Constants.swift
  - /Users/tj/MuscleDaddies/MuscleDaddies/Views/Card/CardThemes/PixelArtTheme.swift

## 2026-02-07 Update: Sports Class Swap
- Replaced Point Guard with Golf Trick Shot (recovery‑focused).
- Updated class list and weights (INT primary, END secondary).
- File: /Users/tj/MuscleDaddies/MuscleDaddies/Utilities/Constants.swift
