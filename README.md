# DailyDuel

**Challenge Yourself. Rise Every Day.**

DailyDuel is a Flutter challenge app with local demo authentication, timed
knowledge quizzes, a coding-challenge interface, rankings, activity history,
achievements, notifications, profile controls, and admin demonstration screens.
Its repositories are mock/local implementations intended to be replaceable by a
future backend.

## Features

- Animated splash screen and three-step onboarding.
- Local demo sign-in, registration, password-reset UI, and informational pages.
- Home dashboard and daily General Knowledge, Technical, and Coding challenges.
- Challenge catalogue with category, difficulty, and text filters.
- Timed quizzes with question navigation, answer marking, scoring, results, and
  answer review.
- Coding editor with language selection and a clearly labeled simulated submit
  response. The app does not compile or execute submitted code.
- Global, weekly, daily, and friends leaderboards populated with demonstration
  data. Rankings are not synchronized between real users.
- Local quiz history, profile editing, achievements, and notifications.
- Persistent light/dark/system theme and notification preferences.
- Admin demonstration screens for quiz drafts and read-only mock users.

## Requirements

- Flutter SDK and Dart SDK matching the minimum versions in `pubspec.yaml`
  (Flutter 3.41.6 / Dart 3.11.4 were used for this update).
- Android SDK and an emulator or Android device for Android builds and runs.

Check the local setup with:

```shell
flutter doctor
```

## Install and run

From the project root:

```shell
flutter pub get
flutter run
```

To select a connected device:

```shell
flutter devices
flutter run -d <device-id>
```

The demo account is:

- Email: `demo@dailyduel.com`
- Password: `Demo@1234`

Admin demonstration credentials:

- Email: `admin@dailyduel.com`
- Password: `Admin@1234`

Authentication is simulated and account/profile data is stored locally on the
device. This build does not authenticate against a remote service.

## Tests and analysis

```shell
dart format .
flutter analyze
flutter test
```

## Build a debug APK

```shell
flutter build apk --debug
```

The generated APK is:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Install on a connected Android device with:

```shell
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Alternatively, copy the APK to the phone and open it to install. If Android
blocks the installation, allow installs from that file manager in Android's
unknown-app settings.

## Backend and data status

No Firebase, Appwrite, Supabase, remote database, paid entry, or real-money
prizes are used. Challenge definitions, leaderboard entries, and achievements
include mock data; quiz attempts and preferences use local storage. Local demo
rankings do not represent a shared competition.

Authentication and registration are simulated. The coding challenge editor does
not execute code. Admin quiz drafts are only retained for the current screen
session, and the admin user list is read-only. Uninstalling or clearing app data
removes device-local state.
