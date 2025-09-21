# App Icon Update Instructions

## New App Name: 小饭堂
The app display name has been updated to "小饭堂" in:
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`

## New App Icon Design
A custom orange-themed app icon has been created with:
- Light orange background (#FFF5E6)
- Orange plate with gradient effect
- Brown chopsticks (angled)
- Silver fork, knife, and spoon
- Golden steam lines
- Small food elements

## To Complete the Icon Update:

### Option 1: Online Converter (Recommended)
1. Open the SVG file: `assets/app_icon.svg`
2. Use an online SVG to PNG converter like:
   - https://convertio.co/svg-png/
   - https://cloudconvert.com/svg-to-png
   - https://www.freeconvert.com/svg-to-png

3. Generate the following sizes:

**Android Icons:**
- 48x48px → save as `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- 72x72px → save as `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- 96x96px → save as `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- 144x144px → save as `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- 192x192px → save as `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

**iOS Icons:**
- 20x20px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png`
- 40x40px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png`
- 60x60px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png`
- 29x29px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png`
- 58x58px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png`
- 87x87px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png`
- 40x40px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png`
- 80x80px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png`
- 120x120px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png`
- 120x120px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png`
- 180x180px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png`
- 76x76px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png`
- 152x152px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png`
- 167x167px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png`
- 1024x1024px → save as `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`

### Option 2: Using Flutter Icon Generator
If you have the flutter_launcher_icons package:
1. Install: `flutter pub add dev:flutter_launcher_icons`
2. Create `flutter_launcher_icons.yaml`:
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/app_icon.png"  # Convert SVG to PNG first
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/app_icon.png"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  windows:
    generate: true
    image_path: "assets/app_icon.png"
    icon_size: 48
```

### Option 3: Manual Image Editor
1. Open the SVG in an image editor (Photoshop, GIMP, etc.)
2. Export at each required size
3. Replace the existing PNG files

## After Icon Update:
Run `flutter clean && flutter pub get` to ensure all changes are applied.
