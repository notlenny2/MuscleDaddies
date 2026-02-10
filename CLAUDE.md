# MuscleDaddies - Claude Code Instructions

## Project Overview

**MuscleDaddies** is an RPG-gamified fitness app built with SwiftUI, Firebase, and HealthKit. Users select character classes (Fantasy/Sports/Sci-Fi themes), log workouts, earn XP/levels, track HP based on recovery metrics, and compete in group challenges.

- **Tech Stack**: SwiftUI, Firebase (Auth, Firestore, FCM), HealthKit, AuthenticationServices
- **Min iOS**: 17.0
- **Build System**: xcodegen (generates `MuscleDaddies.xcodeproj` from `project.yml`)
- **Bundle ID**: `com.muscledaddies.app`
- **Firebase Project ID**: `muscle-daddies` (nam5 region)

---

## Critical Architecture Patterns

### 1. Demo Mode Architecture

**Always check demo mode before adding Firebase-dependent features.**

- Demo mode activates when `GoogleService-Info.plist` is missing or invalid
- All services check `AppDelegate.firebaseConfigured` to gate Firebase calls
- Pattern used throughout:
  ```swift
  var isDemoMode: Bool { !AppDelegate.firebaseConfigured }

  func someFirestoreMethod() async throws -> [SomeType] {
      if isDemoMode {
          return demoData // Static demo data
      }
      // Real Firestore logic here
  }
  ```
- Services use `lazy var db` to avoid crashes when Firebase not configured
- Demo data must be realistic and represent all app states

### 2. Service Layer Pattern

**All services follow this structure:**

```swift
@MainActor
class SomeService: ObservableObject {
    @Published var state: SomeState
    lazy var db = Firestore.firestore()
    var isDemoMode: Bool { !AppDelegate.firebaseConfigured }

    // Methods here
}
```

**Rules:**
- ALWAYS use `@MainActor` on services (ensures UI updates on main thread)
- ALWAYS use `lazy var db` (prevents Firestore crash when not configured)
- ALWAYS check `isDemoMode` before Firebase calls
- ALWAYS use `@Published` for observable state
- Services are injected as `@EnvironmentObject` in views

**Current Services:**
- `AuthService` - Apple Sign-In, onboarding, user state
- `FirestoreService` - All Firestore CRUD operations
- `HealthKitService` - Workout/recovery sync with deduplication
- `StatCalculator` - XP/level/HP/stat calculations
- `NotificationService` - FCM token registration, push notifications

### 3. Naming Conventions

**CRITICAL - Avoid SwiftUI Namespace Collisions:**

- Use `WorkoutGroup` NOT `Group` (SwiftUI.Group exists)
- Use `AppUser` NOT `User` (Firebase.User exists)
- Prefix custom types when conflicts possible

**Model Naming:**
- All models: `Codable, Identifiable` conformance
- Use `@DocumentID var id: String?` for Firestore documents
- Optional fields use `?` suffix (e.g., `var energyBurned: Double?`)

**View Naming:**
- Feature-based organization: `Views/[Feature]/[Feature]View.swift`
- Reusable components go in `Views/Card/` or `Views/Components/`

### 4. Class System Architecture

**24 Classes across 3 Themes:**
- **Fantasy** (8): Warrior, Scout, Knight, Wizard, Thief, Berserker, Swordmaster, Elf
- **Sports** (8): Shortstop, Quarterback, RacecarDriver, Enforcer, Golfer, PowerForward, Goalie, Striker
- **Sci-Fi** (8): StarfighterPilot, StarfleetCaptain, BorgJuggernaut, Xenomorph, AndroidMedic, WarpEngineer, ZeroGRanger, VoidMonk

**Class-to-Theme Mapping:**
- `ClassTheme.fantasy` → `CardTheme.pixel` (Pixel Art)
- `ClassTheme.sports` → `CardTheme.trading` (Trading Card)
- `ClassTheme.scifi` → `CardTheme.modern` (Modern/Sci-Fi)

**Each class has stat weights (4 values summing to 1.0) defined in `StatCalculator`.**

### 5. XP/Level/HP System

**XP Calculation (per workout):**
```swift
// Endurance workouts: 1 XP per calorie
enduranceXP = energyBurned * 1.0

// Speed workouts: based on pace (mph)
speedXP = minutes * (mph / 7.5) * 10

// Strength workouts: HR × RPE intensity
strengthXP = minutes * (HR / 140) * (RPE / 10) * 14

// Recovery workouts: time-based
recoveryXP = minutes * 4
```

**Level Progression:**
- Exponential curve (each level requires more XP)
- Calculated in `StatCalculator.level(from:)`
- Updates `xpCurrent`, `xpToNext`, `totalXP`

