#!/usr/bin/env bash
set -e
echo "==> CHECK"
cd apps/mobile
flutter pub get
flutter analyze
echo "OK"
