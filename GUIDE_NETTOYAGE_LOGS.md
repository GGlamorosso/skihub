# 🧹 Guide de nettoyage des logs - Messages non bloquants

## 📊 Analyse des messages dans les logs

### ✅ Messages NON BLOQUANTS (peuvent être ignorés pour l'instant)

#### 1. 🔔 APNS Token (Firebase Messaging)
```
APNS token has not been set yet. Please ensure the APNS token is available by calling getAPNSToken().
```

**Explication** :
- Firebase essaie de récupérer le token APNs (Apple Push Notification service) avant qu'il soit disponible
- C'est normal en développement iOS
- L'app fonctionne quand même

**Action** : 
- ✅ **Laisser comme ça pour l'instant**
- 📝 À configurer plus tard quand vous ferez la config push iOS complète (certificats, capabilities, etc.)

---

#### 2. 🎨 AssetManifest.json (google_fonts)
```
Unable to load asset: "AssetManifest.json".
google_fonts was unable to load font Poppins-...
```

**Explication** :
- `google_fonts` essaie de lire la liste des assets générée par Flutter
- L'asset `AssetManifest.json` n'est pas trouvé ou vide
- Souvent dû à des builds précédents incomplets

**Solution rapide** :
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

**Si le message persiste mais que l'app fonctionne** :
- ✅ Considérer comme non bloquant
- Les polices se chargent quand même (fallback système)

---

#### 3. 📏 RenderFlex Overflow (UI Layout)
```
A RenderFlex overflowed by 5.6 pixels on the right.
file: lib/components/buttons.dart:62:15
```

**Explication** :
- Un `Row` a trop de contenu pour la largeur disponible
- Flutter signale le débordement (warning visuel)
- L'app fonctionne quand même

**Solution** : Voir section "Corrections UI" ci-dessous

---

### ⚠️ Messages à VÉRIFIER (mais pas critiques)

#### 4. 📊 Match-candidates retourne 0 candidats
```
Match-candidates returned 0 candidates
candidates: [], total_found: 0
```

**Explication** :
- La fonction fonctionne ✅
- Pas d'erreur serveur ✅
- Mais aucun candidat trouvé

**Raisons possibles** :
1. Vous êtes le seul utilisateur dans votre station/dates
2. Les autres utilisateurs n'ont pas de station/dates actives compatibles
3. Tous les utilisateurs ont déjà été likés/matchés

**Solution** : Voir section "Créer des utilisateurs de test" ci-dessous

---

## 🔧 Corrections rapides

### Correction 1 : RenderFlex Overflow dans buttons.dart

**Fichier** : `frontend/lib/components/buttons.dart` (ligne ~62)

**Problème** : Le `Row` avec `Icon` + `Text` peut dépasser sur petits écrans

**Solution** : Utiliser `Flexible` ou réduire le padding

```dart
// AVANT (ligne 62)
: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, color: AppColors.textOnPink, size: 20),
        const SizedBox(width: 8),
      ],
      Text(
        text,
        style: AppTypography.buttonPrimary,
      ),
    ],
  )

// APRÈS (corrigé)
: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, color: AppColors.textOnPink, size: 18), // ✅ Réduire taille
        const SizedBox(width: 6), // ✅ Réduire espacement
      ],
      Flexible( // ✅ Permet au texte de se réduire si nécessaire
        child: Text(
          text,
          style: AppTypography.buttonPrimary,
          overflow: TextOverflow.ellipsis, // ✅ Tronquer si trop long
          maxLines: 1,
        ),
      ),
    ],
  )
```

---

### Correction 2 : Nettoyer les assets Flutter

```bash
cd /Users/user/Desktop/SKIAPP/crewsnow/frontend
flutter clean
flutter pub get
flutter run
```

Cela devrait résoudre les erreurs `AssetManifest.json`.

---

## 🧪 Créer des utilisateurs de test pour le matching

### Option 1 : Via l'app (recommandé)

1. Créer un 2ᵉ compte avec un autre email
2. Compléter l'onboarding avec :
   - **Même station** que votre compte principal
   - **Dates qui se chevauchent** (ex: si vous êtes du 20-27 déc, mettre 22-29 déc)
   - **Rayon de recherche** suffisant (50+ km)
   - **Niveau compatible** (beginner/intermediate/advanced)
   - **Styles de ski** qui se chevauchent

### Option 2 : Via SQL (rapide pour tests)

Exécuter dans **Supabase Dashboard → SQL Editor** :

```sql
-- 1. Créer un utilisateur de test dans auth.users (via Dashboard → Authentication → Users)
-- Notez l'UUID créé

-- 2. Créer le profil dans public.users (remplacer USER_UUID par l'UUID créé)
INSERT INTO public.users (
    id,
    username,
    email,
    level,
    ride_styles,
    languages,
    objectives,
    bio,
    birth_date,
    is_active,
    last_active_at
) VALUES (
    'USER_UUID', -- UUID de l'utilisateur créé dans auth.users
    'TestUser',
    'test@example.com',
    'intermediate',
    ARRAY['freestyle', 'park']::ride_style[],
    ARRAY['fr', 'en']::language_code[],
    ARRAY['fun', 'friends']::TEXT[],
    'Profil de test pour matching',
    '1995-01-15'::DATE,
    true,
    NOW()
);

-- 3. Créer une station active (remplacer USER_UUID et STATION_ID)
-- STATION_ID = ID d'une station existante (voir: SELECT id, name FROM stations LIMIT 5;)
INSERT INTO user_station_status (
    user_id,
    station_id,
    date_from,
    date_to,
    radius_km,
    is_active
) VALUES (
    'USER_UUID',
    'STATION_ID', -- ID d'une station existante
    '2025-12-22'::DATE, -- Dates qui se chevauchent avec votre séjour
    '2025-12-29'::DATE,
    50, -- Rayon de recherche
    true
);
```

---

## 📋 Checklist de nettoyage

### Actions immédiates (5 minutes)

- [ ] Exécuter `flutter clean && flutter pub get` dans `frontend/`
- [ ] Corriger le `RenderFlex overflow` dans `buttons.dart` (optionnel)
- [ ] Vérifier que les fonctions SQL sont bien créées (exécuter `verify_all_functions.sql`)

### Actions à faire plus tard (non urgentes)

- [ ] Configurer APNs pour les notifications push iOS
- [ ] Créer des utilisateurs de test pour tester le matching
- [ ] Nettoyer tous les `RenderFlex overflow` dans l'UI (si nécessaire)

---

## ✅ Résultat attendu

Après ces corrections :
- ✅ Moins de messages d'erreur dans les logs
- ✅ L'app fonctionne sans warnings visuels
- ✅ Les polices se chargent correctement
- ✅ Le matching fonctionne si vous avez des utilisateurs de test

---

## 🎯 Priorités

1. **CRITIQUE** : Exécuter `20250118_fix_all_critical_errors.sql` (si pas encore fait)
2. **IMPORTANT** : `flutter clean && flutter pub get` pour nettoyer les assets
3. **OPTIONNEL** : Corriger le `RenderFlex overflow` (cosmétique)
4. **OPTIONNEL** : Créer des utilisateurs de test pour tester le matching

Les messages APNS et AssetManifest peuvent être ignorés pour l'instant si l'app fonctionne correctement.

