# FocusSnap

An iOS app that locks your distracting apps until you complete real-world challenges — take a photo outside, hit a step goal, show up at the gym, meditate, or journal your thoughts.

## How It Works

1. **Create a profile** — Pick which apps to block and what challenge unlocks them
2. **Start a session** — One tap shields all your selected apps using Screen Time
3. **Earn your apps back** — Complete the challenge (snap a photo, walk 5K steps, arrive at a location, etc.)
4. **Apps unlock** — Shields are removed once the condition is met

You can set a single unlock challenge for all apps, or assign different conditions per app (e.g., Twitter needs 10K steps by noon, Instagram needs a photo, TikTok needs 5 minutes of prayer).

## Unlock Conditions

| Condition | How it works |
|-----------|-------------|
| **Photo** | Take a real photo matching a category (outdoor, gym, book, nature, food, pet, workspace) — verified on-device using Vision/CoreML |
| **Steps** | Reach a step count goal (pulled from HealthKit) |
| **Distance** | Walk or run a target distance |
| **Workout** | Complete a workout of any type for X minutes |
| **Calories** | Burn X active calories tracked by Apple Health |
| **Flights Climbed** | Climb X flights of stairs tracked by your phone |
| **Mindfulness** | Complete a meditation, prayer, or breathing session with an in-app timer (also writes to Apple Health) |
| **Journaling** | Write a journal entry hitting a minimum word count, with optional prompts |
| **Location** | Arrive at a saved place — gym, school, office, church, library — verified via GPS geofencing |
| **Time-based** | Apps unlock automatically after a specific time of day |

### Deadlines

Any condition can have an optional **deadline** — e.g., "5,000 steps by 10:00 AM" or "journal 50 words by noon". The deadline shows up on the unlock card so you know exactly when you need to finish.

## Photo Challenges

The app uses Apple's Vision framework to verify photos are real and match the challenge. For example, "Go Outside" checks for keywords like sky, street, park, sunlight. No cheating with saved screenshots.

Categories: Outdoor, Book, Gym, Nature, Food, Pet, Workspace, or Custom (with your own keywords).

## Mindfulness & Prayer

The in-app mindfulness timer supports different labels — **Meditation**, **Prayer**, or **Breathing** — each with its own visual theme and motivational message. Completed sessions are saved to Apple Health as mindful minutes. Set any duration from 1 to 60 minutes.

## Location-Based Unlock

Set a place like the gym, library, school, or office. The app uses GPS to verify you actually showed up. Search for any place by name with quick presets for common locations (Gym, Library, School, Office, Church, Park, Coffee Shop). Uses a 100-meter geofence radius.

## Project Structure

```
FocusSnap/                          # Main app target
├── FocusSnapApp.swift              # Entry point
├── Info.plist                      # App configuration & permissions
├── FocusSnap.entitlements          # Family Controls entitlement
├── Assets.xcassets/                # App icon & colors
├── Models/
│   ├── FocusProfile.swift          # Profile with unlock rules & app selections
│   ├── Challenge.swift             # Photo challenge types & Vision keywords
│   ├── FocusSession.swift          # Session tracking (start, end, duration)
│   └── UnlockCondition.swift       # All condition types, deadlines, per-app rules
├── Services/
│   ├── AuthorizationManager.swift  # Family Controls authorization
│   ├── SessionManager.swift        # Start/end sessions, apply/remove shields
│   ├── ProfileManager.swift        # CRUD for focus profiles
│   ├── CameraService.swift         # Camera capture for photo challenges
│   ├── HealthKitService.swift      # Steps, distance, calories, flights, workouts, mindful minutes
│   ├── ImageVerificationService.swift  # Vision-based photo verification
│   ├── LocationService.swift       # GPS geofencing for location-based unlock
│   └── MindfulnessService.swift    # In-app meditation/prayer timer + HealthKit write
└── Views/
    ├── ContentView.swift           # Root view (onboarding vs main flow)
    ├── MainTabView.swift           # Tab bar (Home, Profiles, Stats, Settings)
    ├── HomeView.swift              # Dashboard with session start & history
    ├── LockedView.swift            # Active session with progress cards for each rule
    ├── OnboardingView.swift        # First-launch setup flow
    ├── CameraCaptureView.swift     # Camera UI for photo challenges
    ├── MindfulnessView.swift       # Full-screen timer for meditation/prayer/breathing
    ├── JournalingView.swift        # Journal entry editor with word count progress
    ├── LocationPickerView.swift    # Search & pick a place for location conditions
    ├── ProfilesView.swift          # List & manage profiles
    ├── EditProfileView.swift       # Create/edit a profile with rules
    ├── SettingsView.swift          # App settings
    └── StatsView.swift             # Focus time & session statistics

DeviceActivityMonitorExtension/     # Monitors Screen Time activity
ShieldConfigurationExtension/       # Customizes the app-blocking shield UI
ShieldActionExtension/              # Handles shield button actions (dismiss/unlock)
```

## Key Frameworks

- **FamilyControls / ManagedSettings** — Block and unblock apps using Screen Time APIs
- **HealthKit** — Read steps, distance, calories, flights, workouts; write mindful sessions
- **CoreLocation / MapKit** — GPS geofencing and place search for location-based unlock
- **AVFoundation** — Camera capture for photo challenges
- **Vision / CoreML** — On-device image classification to verify photos
- **SwiftUI** — All UI

## Features

- **10 unlock condition types** — Photo, steps, distance, workout, calories, flights, mindfulness, journaling, location, time-based
- **Per-app unlock rules** — Different conditions for different apps in the same session
- **Deadlines** — Optional "complete by" time on any condition
- **Meditation & prayer timer** — In-app timer with HealthKit integration
- **Location arrival** — GPS-verified "show up" challenges
- **Journal to unlock** — Write your thoughts to earn screen time
- **Emergency unlock** — Limited-use escape hatch (5 per profile by default)
- **Streak tracking** — Counts consecutive days with completed sessions
- **Session history** — See past sessions, durations, and whether emergency unlock was used
- **Multiple profiles** — "Morning Routine", "Deep Work", "Get Moving", etc.
- **Dark theme** — Full dark mode UI

## Requirements

- iOS 16+
- Xcode 15+
- Physical device recommended (Screen Time APIs have limited simulator support)

## Building

```bash
# Clone
git clone https://github.com/facun20/iPhone-app-.git
cd iPhone-app-

# Open in Xcode
open FocusSnap.xcodeproj

# Build for simulator (no code signing needed)
xcodebuild build \
  -project FocusSnap.xcodeproj \
  -scheme FocusSnap \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

For device builds, you'll need an Apple Developer account with the Family Controls entitlement approved.

## CI/CD

Builds run on [Codemagic](https://codemagic.io) via `codemagic.yaml`. The pipeline builds a simulator `.app` artifact that can be previewed using Codemagic's App Preview feature.
