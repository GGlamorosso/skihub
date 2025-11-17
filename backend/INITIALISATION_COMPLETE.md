# 🗄️ Initialisation Complète de la Base de Données

## 📋 Ce que cette migration fait

Cette migration SQL complète (`20250117_complete_schema.sql`) crée **TOUTES** les tables, index, fonctions et RLS policies selon le plan DEV 2.

## ✅ Tables créées/vérifiées

1. **users** - Profils utilisateurs (colonnes manquantes ajoutées)
2. **likes** - Likes/dislikes pour le matching
3. **matches** - Matches mutuels entre utilisateurs
4. **messages** - Messages de chat
5. **stations** - Référentiel des stations de ski
6. **user_station_status** - Station actuelle + dates pour chaque user
7. **ride_stats** - Statistiques GPS des sessions de ski
8. **subscriptions** - Abonnements Stripe
9. **profile_photos** - Photos de profil avec modération
10. **friends** - Amitiés pour le mode crew
11. **boosts** - Boosts de station achetés
12. **groups** - Groupes de 2-4 riders
13. **group_members** - Membres des groupes
14. **user_consents** - Consentements RGPD (GPS, notifications)

## 🔒 RLS Policies créées

Toutes les tables ont des policies RLS pour :
- Les utilisateurs peuvent lire/modifier uniquement leurs propres données
- Les matches/messages accessibles uniquement aux participants
- Les photos approuvées lisibles par tous
- Les stations lisibles par tous

## 📊 Index créés

Index de performance sur :
- `likes(liker_id, liked_id)` - Recherche de réciprocité
- `matches(user1_id, user2_id)` - Recherche de matches
- `messages(match_id)` - Messages par match
- `user_station_status(date_from, date_to)` - Filtrage par dates
- Et beaucoup d'autres...

## 🔧 Fonctions SQL créées

- `get_total_unread_count(p_user_id UUID)` - Nombre de messages non lus
- `update_match_last_message_at()` - Trigger pour mettre à jour last_message_at

## 🚀 Comment utiliser

### Étape 1 : Exécuter la migration complète

Dans **Supabase Dashboard > SQL Editor**, copiez-collez le contenu de :
```
backend/supabase/migrations/20250117_complete_schema.sql
```

Cliquez sur **Run**.

### Étape 2 : Vérifier que tout est créé

```sql
-- Vérifier les tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Vérifier les policies RLS
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### Étape 3 : Créer votre profil

```sql
-- Remplacez VOTRE_USER_ID
UPDATE public.users 
SET 
  onboarding_completed = true,
  is_active = true,
  level = 'intermediate',
  ride_styles = ARRAY['alpine', 'snowboard']::ride_style[],
  languages = ARRAY['fr', 'en']::language_code[],
  bio = 'Passionné de ski !',
  last_active_at = NOW(),
  updated_at = NOW()
WHERE id = 'VOTRE_USER_ID';
```

## ⚠️ Notes importantes

- Cette migration utilise `CREATE TABLE IF NOT EXISTS` et `DROP POLICY IF EXISTS` pour être **idempotente** (peut être exécutée plusieurs fois sans erreur)
- Les colonnes existantes ne sont pas modifiées
- Les nouvelles colonnes sont ajoutées seulement si elles n'existent pas
- Les policies sont recréées (DROP puis CREATE) pour éviter les doublons

## 📝 Prochaines étapes après cette migration

1. ✅ Redéployer les Edge Functions (match-candidates, gatekeeper, manage-consent)
2. ✅ Créer votre profil utilisateur
3. ✅ Créer quelques stations de test dans `stations`
4. ✅ Créer quelques utilisateurs de test pour voir des profils dans le feed
5. ✅ Tester le flux complet : login → onboarding → feed → profil

---

**Cette migration crée TOUT le schéma nécessaire selon le plan DEV 2. Plus besoin de créer les tables manuellement !** 🎯