**HP System:**
- Base: 100
- Penalty: High training load (7-day cumulative workouts)
- Boost: Recovery score (sleep + HRV from HealthKit)
- Calculated in `StatCalculator.calculateHP()`

**Streak Multiplier:**
- +0.01 (1%) per consecutive workout day
- Capped at +0.25 (25%)
- Applied to all XP gains

### 6. HealthKit Integration

**Deduplication Strategy:**
- Every workout has `healthKitUUID: String?` field
- Before adding HealthKit workout to Firestore, check if `healthKitUUID` already exists
- Pattern:
  ```swift
  let existingWorkouts = try await db.collection("workouts")
      .whereField("healthKitUUID", isEqualTo: uuid)
      .getDocuments()

  if !existingWorkouts.documents.isEmpty { return } // Already synced
  ```

**Recovery Metrics:**
- Stored in Firestore at: `recovery/{userId}/daily/{yyyy-MM-dd}`
- Fields: `sleepMinutes7d`, `mindfulMinutes7d`, `hrvSDNN`, `restingHeartRate`, `heartRateRecovery1Min`
- Fetched daily and used in HP calculation

**HealthKit Permissions:**
- Requested in `SettingsView` with educational sheet explaining each permission
- Required types: workouts, activeEnergyBurned, heartRate, sleep, HRV, mindfulness

---

## File Structure

```
MuscleDaddies/
├── project.yml                 # xcodegen config (regenerate Xcode project with `xcodegen generate`)
├── firebase.json               # Firebase config
├── firestore.rules             # Security rules
├── MuscleDaddies/
│   ├── App/
│   │   ├── MuscleDaddiesApp.swift   # @main entry, service injection
│   │   └── ContentView.swift        # Root TabView (7 tabs)
│   ├── Models/                      # All Codable + Identifiable
│   │   ├── User.swift               # AppUser, UserStats, UserGoals
│   │   ├── Workout.swift
│   │   ├── CharacterCard.swift
│   │   ├── Achievement.swift
│   │   ├── Challenge.swift
│   │   ├── BeltChallenge.swift
│   │   ├── RecoveryMetrics.swift
│   │   └── FeedItem.swift           # Includes WorkoutGroup model
│   ├── Services/                    # All @MainActor Observable
│   │   ├── AuthService.swift
│   │   ├── FirestoreService.swift
│   │   ├── HealthKitService.swift
│   │   ├── StatCalculator.swift
│   │   └── NotificationService.swift
│   ├── Views/                       # Organized by feature
│   │   ├── Auth/                    # LoginView, GuidedOnboardingFlow
│   │   ├── Card/                    # CharacterCardView, themes, StatRadarView
│   │   ├── Workout/                 # LogWorkoutView, WorkoutHistoryView
│   │   ├── Feed/                    # FeedView, FeedItemView
│   │   ├── Progress/                # XPRecoveryView
│   │   ├── Group/                   # GroupView, LeaderboardView, ChallengeView
│   │   ├── Achievements/
│   │   └── Settings/
│   ├── Utilities/
│   │   ├── Constants.swift          # ALL enums (WorkoutType, MuscleClass, etc.)
│   │   └── Extensions.swift         # Color, Font, Date extensions
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   └── Fonts/
│   └── Info.plist
├── MuscleDaddiesPreview/            # Preview target (uses PreviewApp.swift)
└── functions/                       # Firebase Cloud Functions (Node.js)
```

---

## Firestore Schema

**Collections:**

```
users/{uid}
  - displayName, avatarURL, joinedAt, groupId, fcmToken
  - stats: UserStats (strength, speed, endurance, intelligence, level, xp, hp)
  - currentStreak, longestStreak, lastWorkoutDate
  - selectedTheme: CardTheme, classTheme: ClassTheme, selectedClass: MuscleClass
  - priorityPrimary, prioritySecondary: PriorityStat
  - heightCm, weightKg, bodyType, goals: UserGoals

groups/{groupId}
  - name, inviteCode, createdBy, createdAt, memberIds[]

workouts/{workoutId}
  - userId, groupId, type: WorkoutType, source: WorkoutSource
  - duration (mins), intensity (1-5 RPE)
  - energyBurned?, distance?, averageHeartRate?, estimatedHeartRate?
  - strengthExercise?, strengthReps?, strengthWeightKg?
  - notes?, createdAt, healthKitUUID? (dedup key)

feed/{feedItemId}
  - groupId, userId, userName, type: FeedItemType, content, createdAt
  - reactions: {emoji: [userId...]}
  - comments: [Comment]

recovery/{userId}/daily/{yyyy-MM-dd}
  - sleepMinutes7d, mindfulMinutes7d
  - hrvSDNN, restingHeartRate, heartRateRecovery1Min

challenges/{challengeId}
  - groupId, title, metric, startDate, endDate
  - participants: {userId: score}

beltChallenges/{challengeId}
  - groupId, challengerId, opponentId, stat
  - status: pending|active|declined|completed|expired
  - durationDays, startDate, endDate, winnerId?

achievements/{achievementId}
  - userId, type: AchievementType, unlockedAt
```

