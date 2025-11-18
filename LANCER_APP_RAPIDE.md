# ⚡ Lancer l'app Flutter rapidement

## 🚀 Méthode la plus simple

### Option 1 : Script automatique (recommandé)

```bash
./scripts/launch-flutter-app.sh
```

Le script va :
1. Vous demander de choisir iOS ou Android
2. Lancer l'émulateur automatiquement
3. Lancer l'application

---

### Option 2 : Commandes manuelles

#### Pour iOS Simulator :

```bash
# 1. Lancer l'émulateur iOS
flutter emulators --launch apple_ios_simulator

# 2. Attendre 5 secondes que le Simulator démarre

# 3. Lancer l'app
cd frontend
flutter run
```

#### Pour Android Emulator :

```bash
# 1. Lancer l'émulateur Android
flutter emulators --launch Medium_Phone_API_36.1

# 2. Attendre 10 secondes que l'émulateur démarre

# 3. Lancer l'app
cd frontend
flutter run
```

#### Pour un appareil physique connecté :

```bash
cd frontend
flutter run
```

---

## 📱 Émulateurs disponibles sur votre système

- ✅ **iOS Simulator** (`apple_ios_simulator`)
- ✅ **Android Emulator** (`Medium_Phone_API_36.1`)

---

## 🔥 Commandes utiles pendant le développement

Une fois l'app lancée :
- `r` = Hot reload (rechargement rapide)
- `R` = Hot restart (redémarrage complet)
- `q` = Quitter l'application

---

## 🐛 Si ça ne fonctionne pas

```bash
# Nettoyer et réinstaller les dépendances
cd frontend
flutter clean
flutter pub get

# Relancer
flutter run
```

---

## 💡 Astuce

Pour lancer directement sans choisir :

```bash
# iOS
cd frontend && flutter emulators --launch apple_ios_simulator && sleep 5 && flutter run

# Android
cd frontend && flutter emulators --launch Medium_Phone_API_36.1 && sleep 10 && flutter run
```

