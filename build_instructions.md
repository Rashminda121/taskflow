Build Instructions for DayDo App
This document outlines the steps to set up and generate necessary files for the DayDo app, ensuring all dependencies are installed and Hive adapters are correctly generated.
Prerequisites

Flutter SDK: Ensure Flutter is installed (version compatible with SDK >=2.12.0 <4.0.0).
Dart SDK: Version 3.8.1 or compatible.
Project Setup: Clone or set up the DayDo project directory with the provided pubspec.yaml and source files.

Steps to Build and Generate Files

Clean the Project
Remove any cached build artifacts to ensure a fresh build environment.
flutter clean


Fetch Dependencies
Install all dependencies listed in pubspec.yaml.
flutter pub get


Generate Hive Adapters
Generate the task.g.dart file (and other Hive adapters) using the build_runner package. The --delete-conflicting-outputs flag ensures any conflicting generated files are overwritten.
flutter packages pub run build_runner build --delete-conflicting-outputs


Optional: Watch for Changes (Development)
For continuous generation during development, use the watch command to automatically regenerate files when changes are detected in the source code.
flutter packages pub run build_runner watch --delete-conflicting-outputs



Troubleshooting

Error: "part 'task.g.dart' not found"

Ensure the part 'task.g.dart'; directive is included in lib/models/task.dart.
Verify that hive_generator and build_runner are listed in dev_dependencies in pubspec.yaml.
Rerun flutter pub get followed by the build command.


Error: Dependency conflicts

Check pubspec.yaml for correct dependency versions (e.g., hive: ^2.2.3, hive_flutter: ^1.1.0).
Run flutter pub get again to resolve dependencies.


Error: Hive type ID conflict

Ensure the typeId in Task (@HiveType(typeId: 0)) and TimeOfDayAdapter (typeId: 1) are unique.
If adding new Hive types, assign unique typeId values.


Error: Build fails due to conflicts

Delete any existing *.g.dart files (e.g., lib/models/task.g.dart) and rerun the build command with --delete-conflicting-outputs.



Additional Notes

File Locations: Ensure task.dart and task.g.dart are in the same directory (e.g., lib/models/).
App Icon: For flutter_local_notifications, place an app icon named app_icon in android/app/src/main/res/drawable/.
Permissions: Verify Android and iOS permissions for notifications and image picker are configured in AndroidManifest.xml and Info.plist, respectively.
Testing: After generating files, run the app (flutter run) to ensure all features (e.g., task management, notifications, theme switching) work as expected.

If you encounter specific errors, capture the error message and consult the relevant documentation or seek assistance.