
# 🗂️ DayDo App – Build & Setup Guide

This guide walks you through the steps to set up and build the **DayDo** task management app. It includes installing dependencies, generating Hive adapters, and resolving common issues.

---

## ✅ Prerequisites

Before getting started, make sure the following are set up:

- **Flutter SDK**: Version `>=2.12.0 <4.0.0`
- **Dart SDK**: Version `3.8.1` or compatible
- **Project Setup**: Project directory includes:
  - `pubspec.yaml`
  - Source files (e.g. `lib/models/task.dart`)

---

## 🚀 Build & Generate Steps

### 1. 🧹 Clean the Project

Removes cached build files to start fresh:

```bash
flutter clean
```

---

### 2. 📦 Fetch Dependencies

Installs all dependencies listed in `pubspec.yaml`:

```bash
flutter pub get
flutter packages upgrade
```

---

### 3. 🏗️ Generate Hive Adapters

Generates `.g.dart` files for Hive (e.g., `task.g.dart`). The flag ensures any conflicts are automatically resolved:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter packages pub run build_runner build
```

---

### 4. 🔄 Watch for Changes (Optional)

Watches your code and regenerates files automatically when changes are made:

```bash
flutter packages pub run build_runner watch --delete-conflicting-outputs
```

---

## 🛠️ Troubleshooting

### 🔹 Error: `part 'task.g.dart' not found`

- Ensure `task.dart` includes:
  ```dart
  part 'task.g.dart';
  ```
- Check `dev_dependencies` for:
  ```yaml
  dev_dependencies:
    hive_generator: ^2.0.1
    build_runner: ^2.4.6
  ```
- Rerun the build command after fetching dependencies:
  ```bash
  flutter pub get
  flutter packages pub run build_runner build --delete-conflicting-outputs
  ```

---

### 🔹 Error: Dependency Conflicts

- Validate versions in `pubspec.yaml`, e.g.:
  ```yaml
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  ```
- Run:
  ```bash
  flutter pub get
  ```

---

### 🔹 Error: Hive Type ID Conflict

- Ensure unique `typeId`s in Hive models:
  ```dart
  @HiveType(typeId: 0) // For Task
  @HiveType(typeId: 1) // For TimeOfDayAdapter
  ```

---

### 🔹 Error: Build Fails Due to Conflicts

- Delete existing `.g.dart` files manually (e.g., `task.g.dart`) and rerun:
  ```bash
  flutter packages pub run build_runner build --delete-conflicting-outputs
  ```

---

## 📁 Additional Notes

- **File Locations**: Place `task.dart` and `task.g.dart` in the same directory (e.g., `lib/models/`).
- **App Icon**: Place an icon named `app_icon.png` in `android/app/src/main/res/drawable/` for notifications.
- **Permissions**: Check Android and iOS configurations:
  - `AndroidManifest.xml` (for notifications, image picker)
  - `Info.plist` (for iOS-specific permissions)
- **Testing**: After setup, run the app to confirm all features work:
  ```bash
  flutter run
  ```

---

If you encounter errors, refer to the messages above or consult the [Flutter documentation](https://docs.flutter.dev).
