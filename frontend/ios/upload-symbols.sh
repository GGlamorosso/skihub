#!/bin/bash

# Script pour uploader les dSYM vers Firebase Crashlytics
# Ce script doit être ajouté comme "Run Script" dans Xcode Build Phases

# Chemin vers le script upload-symbols de Firebase
FIREBASE_SYMBOLS_SCRIPT="${PODS_ROOT}/FirebaseCrashlytics/upload-symbols"

# Chemin vers GoogleService-Info.plist
GOOGLE_SERVICE_INFO="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

# Chemin vers le dSYM
DSYM_PATH="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"

# Vérifier que le script existe
if [ ! -f "$FIREBASE_SYMBOLS_SCRIPT" ]; then
  echo "⚠️ Firebase Crashlytics upload-symbols script not found"
  exit 0
fi

# Vérifier que GoogleService-Info.plist existe
if [ ! -f "$GOOGLE_SERVICE_INFO" ]; then
  echo "⚠️ GoogleService-Info.plist not found"
  exit 0
fi

# Vérifier que le dSYM existe
if [ ! -d "$DSYM_PATH" ]; then
  echo "⚠️ dSYM not found at $DSYM_PATH"
  exit 0
fi

# Uploader le dSYM
"${FIREBASE_SYMBOLS_SCRIPT}" -gsp "${GOOGLE_SERVICE_INFO}" -p ios "${DSYM_PATH}"

echo "✅ dSYM uploaded to Firebase Crashlytics"

