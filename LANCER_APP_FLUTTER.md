# 🚀 Guide : Lancer l'émulateur et l'application Flutter

## 📱 Option 1 : iOS Simulator (Mac uniquement)

### Étape 1 : Ouvrir le Simulator iOS

```bash
# Ouvrir le Simulator depuis le terminal
open -a Simulator
```

**OU** depuis Xcode :
- Ouvrir Xcode
- Menu : `Xcode > Open Developer Tool > Simulator`

### Étape 2 : Choisir un appareil iOS

Dans le Simulator :
- Menu : `File > Open Simulator > iOS [version] > iPhone [modèle]`
- Exemple : `iPhone 15 Pro`, `iPhone 14`, etc.

### Étape 3 : Lancer l'application Flutter

```bash
# Aller dans le dossier frontend
cd frontend

# Vérifier que l'émulateur est détecté
flutter devices

# Lancer l'application
flutter run
```

---

## 🤖 Option 2 : Android Emulator

### Étape 1 : Vérifier que l'émulateur Android est installé

```bash
# Vérifier les émulateurs disponibles
flutter emulators
```

### Étape 2 : Créer un émulateur (si nécessaire)

```bash
# Ouvrir Android Studio
# Menu : Tools > Device Manager
# Cliquer sur "Create Device"
# Choisir un appareil (ex: Pixel 5)
# Choisir une version Android (ex: API 33)
# Cliquer sur "Finish"
```

### Étape 3 : Lancer l'émulateur Android

```bash
# Lancer un émulateur spécifique
flutter emulators --launch <emulator_id>

# OU depuis Android Studio
# Menu : Tools > Device Manager > Cliquer sur "Play" à côté d'un appareil
```

### Étape 4 : Lancer l'application Flutter

```bash
# Aller dans le dossier frontend
cd frontend

# Vérifier que l'émulateur est détecté
flutter devices

# Lancer l'application
flutter run
```

---

## 📱 Option 3 : Appareil physique (iPhone/Android)

### iPhone (câble USB)

```bash
# Connecter l'iPhone avec un câble USB
# Déverrouiller l'iPhone et accepter "Faire confiance à cet ordinateur"

# Aller dans le dossier frontend
cd frontend

# Vérifier que l'iPhone est détecté
flutter devices

# Lancer l'application
flutter run
```

### Android (câble USB ou WiFi)

```bash
# Activer le mode développeur sur l'Android
# Paramètres > À propos du téléphone > Appuyer 7 fois sur "Numéro de build"
# Activer "Débogage USB" dans Options développeur

# Connecter l'Android avec un câble USB
# OU activer le débogage WiFi dans Android Studio

# Aller dans le dossier frontend
cd frontend

# Vérifier que l'Android est détecté
flutter devices

# Lancer l'application
flutter run
```

---

## ⚡ Commandes rapides

### Voir les appareils disponibles

```bash
cd frontend
flutter devices
```

### Lancer l'app sur un appareil spécifique

```bash
cd frontend
flutter run -d <device_id>
```

### Lancer en mode release (plus rapide, mais pas de hot reload)

```bash
cd frontend
flutter run --release
```

### Lancer avec des logs détaillés

```bash
cd frontend
flutter run -v
```

---

## 🔥 Hot Reload (pendant le développement)

Une fois l'application lancée :
- Appuyer sur `r` dans le terminal pour **hot reload** (rechargement rapide)
- Appuyer sur `R` pour **hot restart** (redémarrage complet)
- Appuyer sur `q` pour **quitter** l'application

---

## 🐛 Dépannage

### Problème : "No devices found"

```bash
# Vérifier que Flutter détecte les appareils
flutter devices

# Si iOS Simulator ne s'affiche pas :
open -a Simulator

# Si Android Emulator ne s'affiche pas :
flutter emulators --launch <emulator_id>
```

### Problème : "Unable to locate Android SDK"

```bash
# Configurer le chemin Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### Problème : Erreurs de dépendances

```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

### Problème : Erreurs de build iOS

```bash
cd frontend/ios
pod install
cd ..
flutter run
```

---

## 📋 Checklist avant de lancer

- [ ] Flutter est installé (`flutter --version`)
- [ ] Les dépendances sont installées (`flutter pub get`)
- [ ] Un émulateur/appareil est disponible (`flutter devices`)
- [ ] Les variables d'environnement sont configurées (Supabase keys, etc.)

---

## 🎯 Commandes complètes (copier-coller)

### iOS Simulator

```bash
# Ouvrir le Simulator
open -a Simulator

# Attendre quelques secondes que le Simulator démarre

# Lancer l'app
cd frontend
flutter run
```

### Android Emulator

```bash
# Lancer l'émulateur (remplacer <emulator_id> par l'ID de votre émulateur)
flutter emulators --launch <emulator_id>

# OU depuis Android Studio : Tools > Device Manager > Play

# Lancer l'app
cd frontend
flutter run
```

---

## 💡 Astuce

Pour lancer automatiquement l'émulateur et l'app en une seule commande :

```bash
cd frontend
flutter run
```

Flutter va automatiquement :
1. Détecter un émulateur disponible
2. Le lancer s'il n'est pas déjà ouvert
3. Installer l'app
4. La lancer

---

## ✅ Résultat attendu

Une fois lancé, vous devriez voir :
- L'émulateur/appareil s'ouvrir
- L'application CrewSnow se lancer
- Les logs Flutter dans le terminal
- La possibilité de faire du hot reload avec `r`

