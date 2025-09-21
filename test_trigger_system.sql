-- Test the auto-translation trigger system
-- This will check if the trigger is working and test it with a known ingredient

-- 1. Check if "Noodle" is in the translation mapping table
SELECT 
    'NOODLE MAPPING CHECK' as check_type,
    english_name,
    chinese_name,
    category
FROM public.ingredient_translations
WHERE english_name = 'Noodle';

-- 2. Check if "Rice" is in the translation mapping (should be there)
SELECT 
    'RICE MAPPING CHECK' as check_type,
    english_name,
    chinese_name,
    category
FROM public.ingredient_translations
WHERE english_name = 'Rice';

-- 3. Check if "Chicken" is in the translation mapping (should be there)
SELECT 
    'CHICKEN MAPPING CHECK' as check_type,
    english_name,
    chinese_name,
    category
FROM public.ingredient_translations
WHERE english_name = 'Chicken';

-- 4. Test the trigger by adding a new ingredient that SHOULD auto-translate
-- Let's try "Rice" since it should be in the mapping
INSERT INTO public.ingredients (name, category, default_unit, created_by)
VALUES ('Test Rice Auto', 'grain', 'cup', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid);

-- 5. Check if "Test Rice Auto" got auto-translated
SELECT 
    'AUTO-TRANSLATION TEST RESULT' as test_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary,
    it.created_at as alias_created_at
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Test Rice Auto';

-- 6. Test with "Chicken" (should also auto-translate)
INSERT INTO public.ingredients (name, category, default_unit, created_by)
VALUES ('Test Chicken Auto', 'meat', 'g', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid);

-- 7. Check if "Test Chicken Auto" got auto-translated
SELECT 
    'CHICKEN AUTO-TRANSLATION TEST' as test_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary,
    it.created_at as alias_created_at
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Test Chicken Auto';

-- 8. Check the trigger function directly
SELECT 
    'TRIGGER FUNCTION TEST' as test_type,
    'Testing if trigger function exists and works' as description;

-- 9. Show recent test ingredients
SELECT 
    'RECENT TEST INGREDIENTS' as check_type,
    i.name as english_name,
    i.category,
    i.created_at,
    CASE 
        WHEN it.term IS NOT NULL THEN CONCAT('YES - ', it.term) 
        ELSE 'NO' 
    END as has_chinese_alias
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name LIKE 'Test %'
ORDER BY i.created_at DESC;

-- 10. Check if the trigger exists and is enabled
SELECT 
    'TRIGGER STATUS' as check_type,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_auto_translate_ingredient';
