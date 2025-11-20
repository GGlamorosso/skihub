# 🔧 Correction : Profil non créé après onboarding

## ❌ Problème identifié

L'erreur `No profile found for user` apparaissait car le profil n'était pas complètement créé après l'onboarding.

## ✅ Corrections appliquées

### 1. Email manquant dans l'upsert
**Problème** : L'email est requis (`NOT NULL UNIQUE`) dans la table `users` mais n'était pas inclus dans l'upsert.

**Correction** : Ajout de la récupération de l'email depuis `auth.users` et inclusion dans l'upsert.

### 2. Objectives non sauvegardés
**Problème** : Les `objectives` étaient collectés dans l'onboarding mais pas sauvegardés dans la base.

**Correction** : Ajout de `'objectives': state.objectives.toList()` dans l'upsert.

### 3. file_size_bytes manquant pour la photo
**Problème** : La colonne `file_size_bytes` est `NOT NULL` mais n'était pas fournie lors de l'insertion de la photo.

**Correction** : Calcul de la taille du fichier et ajout dans l'insert.

### 4. Chemin de stockage incorrect
**Problème** : Le chemin utilisait `profile_photos/$userId/$fileName` au lieu de `$userId/$fileName`.

**Correction** : Utilisation du format correct `userId/filename` pour respecter la RLS policy.

## 📝 Fichier modifié

- `frontend/lib/features/onboarding/controllers/onboarding_controller.dart`

## 🔍 Changements détaillés

### Avant (ligne 196-208)
```dart
await _supabase.from('users').upsert({
  'id': userId,
  'username': _generateUsernameFromName(),
  // ❌ Email manquant
  // ❌ objectives manquant
  ...
}, onConflict: 'id');
```

### Après
```dart
// ✅ Récupérer l'email
final currentUser = _supabase.currentUser;
if (currentUser == null || currentUser.email == null) {
  throw Exception('Utilisateur non authentifié ou email manquant');
}

await _supabase.from('users').upsert({
  'id': userId,
  'email': currentUser.email!, // ✅ Ajouté
  'username': _generateUsernameFromName(),
  'objectives': state.objectives.toList(), // ✅ Ajouté
  ...
}, onConflict: 'id');
```

### Photo - Avant
```dart
final path = 'profile_photos/$userId/$fileName'; // ❌ Format incorrect
await _supabase.uploadFile(...);
```

### Photo - Après
```dart
final storagePath = '$userId/$fileName'; // ✅ Format correct
await _supabase.storage
    .from('profile_photos')
    .uploadBinary(storagePath, bytes, ...);
```

## ✅ Résultat attendu

Après ces corrections :
1. ✅ Le profil est créé avec tous les champs requis (email, objectives, etc.)
2. ✅ La photo est uploadée avec le bon chemin et `file_size_bytes`
3. ✅ La station est créée correctement
4. ✅ L'onboarding est marqué comme complet
5. ✅ L'utilisateur peut accéder au feed

## 🧪 Test

1. Créer un nouveau compte
2. Compléter l'onboarding (nom, âge, photo, niveau, styles, langues, objectifs, station, dates)
3. Vérifier que le profil est créé dans `public.users`
4. Vérifier que la photo est dans `profile_photos`
5. Vérifier que la station est dans `user_station_status`
6. Vérifier que `onboarding_completed = true`

