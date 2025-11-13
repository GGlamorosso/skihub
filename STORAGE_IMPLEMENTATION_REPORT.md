# CrewSnow - Rapport Implémentation Storage & Modération

## 📋 Résumé Exécutif

✅ **Migration créée** : `supabase/migrations/20241118_storage_policies.sql`
✅ **Bucket sécurisé** : `profile_photos` avec RLS et limites strictes
✅ **5 politiques Storage** : Upload UID, lecture publique/privée, modération
✅ **Synchronisation DB ↔ Storage** : Metadata automatiquement synchronisées  
✅ **Workflow modération** : Fonctions complètes approve/reject/upload
✅ **Tests complets** : `supabase/test/storage_validation_test.sql`

---

## 🗂️ 1. Configuration Bucket Profile_Photos

### 1.1 Spécifications Bucket
```sql
-- Bucket sécurisé et optimisé
{
  id: 'profile_photos',
  name: 'profile_photos', 
  public: false,              -- ✅ Privé par défaut
  file_size_limit: 5242880,   -- ✅ 5MB max
  allowed_mime_types: [       -- ✅ Images seulement
    'image/jpeg',
    'image/png', 
    'image/webp',
    'image/gif'
  ]
}
```

### 1.2 Structure de Dossiers UID
```
profile_photos/
├── 00000000-0000-0000-0000-000000000001/
│   ├── profile_main.jpg
│   ├── profile_alt1.png
│   └── profile_alt2.webp
├── 00000000-0000-0000-0000-000000000002/
│   └── avatar.jpg
└── ...
```

**Avantages** :
- ✅ **Isolation utilisateurs** : Impossible d'accéder aux dossiers d'autrui
- ✅ **Organisation claire** : Un dossier par utilisateur
- ✅ **Sécurité renforcée** : Structure basée sur UUID non-devinable

---

## 🔐 2. Politiques Storage (RLS)

### 2.1 Upload Policy - Structure UID Forcée
```sql
CREATE POLICY "user can upload to their folder"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'profile_photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND auth.uid() IS NOT NULL
  );
```

**Protection** :
- ✅ Upload uniquement dans son dossier `/<uid>/`
- ✅ Impossible d'uploader dans dossier d'autrui
- ✅ Vérification auth.uid() non-null

### 2.2 Lecture Publique - Photos Approuvées Seulement
```sql
CREATE POLICY "public read approved profile photos"
  ON storage.objects FOR SELECT TO anon, authenticated
  USING (
    bucket_id = 'profile_photos'
    AND metadata->>'moderation_status' = 'approved'
  );
```

**Sécurité** :
- ✅ Accès public **uniquement** si `moderation_status = 'approved'`
- ✅ Photos `pending`/`rejected` invisibles au public
- ✅ Contrôle via metadata JSON

### 2.3 Lecture Propriétaire - Toutes Photos
```sql
CREATE POLICY "owner read their photos"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'profile_photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND auth.uid() IS NOT NULL
  );
```

**Fonctionnalités** :
- ✅ Utilisateur voit **toutes** ses photos (pending, approved, rejected)
- ✅ Nécessaire pour interface de gestion photos
- ✅ Isolation stricte par UID

### 2.4 Modification & Suppression Propriétaire
```sql
-- UPDATE: Metadata des photos
CREATE POLICY "owner update their photos" ...

-- DELETE: Suppression photos
CREATE POLICY "owner delete their photos" ...
```

---

## 🔄 3. Synchronisation DB ↔ Storage

### 3.1 Trigger Automatique DB → Storage
```sql
CREATE TRIGGER trigger_sync_photo_moderation
  AFTER UPDATE OF moderation_status, is_main ON public.profile_photos
  FOR EACH ROW
  EXECUTE FUNCTION sync_photo_moderation_to_storage();
```

**Fonctionnement** :
- ✅ **Changement DB** → Met à jour `storage.objects.metadata`
- ✅ **Synchronisation temps réel** : Trigger automatique
- ✅ **Cohérence garantie** : Pas de désync possible

### 3.2 Fonction Sync Storage → DB
```sql
CREATE FUNCTION sync_photo_moderation_from_storage(
  storage_path text,
  new_status moderation_status
) RETURNS void
```

**Usage** :
- ✅ **Modération manuelle** : Admin change directement Storage
- ✅ **Sync bidirectionnelle** : Storage → DB → Storage
- ✅ **Workflow flexible** : Support modération externe

### 3.3 Structure Metadata JSON
```json
{
  "moderation_status": "approved|pending|rejected",
  "is_main": true|false,
  "user_id": "uuid-string",
  "uploaded_at": "2024-11-18T10:30:00Z",
  "updated_at": "2024-11-18T11:15:00Z"
}
```

---

## 📸 4. Workflow Complet Upload & Modération

### 4.1 Upload Workflow
```sql
-- 1. Upload fichier via client
-- 2. Appeler fonction post-upload
SELECT handle_photo_upload(
  user_id := auth.uid(),
  storage_path := 'uuid/filename.jpg',
  is_main := true
);
```

**Process automatique** :
1. ✅ **Insert DB** : Entrée `profile_photos` avec `status = 'pending'`
2. ✅ **Update Storage** : Metadata synchronisées  
3. ✅ **Gestion is_main** : Désactive autres photos principales
4. ✅ **Cohérence** : DB et Storage alignés

