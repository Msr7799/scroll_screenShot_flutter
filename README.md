# Flutter Scrolling Screenshot App - Linux

## هيكل المشروع (Project Structure)
```
scroll_screenshot_app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── screenshot_config.dart
│   │   └── scroll_detection.dart
│   ├── services/
│   │   ├── screenshot_service.dart
│   │   ├── scroll_detector.dart
│   │   └── file_manager.dart
│   ├── ui/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   └── preview_screen.dart
│   │   ├── widgets/
│   │   │   ├── area_selector.dart
│   │   │   ├── control_panel.dart
│   │   │   └── progress_indicator.dart
│   │   └── dialogs/
│   │       ├── settings_dialog.dart
│   │       └── export_dialog.dart
│   └── utils/
│       ├── constants.dart
│       └── helpers.dart
├── assets/
│   └── icons/
├── test/
└── pubspec.yaml
```