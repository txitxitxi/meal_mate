-- Fix the missing "Noodle" translation
-- This will add the Chinese alias for "Noodle" and test the system

-- 1. First, add "Noodle" to the translation mapping table
INSERT INTO public.ingredient_translations (english_name, chinese_name, category)
VALUES ('Noodle', '面条', 'grain')
ON CONFLICT (english_name) DO UPDATE SET
    chinese_name = EXCLUDED.chinese_name,
    category = EXCLUDED.category,
    updated_at = now();

-- 2. Add Chinese alias for existing "Noodle" ingredient
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '面条', 'zh', true, 10 
FROM public.ingredients 
WHERE name = 'Noodle'
AND NOT EXISTS (
    SELECT 1 FROM public.ingredient_terms it 
    WHERE it.ingredient_id = public.ingredients.id AND it.locale = 'zh'
);

-- 3. Verify the fix worked
SELECT 
    'NOODLE TRANSLATION FIXED' as status,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary,
    it.created_at as alias_created_at
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Noodle';

-- 4. Test the auto-translation system with a new ingredient
-- Add a new ingredient that should get auto-translated
INSERT INTO public.ingredients (name, category, default_unit, created_by)
VALUES ('Test Rice', 'grain', 'cup', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid);

-- Check if "Test Rice" got auto-translated
SELECT 
    'AUTO-TRANSLATION TEST' as test_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Test Rice';

-- 5. Show recent ingredients with their Chinese aliases
SELECT 
    'RECENT INGREDIENTS WITH CHINESE' as check_type,
    i.name as english_name,
    it.term as chinese_name,
    i.category,
    i.created_at,
    CASE 
        WHEN it.term IS NOT NULL THEN 'YES' 
        ELSE 'NO' 
    END as has_chinese_alias
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
ORDER BY i.created_at DESC
LIMIT 10;

-- 6. Check translation mapping for "Noodle"
SELECT 
    'NOODLE MAPPING VERIFICATION' as check_type,
    it.english_name,
    it.chinese_name,
    it.category,
    it.created_at
FROM public.ingredient_translations it
WHERE it.english_name = 'Noodle';
