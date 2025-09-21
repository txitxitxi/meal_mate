-- Debug the auto-translation system
-- Check why the trigger isn't working for new ingredients

-- 1. Check if the trigger exists
SELECT 
    'TRIGGER CHECK' as check_type,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_auto_translate_ingredient';

-- 2. Check if the function exists
SELECT 
    'FUNCTION CHECK' as check_type,
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'auto_translate_ingredient';

-- 3. Test the translation mapping table
SELECT 
    'TRANSLATION MAPPING CHECK' as check_type,
    english_name,
    chinese_name,
    category
FROM public.ingredient_translations
WHERE english_name IN ('Chicken', 'Beef', 'Rice', 'Noodle')
ORDER BY english_name;

-- 4. Check if there are any recent ingredients without Chinese aliases
SELECT 
    'RECENT INGREDIENTS WITHOUT CHINESE' as check_type,
    i.name as english_name,
    i.category,
    i.created_at,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.ingredient_translations it 
            WHERE LOWER(it.english_name) = LOWER(i.name)
        ) THEN 'HAS MAPPING' 
        ELSE 'NO MAPPING' 
    END as translation_mapping_status
FROM public.ingredients i
WHERE NOT EXISTS (
    SELECT 1 FROM public.ingredient_terms it 
    WHERE it.ingredient_id = i.id AND it.locale = 'zh'
)
AND i.created_at > NOW() - INTERVAL '1 hour'
ORDER BY i.created_at DESC;

-- 5. Test the auto-translation function manually
-- First, let's see what happens when we call it directly
SELECT 
    'MANUAL FUNCTION TEST' as test_type,
    'Testing auto_translate_ingredient function' as description;

-- 6. Check the ingredient_translations table structure
SELECT 
    'TABLE STRUCTURE CHECK' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'ingredient_translations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 7. Show some sample data from ingredient_translations
SELECT 
    'SAMPLE TRANSLATIONS' as check_type,
    english_name,
    chinese_name,
    category
FROM public.ingredient_translations
ORDER BY english_name
LIMIT 10;