**Query Patterns:**
- Most queries filter by `userId` or `groupId`
- Date-based queries use `createdAt` with `.order(by:)` + `.limit()`
- No custom Firestore indexes needed (simple queries only)

---

## View Architecture

**Root Navigation (ContentView):**
- TabView with 7 tabs: Card, Progress, Feed, Challenges, Log (floats top-right), Group, Settings
- All services injected as `@EnvironmentObject`
- `onAppear` triggers HealthKit sync + recovery metrics fetch

**Common View Patterns:**
- Use `NavigationStack` for local navigation
- Use `.sheet()` for modals (e.g., Log Workout)
- Use `.alert()` for confirmations/errors
- Custom fonts: `.primary()`, `.secondary()`, `.pixel()`
- Custom colors: `.statRed`, `.statBlue`, `.statGreen`, `.statPurple`, `.cardGold`, `.cardDark`
- Dark mode enforced: `.preferredColorScheme(.dark)`

**Card Themes:**
- Each theme has distinct layout in `Views/Card/CardThemes/`
- `ModernTheme` - Radar chart background, Sci-Fi styling
- `PixelArtTheme` - Retro pixel art, Fantasy styling
- `TradingCardTheme` - Classic card layout, Sports styling

---

## Development Workflow

### Building the Project

1. **Generate Xcode Project:**
   ```bash
   cd /Users/tj/MuscleDaddies
   xcodegen generate
   ```

2. **Open in Xcode:**
   ```bash
   open MuscleDaddies.xcodeproj
   ```

3. **Run in Simulator:**
   - Select `MuscleDaddies` scheme
   - Demo mode will activate automatically if Firebase not configured

4. **Run Preview Target:**
   - Select `MuscleDaddiesPreview` scheme
   - Uses `PreviewApp.swift` instead of `MuscleDaddiesApp.swift`

### Firebase Setup

**Required Files:**
- `GoogleService-Info.plist` (download from Firebase Console)
- Place in `/Users/tj/MuscleDaddies/MuscleDaddies/`

**Deploy Firestore Rules:**
```bash
firebase deploy --only firestore:rules
```

**Deploy Cloud Functions:**
```bash
cd functions
npm install
firebase deploy --only functions
```

### HealthKit Testing

- Test on physical device (HealthKit not available in simulator)
- Use Health app to add sample workouts/sleep/HRV data
- Trigger sync from Settings tab

---

## Common Tasks

### Adding a New Workout Type

1. Add to `WorkoutType` enum in `Constants.swift`
2. Update `StatCalculator.calculateWorkoutXP()` with XP logic
3. Add icon/label to `LogWorkoutView` picker
4. Update demo data in services

### Adding a New Achievement

1. Add to `AchievementType` enum in `Constants.swift`
2. Add unlock logic to `FirestoreService.checkAndUnlockAchievements()`
3. Update demo data in `AuthService.demoAchievements`

### Adding a New Class

1. Add to `MuscleClass` enum in `Constants.swift`
2. Assign to a `ClassTheme` (fantasy/sports/scifi)
3. Add stat weights in `StatCalculator.classWeights`
4. Add class image to `Assets.xcassets/Class Images/`
5. Update `GuidedOnboardingFlow` class picker

### Modifying XP Calculation

- Edit `StatCalculator.calculateWorkoutXP()`
- Respect class weights (applied after base calculation)
- Test with demo mode first

### Adding a New Service

1. Create in `Services/` folder
2. Use `@MainActor class SomeService: ObservableObject`
3. Add `lazy var db = Firestore.firestore()`
4. Add `var isDemoMode: Bool { !AppDelegate.firebaseConfigured }`
5. Inject in `MuscleDaddiesApp` as `@StateObject`
6. Add to `ContentView` `.environmentObject()` chain

---

## Testing & Demo Mode

**Testing Without Firebase:**
- Delete or rename `GoogleService-Info.plist`
- App will enter demo mode automatically
- All services return static demo data
- Full app functionality testable

**Testing With Firebase:**
- Ensure `GoogleService-Info.plist` is present
- Check Firestore rules allow your test user
- Monitor Firebase Console for data writes

**Testing HealthKit:**
- Physical device required
- Request permissions in Settings tab
- Add sample data in Health app
- Trigger sync from Settings

---

## Things to NEVER Do

