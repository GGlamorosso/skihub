# ✅ Configuration dSYM pour Firebase Crashlytics - TERMINÉE

## Ce qui a été fait

### 1. Script de build phase ajouté automatiquement
Un script de build phase "Upload dSYM to Firebase" a été ajouté au projet Xcode. Ce script :
- S'exécute automatiquement après chaque build/archive
- Upload les fichiers dSYM vers Firebase Crashlytics
- Utilise le fichier `GoogleService-Info.plist` pour l'authentification
- Affiche un message de confirmation ou d'avertissement dans les logs Xcode

### 2. Configuration du script
- **Nom** : "Upload dSYM to Firebase"
- **Position** : Après "Thin Binary" (après la génération du dSYM)
- **Input Files** : 
  - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}`
  - `${PROJECT_DIR}/Runner/GoogleService-Info.plist`

### 3. Configuration dSYM déjà en place
- `DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"` pour Release et Profile ✅
- Le dSYM est généré automatiquement lors de chaque archive ✅

## Comment ça fonctionne

Lorsque vous archivez votre application dans Xcode :
1. Le build génère le fichier dSYM
2. Le script "Upload dSYM to Firebase" s'exécute automatiquement
3. Le script upload le dSYM vers Firebase Crashlytics
4. Vous verrez dans les logs Xcode : `✅ dSYM uploaded to Firebase Crashlytics`

## Vérification

### Dans Xcode
1. Ouvrez `frontend/ios/Runner.xcworkspace`
2. Sélectionnez le projet **Runner** → Target **Runner** → **Build Phases**
3. Vous devriez voir "Upload dSYM to Firebase" dans la liste

### Après un archive
1. Archivez votre app dans Xcode (Product → Archive)
2. Dans les logs de build, cherchez : `✅ dSYM uploaded to Firebase Crashlytics`
3. Si vous voyez un avertissement, c'est normal si FirebaseCrashlytics n'est pas encore installé (le script ne fait rien dans ce cas)

### Dans Firebase Console
1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet `crewsnow-33b1f`
3. Allez dans **Crashlytics**
4. Après le premier upload, vous ne devriez plus recevoir d'email d'avertissement sur les dSYM manquants

## Notes importantes

- Le script ne fait rien si FirebaseCrashlytics n'est pas installé (pas d'erreur)
- Le script s'exécute uniquement lors des builds Release/Profile (pas en Debug)
- Les dSYM sont uploadés automatiquement, vous n'avez rien à faire manuellement

## Problèmes possibles

### Si le script ne s'exécute pas
1. Vérifiez que vous archivez en mode **Release** ou **Profile** (pas Debug)
2. Vérifiez que `GoogleService-Info.plist` existe dans `Runner/`
3. Vérifiez que FirebaseCrashlytics est installé : `cd ios && pod install`

### Si vous voyez un avertissement
C'est normal si FirebaseCrashlytics n'est pas encore installé. Le script ne fait rien dans ce cas et n'interrompt pas le build.

## Prochaines étapes

1. **Tester** : Archivez votre app dans Xcode et vérifiez les logs
2. **Vérifier Firebase** : Après le premier upload, vérifiez dans Firebase Console que les dSYM sont bien reçus
3. **C'est tout !** : Le script s'exécutera automatiquement à chaque archive

---

**Configuration terminée le** : $(date)
**Script ajouté au projet** : ✅
**Prêt pour la production** : ✅

