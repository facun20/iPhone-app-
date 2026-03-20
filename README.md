# FocusSnap

An iOS app that locks your distracting apps until you complete real-world challenges — take a photo outside, hit a step goal, finish a workout, or just wait until the right time.

## How It Works

1. **Create a profile** — Pick which apps to block and what challenge unlocks them
2. **Start a session** — One tap shields all your selected apps using Screen Time
3. **Earn your apps back** — Complete the challenge (snap a photo, walk 5K steps, etc.)
4. **Apps unlock** — Shields are removed once the condition is met

You can set a single unlock challenge for all apps, or assign different conditions per app (e.g., Twitter needs 10K steps, Instagram needs a photo).

## Unlock Conditions

| Condition | How it works |
|-----------|-------------|
| **Photo** | Take a real photo matching a category (outdoor, gym, book, nature, food, pet, workspace) — verified on-device using Vision/CoreML |
| **Steps** | Reach a step count goal (pulled from HealthKit) |
| **Distance** | Walk or run a target distance |
| **Workout** | Complete a workout of any type for X minutes |
| **Time-based** | Apps unlock automatically after a specific time of day |

## Photo Challenges

The app uses Apple's Vision framework to verify photos are real and match the challenge. For example, "Go Outside" checks for keywords like sky, street, park, sunlight. No cheating with saved screenshots.

Categories: Outdoor, Book, Gym, Nature, Food, Pet, Workspace, or Custom (with your own keywords).

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
│   └── UnlockCondition.swift       # Unlock condition types & per-app rules
├── Services/
│   ├── AuthorizationManager.swift  # Family Controls authorization
│   ├── SessionManager.swift        # Start/end sessions, apply/remove shields
│   ├── ProfileManager.swift        # CRUD for focus profiles
│   ├── CameraService.swift         # Camera capture for photo challenges
│   ├── HealthKitService.swift      # Steps, distance, workout data from HealthKit
│   └── ImageVerificationService.swift  # Vision-based photo verification
└── Views/
    ├── ContentView.swift           # Root view (onboarding vs main flow)
    ├── MainTabView.swift           # Tab bar (Home, Profiles, Stats, Settings)
    ├── HomeView.swift              # Dashboard with session start & history
    ├── LockedView.swift            # Shown during active session with progress
    ├── OnboardingView.swift        # First-launch setup flow
    ├── CameraCaptureView.swift     # Camera UI for photo challenges
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
- **HealthKit** — Read steps, distance, and workout data
- **AVFoundation** — Camera capture for photo challenges
- **Vision / CoreML** — On-device image classification to verify photos
- **SwiftUI** — All UI

## Features

- **Per-app unlock rules** — Different conditions for different apps in the same session
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
