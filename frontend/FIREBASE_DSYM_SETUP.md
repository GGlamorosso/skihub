# Configuration dSYM pour Firebase Crashlytics iOS

## Problème
Firebase Crashlytics nécessite les fichiers dSYM pour symboliser les crash reports. Sans ces fichiers, les rapports de crash ne montrent que des adresses mémoire au lieu de noms de fonctions.

## Solution : Ajouter un script de build dans Xcode

### Étape 1 : Ouvrir le projet dans Xcode
```bash
cd frontend/ios
open Runner.xcworkspace
```

### Étape 2 : Ajouter le script de build
1. Dans Xcode, sélectionnez le projet **Runner** dans le navigateur de gauche
2. Sélectionnez la cible **Runner**
3. Allez dans l'onglet **Build Phases**
4. Cliquez sur le bouton **+** en haut à gauche
5. Sélectionnez **New Run Script Phase**
6. Renommez le script en "Upload dSYM to Firebase"

### Étape 3 : Configurer le script
Collez ce script dans la zone de texte :

```bash
"${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" -gsp "${PROJECT_DIR}/Runner/GoogleService-Info.plist" -p ios "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
```

### Étape 4 : Positionner le script
1. **Important** : Faites glisser le script **APRÈS** la phase "Run Script" (celle qui contient `xcode_backend.sh build`)
2. Le script doit s'exécuter **après** la génération du dSYM

### Étape 5 : Configurer les Input Files (optionnel mais recommandé)
Dans la section "Input Files" du script, ajoutez :
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
${PROJECT_DIR}/Runner/GoogleService-Info.plist
```

### Étape 6 : Vérifier la configuration
1. Assurez-vous que `DEBUG_INFORMATION_FORMAT` est défini sur `"dwarf-with-dsym"` pour les configurations **Release** et **Profile**
2. C'est déjà configuré dans votre projet ✅

## Vérification

Après avoir archivé et uploadé votre build :
1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet `crewsnow-33b1f`
3. Allez dans **Crashlytics**
4. Vérifiez que les dSYM sont bien uploadés (vous ne devriez plus recevoir d'email d'avertissement)

## Note
Le script s'exécute automatiquement lors de chaque archive. Vous n'avez rien à faire manuellement après la configuration initiale.

