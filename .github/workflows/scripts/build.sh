#!/bin/bash

flutter pub get
flutter pub run flutter_launcher_icons:main
flutter gen-l10n l10n.yaml
flutter pub run build_runner build --delete-conflicting-outputs
