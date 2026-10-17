#!/usr/bin/env bash
# Run once from this folder:  bash setup.sh
set -e
command -v flutter >/dev/null || { echo "Install Flutter 3.24+ first: https://docs.flutter.dev/get-started/install"; exit 1; }
tmp=$(mktemp -d)
flutter create --project-name kalpana --org com.kalpana --platforms=android,ios "$tmp/kalpana" >/dev/null
cp -r "$tmp/kalpana/android" "$tmp/kalpana/ios" .
cp -n "$tmp/kalpana/analysis_options.yaml" "$tmp/kalpana/.gitignore" "$tmp/kalpana/.metadata" . 2>/dev/null || true
flutter pub get
python3 tools/patch_platforms.py
dart run flutter_launcher_icons || true
echo "Done. Connect an Android phone and run:  flutter run"