1. **DO NOT** use `Group` as a type name (use `WorkoutGroup`)
2. **DO NOT** use `User` as a type name (use `AppUser`)
3. **DO NOT** call Firestore without checking `isDemoMode`
4. **DO NOT** use `var db = Firestore.firestore()` without `lazy`
5. **DO NOT** forget `@MainActor` on new services
6. **DO NOT** add HealthKit workouts without checking `healthKitUUID` deduplication
7. **DO NOT** modify `project.yml` without running `xcodegen generate` after
8. **DO NOT** create custom Firestore indexes (keep queries simple)
9. **DO NOT** use force unwrapping (`!`) on optional Firestore fields
10. **DO NOT** hardcode XP values (use `StatCalculator` methods)

---

## Known Issues & Gotchas

1. **Apple Sign-In Provider:**
   - Not yet enabled in Firebase Console
   - Requires manual activation at console.firebase.google.com

2. **APNs Key Upload:**
   - Required for production push notifications
   - Upload to Firebase Console → Cloud Messaging

3. **Xcode Sign in with Apple Capability:**
   - Requires paid Apple Developer account
   - Add in Xcode → Signing & Capabilities

4. **Cloud Functions:**
   - Written but not yet deployed
   - Run `npm install && firebase deploy --only functions`

5. **Achievement Auto-Unlock:**
   - ✅ Implemented in `FirestoreService.checkAndUnlockAchievements()`
   - ✅ Called after workout logging in `LogWorkoutView`
   - ✅ Called after HealthKit sync in `ContentView`
   - ✅ Celebration overlay with confetti animation
   - ✅ Feed posts for unlocked achievements
   - ✅ Haptic feedback on unlock
   - ⚠️ "Daddy of the Month" requires monthly cron job (future enhancement)

6. **Streak Shame/Fame Board:**
   - Planned feature for `GroupView`
   - Show top streaks + broken streaks in group

---

## Code Style Guide

**SwiftUI Conventions:**
- Prefer `async/await` over completion handlers
- Use `try await` for Firestore calls
- Handle errors with `do-catch` or `.task { }`
- Use `.onAppear` for initial data loads
- Use `.task` for async operations tied to view lifecycle

**Naming:**
- Services: `SomeService.swift`
- Views: `SomeView.swift`
- Models: `SomeModel.swift` or `Some.swift`
- Extensions: `+SomeExtension.swift` or in `Extensions.swift`

**Formatting:**
- 4-space indentation
- Opening braces on same line
- Use `//MARK: - Section Name` for organization
- Keep methods under 50 lines when possible

**Comments:**
- Add comments for complex business logic (XP calculations, HP formulas)
- Document non-obvious HealthKit deduplication patterns
- Explain demo mode fallbacks when not obvious

---

## Current Status & Roadmap

**✅ Completed:**
- Demo mode with full fake data
- Firebase Auth (Apple Sign-In)
- Firestore CRUD for all entities
- HealthKit sync with deduplication
- Recovery metrics (sleep, HRV, HR)
- 24-class system with stat weights
- XP/Level/HP calculations
- 3 card themes (Modern, Pixel Art, Trading Card)
- Group system with feed
- Challenges (group + belt 1v1)
- Push notification infrastructure
- **Achievement auto-unlock system** with celebration animations

**🚧 In Progress:**
- Streak shame/fame board

**📋 TODO:**
- Enable Apple Sign-In in Firebase Console
- Upload APNs key to Firebase
- Deploy Cloud Functions
- Add Xcode Sign in with Apple capability
- Polish app icon + launch screen
- TestFlight beta

**🎯 User-Requested Features:**
- Waiting for user to provide custom feature outline

---

## Quick Reference

**Regenerate Xcode Project:**
```bash
xcodegen generate
```

**Deploy Firestore Rules:**
```bash
firebase deploy --only firestore:rules
```

**Deploy Functions:**
```bash
cd functions && npm install && firebase deploy --only functions
```

**Toggle Demo Mode:**
```swift
UserDefaults.standard.set(true, forKey: "forceDemo") // Force demo
UserDefaults.standard.removeObject(forKey: "forceDemo") // Reset
```

**Key Constants:**
- Workout types: `WorkoutType` enum (10 types)
- Classes: `MuscleClass` enum (24 classes)
- Themes: `CardTheme` enum (modern, pixel, trading)
- Class themes: `ClassTheme` enum (fantasy, sports, scifi)
- Achievements: `AchievementType` enum (7 types)
- Stats: strength, speed, endurance, intelligence (0-99 display range)

---

## Contact & Support

- **Firebase Console**: https://console.firebase.google.com/project/muscle-daddies
- **Project Path**: `/Users/tj/MuscleDaddies/`
- **Xcode Project**: `MuscleDaddies.xcodeproj` (generated)
- **Source Control**: Check `.git/` for repo status

---

**Last Updated**: 2026-02-10
**Version**: Extended MVP with RPG systems
