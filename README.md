# Kalpana

Kalpana is a voice-first accessibility assistant built with Flutter for Android. It is designed to help users interact with an accessible interface through voice-based commands and spoken feedback.

## Features

- Voice-based interaction using speech recognition
- Spoken responses using text-to-speech
- Support for English, Hindi, and Marathi
- Onboarding and user profile setup
- Emergency contact selection flow (in progress)
- Accessibility-focused interface with a luminous pastel-orb design
- Additional features being developed collaboratively by the team

> Note: Features may be incomplete while development is in progress. Emergency contact selection, saving, and SOS calling should not be considered fully implemented until verified.

## Tech Stack

- Flutter and Dart
- Android
- `speech_to_text` for speech recognition
- `flutter_tts` for spoken feedback
- `permission_handler` for runtime permissions
- `flutter_contacts` for accessing device contacts
- `geolocator` for location-related functionality
- `shared_preferences` for local preferences and profile data

Refer to `pubspec.yaml` for the complete dependency list.

## Prerequisites

Install the following before running the project:

1. Git
2. Flutter SDK (the project was developed with Flutter 3.35.3)
3. Dart SDK compatible with the installed Flutter version
4. Android Studio with the Android SDK and platform tools
5. VS Code or Android Studio as your editor
6. An Android device with USB debugging enabled, or an Android emulator

Flutter includes the Dart SDK, so a separate Dart installation is usually unnecessary.

## Verify Your Setup

Open a terminal and run:

```bash
flutter --version
flutter doctor
```

Resolve any required Android toolchain issues shown by `flutter doctor`. If needed, accept the Android SDK licenses:

```bash
flutter doctor --android-licenses
```

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/AnuP1306/Kalpana_Final.git
cd Kalpana_Final
```

### 2. Switch to the development branch

If the team is currently using the emergency-contact development branch:

```bash
git switch feature/emergency-contact
```

If the repository's default branch is already the branch your team is using, you can skip this step.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Connect a device

Connect an Android phone with USB debugging enabled, or start an Android emulator.

Check available devices:

```bash
flutter devices
```

### 5. Run the app

```bash
flutter run
```

To select a specific device:

```bash
flutter run -d <device-id>
```

Replace `<device-id>` with an ID listed by `flutter devices`.

## Android Permissions

Kalpana may request permissions for features such as:

- Microphone access for voice interaction
- Contacts access for emergency-contact selection
- Camera access for camera-based features
- Location access for location-related features

Grant permissions when prompted if you want to use the corresponding features. Permission availability and behavior depend on the Android version and device settings.

If a permission was denied permanently, open the app's settings on your device and enable the required permission.

## Project Structure

```text
Kalpana_Final/
├── android/                 # Android platform project
├── lib/
│   ├── app_controller.dart  # App flow and state management
│   ├── screens.dart        # App screens and UI
│   ├── strings.dart        # Language strings
│   └── voice/
│       ├── voice_service.dart
│       └── command_router.dart
├── assets/                  # App assets, if present
├── pubspec.yaml             # Dependencies and project configuration
├── pubspec.lock             # Locked dependency versions
├── analysis_options.yaml    # Dart analysis configuration, if present
├── .gitignore
└── README.md
```

The structure above highlights key files; folders and files may vary as the project evolves.

## Development Workflow

Please create a separate branch for each feature or fix. Avoid committing directly to `main`.

Create a new branch:

```bash
git switch main
git pull origin main
git switch -c feature/your-feature-name
```

After making changes:

```bash
git status
git add <files-you-intend-to-commit>
git commit -m "Describe your change"
git push -u origin feature/your-feature-name
```

Then open a Pull Request on GitHub so the team can review and merge your changes.

Before committing, check `git status` and make sure you are not including generated files, credentials, or unrelated changes.

Coordinate before editing shared files such as `app_controller.dart`, `screens.dart`, and `voice/command_router.dart` to reduce merge conflicts.

## Troubleshooting

### Dependencies are missing

```bash
flutter pub get
```

### Flutter cannot find a device

```bash
flutter doctor
flutter devices
```

Check USB debugging, your USB connection, Android SDK setup, or emulator status.

### Android build or plugin errors

Try:

```bash
flutter clean
flutter pub get
flutter run
```

`flutter clean` removes generated build output; it does not remove your Dart source code.

### Permission problems

Check the app's permissions in Android Settings and ensure the relevant permissions are declared and requested by the application.

## Security

- Never commit API keys, passwords, signing keys, private certificates, or service-account credentials.
- Keep local environment files out of Git.
- If a feature requires a secret, share setup instructions with the team rather than committing the secret.

## Team Contributions

This is a collaborative project. Please use feature branches, write clear commit messages, and open Pull Requests for review.

## License

No license has been specified yet. Do not assume the project is open-source or reuse it under a particular license unless the team agrees on one.