### 4.2 Modération Workflow
```sql
-- Approuver une photo
SELECT moderate_photo(
  photo_id := 'uuid',
  new_status := 'approved'::moderation_status,
  moderation_reason := 'Photo conforme'
);
```

**Process automatique** :
1. ✅ **Update DB** : `moderation_status` + `moderation_reason`
2. ✅ **Trigger Storage** : Metadata synchronisées automatiquement
3. ✅ **Accès public** : Photo devient visible publiquement
4. ✅ **Audit trail** : Raison de modération conservée

### 4.3 Signed URLs Sécurisées
```sql
-- Obtenir URL signée pour photo approuvée
SELECT get_approved_photo_signed_url(
  user_id := 'uuid',
  expires_in_seconds := 3600
);
```

---

## 🧪 5. Tests de Validation

### 5.1 Tests de Configuration
- ✅ **Bucket existe** : Configuration correcte
- ✅ **RLS activé** : `storage.objects` sécurisé
- ✅ **Politiques créées** : 5 politiques actives

### 5.2 Tests d'Accès
- ✅ **Upload UID** : Utilisateur ne peut uploader que dans son dossier
- ✅ **Lecture publique** : Seulement photos `approved` visibles
- ✅ **Lecture propriétaire** : Toutes ses photos accessibles
- ✅ **Isolation** : Impossible d'accéder aux photos d'autrui

### 5.3 Tests de Synchronisation
- ✅ **DB → Storage** : Changement status sync automatiquement
- ✅ **Storage → DB** : Fonction manuelle fonctionne
- ✅ **Metadata cohérence** : JSON structure correcte

---

## 🔒 6. Sécurité Renforcée

### 6.1 Protection Données Sensibles
```
❌ BLOQUÉ (anon/autres users):
- Photos pending/rejected
- Dossiers d'autres utilisateurs  
- Metadata privées

✅ AUTORISÉ:
- Photos approved (public)
- Propres photos (propriétaire)
- Upload dans son dossier UID
```

### 6.2 Contrôles Techniques
- ✅ **Taille fichier** : 5MB max (protection serveur)
- ✅ **Types MIME** : Images seulement (sécurité)
- ✅ **Structure UID** : Dossiers non-devinables
- ✅ **RLS Storage** : Politiques au niveau base

### 6.3 Workflow Modération Sécurisé
- ✅ **Pending par défaut** : Nouvelles photos non-publiques
- ✅ **Approbation explicite** : Modération manuelle requise
- ✅ **Audit trail** : Raisons de modération conservées
- ✅ **Révocable** : Photos peuvent être re-rejetées

---

## 📊 7. Impact Performance

### 7.1 Optimisations Storage
- ✅ **Index metadata** : Recherche `moderation_status` rapide
- ✅ **Bucket privé** : Pas de CDN public (contrôle accès)
- ✅ **Signed URLs** : Accès temporaire sécurisé
- ✅ **Compression** : WebP supporté (taille réduite)

### 7.2 Optimisations Base
- ✅ **Triggers efficaces** : Sync seulement sur changement
- ✅ **Index profile_photos** : Recherche par user_id rapide
- ✅ **Fonctions SECURITY DEFINER** : Permissions optimales

---

## 🔗 8. Intégration Frontend

### 8.1 Upload Client
```typescript
// 1. Upload fichier
const { data, error } = await supabase.storage
  .from('profile_photos')
  .upload(`${userId}/photo_${Date.now()}.jpg`, file);

// 2. Enregistrer en DB
await supabase.rpc('handle_photo_upload', {
  user_id: userId,
  storage_path: data.path,
  is_main: true
});
```

### 8.2 Affichage Public
```typescript
// Photos approuvées seulement (via vue publique)
const { data } = await supabase
  .from('public_profiles_v')
  .select('photo_main_url')
  .eq('id', userId);
```

### 8.3 Gestion Photos Privées
```typescript
// Toutes les photos utilisateur (interface privée)
const { data } = await supabase
  .from('profile_photos')
  .select('*')
  .eq('user_id', userId);
```

---

## ✅ 9. Validation Complète

### Architecture ✅
- **Bucket sécurisé** : Configuration production-ready
- **Politiques RLS** : Isolation utilisateurs garantie  
- **Workflow modération** : Process complet approve/reject
- **Synchronisation** : DB ↔ Storage cohérentes

### Sécurité ✅
- **Accès contrôlé** : Public = approved seulement
- **Structure UID** : Dossiers non-devinables
- **Validation fichiers** : Taille + MIME types
- **Audit trail** : Historique modération

### Performance ✅
- **Triggers optimisés** : Sync seulement si changement
- **Storage privé** : Contrôle accès granulaire
- **Signed URLs** : Accès temporaire sécurisé
- **Formats modernes** : WebP supporté

### Fonctionnel ✅
- **Upload workflow** : Process complet automatisé
- **Modération** : Interface admin ready
- **Frontend integration** : APIs claires
- **Tests complets** : Validation exhaustive

---

**Migration Storage prête pour déploiement** ✅  
**Modération sécurisée niveau production** 🔒  
**Workflow complet upload → approve → public** 📸
