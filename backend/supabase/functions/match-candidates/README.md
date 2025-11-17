# Edge Function: match-candidates

## Déploiement

```bash
cd backend/supabase/functions/match-candidates
supabase functions deploy match-candidates
```

## Utilisation

```typescript
const { data, error } = await supabase.functions.invoke('match-candidates', {
  body: {
    limit: 10,
    cursor: null, // Pour pagination
    latitude: 45.5,
    longitude: 6.0,
    filters: {
      minAge: 18,
      maxAge: 35,
      level: 'intermediate',
      rideStyles: ['alpine', 'snowboard']
    }
  }
})
```