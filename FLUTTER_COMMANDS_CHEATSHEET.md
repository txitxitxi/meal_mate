# Flutter Commands Cheat Sheet

## Project Setup

```bash
# Create a new Flutter project
flutter create <project_name>

# Create a project with a specific organization
flutter create --org com.example <project_name>

# Create a project for specific platforms only
flutter create --platforms=android,ios <project_name>

# Get Flutter version and check setup
flutter --version
flutter doctor
flutter doctor -v  # Verbose output
```

## Running Apps

```bash
# Run app on connected device/emulator
flutter run

# Run in release mode
flutter run --release

# Run in profile mode (for performance testing)
flutter run --profile

# Run with hot reload enabled (default)
flutter run --hot

# Run without hot reload
flutter run --no-hot

# Run on specific device
flutter run -d <device_id>
flutter devices  # List available devices

# Run specific target file
flutter run -t lib/main.dart
```

## Building Apps

### Android

```bash
# Build APK (debug)
flutter build apk

# Build APK (release)
flutter build apk --release

# Build split APKs (smaller size)
flutter build apk --split-per-abi

# Build App Bundle (for Play Store)
flutter build appbundle
```

### iOS

```bash
# Build iOS app
flutter build ios

# Build iOS app (release)
flutter build ios --release

# Build for simulator
flutter build ios --simulator
```

### Web

```bash
# Build web app
flutter build web

# Build web app with base href
flutter build web --base-href /myapp/
```

### Desktop

```bash
# Build for macOS
flutter build macos

# Build for Windows
flutter build windows

# Build for Linux
flutter build linux
```

## Dependencies

```bash
# Get dependencies (download packages from pubspec.yaml)
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Upgrade to latest compatible versions
flutter pub upgrade --major-versions

# Add a dependency
flutter pub add <package_name>

# Add a dev dependency
flutter pub add --dev <package_name>

# Remove a dependency
flutter pub remove <package_name>

# Update packages
flutter pub outdated

# Verify dependencies
flutter pub deps
```

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in watch mode
flutter test --watch
```

## Code Generation & Analysis

```bash
# Run code generation (for packages like json_serializable, freezed, etc.)
flutter pub run build_runner build

# Run code generation with watch mode (auto-regenerate on changes)
flutter pub run build_runner watch

# Clean and rebuild generated code
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze code for errors and warnings
flutter analyze

# Format code
flutter format .

# Format specific file/directory
flutter format lib/
```

## Hot Reload & Hot Restart

```bash
# Hot reload (press 'r' in terminal during flutter run)
# Or save file in IDE (automatic)

# Hot restart (press 'R' in terminal during flutter run)
# Restarts the app, losing state

# Full restart (stop and restart)
flutter run
```

## Device Management

```bash
# List connected devices
flutter devices

# Launch iOS Simulator
open -a Simulator

# Launch Android Emulator (after starting from Android Studio)
flutter emulators

# Launch specific emulator
flutter emulators --launch <emulator_id>

# Check device info
flutter devices -v
```

## Cleaning & Maintenance

```bash
# Clean build files
flutter clean

# Clean and get dependencies
flutter clean && flutter pub get

# Clear Flutter cache
flutter cache clean

# Clear specific cache
flutter cache clean pub
```

## Upgrading Flutter

```bash
# Upgrade Flutter SDK
flutter upgrade

# Upgrade to specific channel
flutter channel stable
flutter channel beta
flutter channel dev
flutter channel master

# Switch channel and upgrade
flutter channel <channel_name> && flutter upgrade
```

## Platform-Specific

### iOS

```bash
# Install CocoaPods dependencies
cd ios && pod install && cd ..

# Update CocoaPods
cd ios && pod update && cd ..

# Open iOS project in Xcode
open ios/Runner.xcworkspace
```

### Android

```bash
# Open Android project in Android Studio
# Navigate to android/ folder in Android Studio

# Build Gradle
cd android && ./gradlew build && cd ..
```

## Info & Diagnostics

```bash
# Show Flutter environment info
flutter doctor

# Show verbose diagnostics
flutter doctor -v

# Show build info
flutter build apk --verbose

# Show logs
flutter logs

# Show installed packages
flutter pub deps
```

## Performance & Profiling

```bash
# Run with performance overlay
flutter run --profile --dart-define=FLUTTER_WEB_USE_SKIA=true

# Enable performance overlay in code
# MaterialApp(showPerformanceOverlay: true)
```

## Internationalization

```bash
# Generate localization files
flutter gen-l10n

# Or if using intl package
flutter pub run intl_translation:generate_from_arb ...
```

## Useful Shortcuts (during `flutter run`)

```
r    - Hot reload
R    - Hot restart
h    - List all commands
c    - Clear screen
q    - Quit
d    - Detach (run in background)
p    - Toggle performance overlay
o    - Toggle platform (iOS/Android on web)
w    - Dump widget hierarchy
t    - Dump rendering tree
```

## Common Workflows

```bash
# Setup new project
flutter create my_app
cd my_app
flutter pub get
flutter run

# Clean rebuild after major changes
flutter clean
flutter pub get
flutter run

# Prepare for release
flutter clean
flutter pub get
flutter build appbundle  # Android
flutter build ios        # iOS

# Update everything
flutter upgrade
flutter pub upgrade
flutter clean
flutter pub get
```

## Troubleshooting

```bash
# Reset Flutter completely
flutter doctor -v  # Check issues
flutter clean
flutter pub cache repair
flutter pub get

# Fix iOS Pod issues
cd ios
pod deintegrate
pod install
cd ..

# Clear derived data (iOS)
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## Version Management

```bash
# Check Flutter version
flutter --version

# Check Dart version
dart --version

# Switch Flutter version (using fvm - Flutter Version Management)
fvm install <version>
fvm use <version>
fvm list
```

---

**Quick Reference:**
- `flutter run` - Run your app
- `flutter pub get` - Get dependencies
- `flutter clean` - Clean build files
- `flutter doctor` - Check setup
- `flutter analyze` - Check for errors
- `flutter test` - Run tests
