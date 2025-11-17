# Edge Function: gatekeeper

## Déploiement

```bash
cd backend/supabase/functions/gatekeeper
supabase functions deploy gatekeeper
```

## Utilisation

```typescript
const { data, error } = await supabase.functions.invoke('gatekeeper', {
  body: {
    action: 'swipe', // ou 'message', 'view_profile'
    resource: 'candidate'
  }
})
```

