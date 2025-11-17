# Edge Function: manage-consent

## Déploiement

```bash
cd backend/supabase/functions/manage-consent
supabase functions deploy manage-consent
```

## Utilisation

### Vérifier un consentement
```typescript
const { data, error } = await supabase.functions.invoke('manage-consent', {
  body: {
    action: 'check',
    purpose: 'gps_tracking'
  }
})
```

### Accorder un consentement
```typescript
const { data, error } = await supabase.functions.invoke('manage-consent', {
  body: {
    action: 'grant',
    purpose: 'gps_tracking',
    version: 1
  }
})
```

### Révoquer un consentement
```typescript
const { data, error } = await supabase.functions.invoke('manage-consent', {
  body: {
    action: 'revoke',
    purpose: 'gps_tracking'
  }
})
```

