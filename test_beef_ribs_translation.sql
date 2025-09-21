-- Test the smart translation system with "Beef Ribs"

-- 1. Check if "Beef Ribs" ingredient was added
SELECT 
    'BEEF RIBS INGREDIENT CHECK' as check_type,
    i.id,
    i.name as english_name,
    i.category,
    i.default_unit,
    i.created_at
FROM public.ingredients i
WHERE i.name ILIKE '%beef ribs%' OR i.name ILIKE '%beef%ribs%'
ORDER BY i.created_at DESC;

-- 2. Check if "Beef Ribs" has Chinese aliases
SELECT 
    'BEEF RIBS CHINESE ALIAS CHECK' as check_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary,
    it.created_at as alias_created_at
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name ILIKE '%beef ribs%' OR i.name ILIKE '%beef%ribs%'
ORDER BY i.created_at DESC;

-- 3. Check if "Beef Ribs" is in the translation cache
SELECT 
    'BEEF RIBS CACHE CHECK' as check_type,
    english_name,
    chinese_name,
    category,
    created_at
FROM public.ingredient_translations
WHERE english_name ILIKE '%beef%ribs%' OR english_name ILIKE '%beef ribs%';

-- 4. Show recent ingredients to see when "Beef Ribs" was added
SELECT 
    'RECENT INGREDIENTS' as check_type,
    i.name as english_name,
    i.category,
    i.created_at,
    CASE 
        WHEN it.term IS NOT NULL THEN CONCAT('YES - ', it.term) 
        ELSE 'NO' 
    END as has_chinese_alias,
    CASE 
        WHEN it.term LIKE '[Auto-translate:%' THEN 'PENDING TRANSLATION'
        WHEN it.term IS NOT NULL THEN 'TRANSLATED'
        ELSE 'NO TRANSLATION'
    END as translation_status
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.created_at > NOW() - INTERVAL '10 minutes'
ORDER BY i.created_at DESC;

-- 5. Check what the Edge Function would translate "Beef Ribs" to
-- (This simulates what should happen when Flutter calls the Edge Function)
SELECT 
    'EDGE FUNCTION SIMULATION' as test_type,
    'beef ribs' as input,
    CASE 
        WHEN EXISTS (SELECT 1 FROM public.ingredient_translations WHERE english_name = 'beef ribs') 
        THEN (SELECT chinese_name FROM public.ingredient_translations WHERE english_name = 'beef ribs')
        WHEN EXISTS (SELECT 1 FROM public.ingredient_translations WHERE english_name = 'beef') 
        THEN (SELECT chinese_name FROM public.ingredient_translations WHERE english_name = 'beef') || ' + 肋骨'
        ELSE '[需要翻译: beef ribs]'
    END as expected_translation;

-- 6. Smart translation system status
SELECT 
    'SMART TRANSLATION SYSTEM STATUS' as check_type,
    (SELECT COUNT(*) FROM public.ingredient_translations) as cached_translations,
    (SELECT COUNT(*) FROM public.ingredients) as total_ingredients,
    (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
     WHERE EXISTS (
       SELECT 1 FROM public.ingredient_terms it 
       WHERE it.ingredient_id = i.id AND it.locale = 'zh'
     )) as ingredients_with_chinese_aliases;
