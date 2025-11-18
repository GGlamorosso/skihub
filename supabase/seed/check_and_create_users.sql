-- ============================================================================
-- Script pour vérifier et créer les utilisateurs manquants
-- ============================================================================
-- Ce script vérifie quels utilisateurs existent dans auth.users
-- et les crée dans public.users s'ils n'existent pas
-- ============================================================================

-- Afficher les utilisateurs existants dans auth.users
SELECT 
    id,
    email,
    created_at,
    CASE 
        WHEN EXISTS (SELECT 1 FROM public.users WHERE users.id = auth.users.id) 
        THEN '✅ Existe dans public.users'
        ELSE '❌ Manquant dans public.users'
    END as status
FROM auth.users
ORDER BY created_at DESC
LIMIT 30;

-- Créer les utilisateurs manquants dans public.users
INSERT INTO public.users (
    id,
    email,
    username,
    onboarding_completed,
    is_active,
    level,
    ride_styles,
    languages,
    objectives,
    created_at,
    updated_at,
    last_active_at
)
SELECT 
    au.id,
    au.email,
    COALESCE(au.email, 'user_' || SUBSTRING(au.id::TEXT, 1, 8)) as username,
    false,
    true,
    'beginner'::user_level,
    ARRAY[]::ride_style[],
    ARRAY[]::language_code[],
    ARRAY[]::TEXT[],
    au.created_at,
    NOW(),
    NOW()
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = au.id
)
ON CONFLICT (id) DO NOTHING;

-- Afficher le résultat
SELECT 
    COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.users WHERE users.id = auth.users.id)) as users_created,
    COUNT(*) as total_auth_users
FROM auth.users;

RAISE NOTICE '✅ Utilisateurs créés dans public.users si nécessaire';

