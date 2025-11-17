# 🚀 Déploiement Bêta CrewSnow - Guide Complet

**Temps total estimé** : 45 minutes  
**Dernière mise à jour** : 2025-01-17

---

## 📋 Vue d'ensemble

Ce guide vous accompagne pour préparer complètement votre app CrewSnow pour la bêta. Toutes les migrations et corrections ont été préparées automatiquement.

---

## ÉTAPE 1 : Base de Données (15 minutes)

### 1.1 Exécuter le Setup Complet

1. Allez sur **[Supabase Dashboard](https://app.supabase.com)** > Votre projet
2. Cliquez sur **SQL Editor**
3. Copiez tout le contenu de : `backend/supabase/seed/complete_beta_setup.sql`
4. Collez dans l'éditeur SQL
5. Cliquez sur **Run**
6. Attendez 2-3 minutes (le script affiche des messages de progression)

**Résultat attendu** :
```
NOTICE: Vue public_profiles_v créée: ✅
NOTICE: Colonne objectives créée: ✅  
NOTICE: Type ride_style créé: ✅
NOTICE: Type language_code créé: ✅
NOTICE: Colonne stations.is_active créée: ✅
NOTICE: Stations créées: 21 stations actives
NOTICE: 🎉 SETUP BÊTA TERMINÉ AVEC SUCCÈS !
```

### 1.2 Créer Votre Profil Utilisateur

1. Dans **Supabase Dashboard > Authentication > Users**
2. Trouvez votre compte utilisateur
3. **Copiez votre UUID** (ex: `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11`)
4. Dans **SQL Editor**, exécutez (remplacez `VOTRE_UUID`) :

```sql
UPDATE public.users 
SET 
  username = 'mon_username', -- Choisissez votre username
  onboarding_completed = true,
  is_active = true,
  level = 'intermediate',
  ride_styles = ARRAY['alpine', 'snowboard']::ride_style[],
  languages = ARRAY['fr', 'en']::language_code[],
  objectives = ARRAY['rencontrer des gens', 'améliorer ma technique', 'découvrir de nouveaux spots'],
  bio = 'Passionné de ski, toujours partant pour de nouvelles aventures sur les pistes !',
  birth_date = '1990-01-01', -- Votre date de naissance
  last_active_at = NOW(),
  updated_at = NOW()
WHERE id = 'VOTRE_UUID';
```

### 1.3 Créer des Utilisateurs de Test

1. Dans **Authentication > Users**, créez 3-4 comptes de test avec des emails différents
2. Notez leurs UUIDs
3. Ouvrez le fichier : `backend/supabase/seed/create_test_users.sql`
4. Remplacez `REMPLACER_PAR_UUID_1`, `REMPLACER_PAR_UUID_2`, etc. par les vrais UUIDs
5. Copiez tout le fichier et exécutez-le dans **SQL Editor**

**Résultat attendu** :
```
NOTICE: Utilisateur de test 1 créé : freeride_expert
NOTICE: Utilisateur de test 2 créé : ski_newbie  
NOTICE: Utilisateur de test 3 créé : snowboard_pro
NOTICE: Utilisateur de test 4 créé : alpine_lover
NOTICE: ✅ Utilisateurs actifs créés : 5
NOTICE: 🎉 UTILISATEURS DE TEST CRÉÉS AVEC SUCCÈS !
```

---

## ÉTAPE 2 : Edge Functions (5 minutes)

### 2.1 Vérifier les Fonctions Déployées

Dans **Supabase Dashboard > Edge Functions**, vérifiez que vous avez :
- ✅ `match-candidates`
- ✅ `gatekeeper`  
- ✅ `manage-consent`

### 2.2 Redéployer match-candidates (IMPORTANT)

1. Cliquez sur **match-candidates**
2. Cliquez sur **Edit Function**
3. Remplacez TOUT le code par le contenu de : `backend/supabase/functions/match-candidates/index.ts`
4. Cliquez sur **Deploy**

**⚠️ Cette étape est critique** : La fonction a été corrigée pour utiliser la nouvelle vue `public_profiles_v`.

### 2.3 Tester les Fonctions

Dans **match-candidates > Invoke**, testez avec :

```json
{
  "limit": 10
}
```

**Résultat attendu** : 
```json
{
  "candidates": [
    {
      "id": "...",
      "username": "freeride_expert",
      "level": "expert",
      "ride_styles": ["freeride", "powder", "touring"],
      "objectives": ["explorer de nouveaux terrains", "..."],
      "age": 38,
      "current_station": "Chamonix-Mont-Blanc"
    }
  ],
  "nextCursor": null
}
```

---

## ÉTAPE 3 : Application Flutter (15 minutes)

### 3.1 Vérifier la Configuration

1. Dans `frontend/lib/config/env_config.dart`, vérifiez que les URLs Supabase sont correctes :
   ```dart
   static String get supabaseUrl {
     const devUrl = 'https://qzpinzxiqupetortbczh.supabase.co'; // ✅ Votre URL
   }
   ```

2. Vérifiez que les clés correspondent à votre projet Supabase

### 3.2 Rebuild Complet

```bash
cd frontend

# Nettoyage complet
flutter clean
rm -rf build/
rm -rf .dart_tool/

# Réinstallation
flutter pub get
flutter pub deps

# Build iOS pour Xcode
flutter build ios --release
```

### 3.3 Vérifier Xcode

1. Ouvrez `frontend/ios/Runner.xcworkspace` dans Xcode
2. Sélectionnez **Runner** > **Signing & Capabilities**
3. Configurez votre **Team** et **Bundle Identifier**
4. Vérifiez qu'il n'y a pas d'erreurs de compilation

---

## ÉTAPE 4 : Vérifications Finales (10 minutes)

### 4.1 Test de l'App en Développement

```bash
cd frontend
flutter run --release
```

**Vérifications** :
- [ ] App démarre sans crash
- [ ] Écran de login s'affiche
- [ ] Connexion avec votre compte fonctionne
- [ ] Profil se charge correctement
- [ ] Feed affiche les utilisateurs de test
- [ ] Swipe fonctionne sans erreur
- [ ] Pas d'erreurs dans les logs

### 4.2 Vérifier les Logs

Cherchez ces messages dans la console :
```
✅ User signed in: votre-email@exemple.com
✅ Supabase initialized successfully  
📍 GPS position sent: 45.5, 6.0
✅ Function called: match-candidates
✅ Profile loaded: votre-username
```

**❌ Erreurs à éviter** :
```
❌ column users.objectives does not exist
❌ relation public_profiles_v does not exist  
❌ type ride_style does not exist
❌ Function call failed: match-candidates
```

### 4.3 Test du Feed

1. Connectez-vous avec votre compte principal
2. Allez dans l'onglet Feed
3. Vous devriez voir les profils de test :
   - `freeride_expert` (Expert, Chamonix)
   - `ski_newbie` (Débutant, Courchevel)
   - `snowboard_pro` (Confirmé, Val d'Isère)
   - `alpine_lover` (Intermédiaire, Tignes)

4. Testez le swipe sur quelques profils
5. Vérifiez que les détails s'affichent correctement

---

## ÉTAPE 5 : Archive Xcode pour TestFlight (10 minutes)

### 5.1 Configuration Xcode

1. Ouvrez `frontend/ios/Runner.xcworkspace`
2. Sélectionnez **Any iOS Device** dans le simulateur
3. **Product > Scheme > Edit Scheme**
4. Build Configuration : **Release**
5. **Product > Archive**

### 5.2 Upload vers App Store Connect

1. Après l'archive, cliquez sur **Distribute App**
2. Sélectionnez **App Store Connect**
3. Suivez les étapes pour upload
4. Attendez le traitement (15-30 minutes)

### 5.3 Configurer TestFlight

1. Allez sur **[App Store Connect](https://appstoreconnect.apple.com)**
2. Sélectionnez votre app
3. **TestFlight > Builds**
4. Sélectionnez le build uploadé
5. Ajoutez des testeurs internes/externes
6. Activez les tests

---

## ✅ Checklist Finale Bêta

### Base de Données
- [ ] Vue `public_profiles_v` créée et fonctionnelle
- [ ] Colonnes `objectives` ajoutée à `users`
- [ ] Types ENUM `ride_style` et `language_code` créés
- [ ] Colonne `is_active` ajoutée à `stations`
- [ ] 21+ stations créées et actives
- [ ] 5+ utilisateurs de test avec profils complets
- [ ] Votre profil principal configuré

### Edge Functions
- [ ] `match-candidates` déployée et testée
- [ ] `gatekeeper` déployée et testée  
- [ ] `manage-consent` déployée et testée
- [ ] Test API retourne des candidats

### Application Flutter
- [ ] Configuration Supabase correcte
- [ ] Build iOS réussie sans erreurs
- [ ] Tests en développement passés
- [ ] Feed affiche les utilisateurs
- [ ] Swipe fonctionne
- [ ] Profil se charge

### Déploiement
- [ ] Archive Xcode réussie
- [ ] Upload App Store Connect terminé
- [ ] TestFlight configuré
- [ ] Testeurs ajoutés
- [ ] Tests bêta activés

---

## 🚨 Résolution de Problèmes

### Erreur : "Build failed in Xcode"
1. Vérifiez que Flutter est à jour : `flutter upgrade`
2. Nettoyez : `flutter clean && flutter pub get`
3. Vérifiez les certificats de développement dans Xcode

### Erreur : "Function not found"
1. Vérifiez que les 3 Edge Functions sont déployées
2. Redéployez `match-candidates` avec le code corrigé
3. Testez l'API directement

### Erreur : "Profile not loading"
1. Vérifiez que votre UUID est correct dans la base
2. Vérifiez que `onboarding_completed = true`
3. Vérifiez les logs Supabase pour les erreurs RLS

### Feed vide
1. Vérifiez que vous avez créé des utilisateurs de test
2. Vérifiez que leurs profils sont `is_active = true`
3. Vérifiez les filtres de matching

---

## 📊 Résumé des Modifications Appliquées

### Fichiers SQL créés/modifiés :
- ✅ `backend/supabase/seed/complete_beta_setup.sql`
- ✅ `backend/supabase/seed/create_test_users.sql`
- ✅ `backend/supabase/migrations/20250117_add_objectives_column.sql`
- ✅ `backend/supabase/migrations/20250117_create_enums_and_convert.sql`
- ✅ `backend/supabase/migrations/20250117_add_stations_is_active.sql`
- ✅ `backend/supabase/migrations/20250117_create_public_profiles_view.sql`

### Fichiers Flutter modifiés :
- ✅ `backend/supabase/functions/match-candidates/index.ts` (corrigé pour utiliser `public_profiles_v`)

### Tables/Vues créées :
- ✅ Vue `public_profiles_v`
- ✅ Types ENUM `ride_style` et `language_code`
- ✅ 21 stations de ski européennes
- ✅ Structure pour utilisateurs de test

---

## 🎯 Prochaines Étapes Post-Bêta

1. **Collecter les retours** des testeurs bêta
2. **Analyser les metrics** d'usage
3. **Corriger les bugs** remontés
4. **Optimiser les performances** si nécessaire
5. **Ajouter les fonctionnalités** manquantes
6. **Préparer le lancement** public

---

**🚀 Votre app CrewSnow est maintenant prête pour la bêta !**

*Temps de setup total : 45 minutes*  
*Prochaine étape : Tests utilisateurs et itérations*
