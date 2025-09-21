-- Check if "Noodle" has a Chinese alias
-- This will verify if the auto-translation system worked

-- 1. Check if "Noodle" ingredient exists
SELECT 
    'NOODLE INGREDIENT CHECK' as check_type,
    i.id,
    i.name as english_name,
    i.category,
    i.default_unit,
    i.created_at
FROM public.ingredients i
WHERE i.name ILIKE '%noodle%'
ORDER BY i.created_at DESC;

-- 2. Check if "Noodle" has Chinese aliases
SELECT 
    'NOODLE CHINESE ALIAS CHECK' as check_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary,
    it.weight,
    it.created_at as alias_created_at
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name ILIKE '%noodle%'
ORDER BY i.created_at DESC, it.created_at DESC;

-- 3. Check if "Noodle" has a translation mapping
SELECT 
    'NOODLE TRANSLATION MAPPING CHECK' as check_type,
    it.english_name,
    it.chinese_name,
    it.category,
    it.created_at
FROM public.ingredient_translations it
WHERE it.english_name ILIKE '%noodle%';

-- 4. Show recent ingredients (last 10) to see when "Noodle" was added
SELECT 
    'RECENT INGREDIENTS' as check_type,
    i.name as english_name,
    i.category,
    i.created_at,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.ingredient_terms it 
            WHERE it.ingredient_id = i.id AND it.locale = 'zh'
        ) THEN 'YES' 
        ELSE 'NO' 
    END as has_chinese_alias
FROM public.ingredients i
ORDER BY i.created_at DESC
LIMIT 10;

-- 5. Check auto-translation system status
SELECT 
    'AUTO-TRANSLATION SYSTEM STATUS' as check_type,
    (SELECT COUNT(*) FROM public.ingredient_translations) as total_translations_available,
    (SELECT COUNT(*) FROM public.ingredients) as total_ingredients,
    (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
     WHERE EXISTS (
       SELECT 1 FROM public.ingredient_terms it 
       WHERE it.ingredient_id = i.id AND it.locale = 'zh'
     )) as ingredients_with_chinese_aliases;
