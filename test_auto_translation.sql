-- Test script for the auto-translation system
-- This script tests the automated Chinese alias addition for new ingredients

-- 1. First, let's see the current state
SELECT 
    'BEFORE TESTING' as status,
    COUNT(*) as total_ingredients,
    COUNT(CASE WHEN EXISTS (
        SELECT 1 FROM public.ingredient_terms it 
        WHERE it.ingredient_id = public.ingredients.id AND it.locale = 'zh'
    ) THEN 1 END) as ingredients_with_chinese;

-- 2. Test adding a new ingredient that has a translation available
-- This should automatically add the Chinese alias via the trigger
INSERT INTO public.ingredients (name, category, default_unit, created_by)
VALUES ('Test Chicken Breast', 'meat', 'g', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid)
ON CONFLICT (name_norm) DO NOTHING;

-- 3. Check if the Chinese alias was automatically added
SELECT 
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary,
    it.created_at
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Test Chicken Breast';

-- 4. Test adding an ingredient that doesn't have a translation
-- This should NOT add a Chinese alias
INSERT INTO public.ingredients (name, category, default_unit, created_by)
VALUES ('Test Unknown Ingredient', 'other', 'g', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid)
ON CONFLICT (name_norm) DO NOTHING;

-- 5. Check if no Chinese alias was added for the unknown ingredient
SELECT 
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Test Unknown Ingredient';

-- 6. Test the add_ingredient_translation function
SELECT add_ingredient_translation(
    'Test Unknown Ingredient',
    '测试未知成分',
    'other'
);

-- 7. Now add another ingredient with the same name to test the updated translation
INSERT INTO public.ingredients (name, category, default_unit, created_by)
VALUES ('Test Unknown Ingredient 2', 'other', 'g', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid)
ON CONFLICT (name_norm) DO NOTHING;

-- 8. Check if the new ingredient got the Chinese alias
SELECT 
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Test Unknown Ingredient 2';

-- 9. Test the retroactive translation function
SELECT 
    'RETROACTIVE TRANSLATION TEST' as test_type,
    COUNT(*) as ingredients_to_translate
FROM retroactively_translate_ingredients();

-- 10. Apply retroactive translations
SELECT 
    'APPLYING RETROACTIVE TRANSLATIONS' as action,
    apply_retroactive_translations() as translations_applied;

-- 11. Final state check
SELECT 
    'AFTER TESTING' as status,
    COUNT(*) as total_ingredients,
    COUNT(CASE WHEN EXISTS (
        SELECT 1 FROM public.ingredient_terms it 
        WHERE it.ingredient_id = public.ingredients.id AND it.locale = 'zh'
    ) THEN 1 END) as ingredients_with_chinese,
    ROUND(
        COUNT(CASE WHEN EXISTS (
            SELECT 1 FROM public.ingredient_terms it 
            WHERE it.ingredient_id = public.ingredients.id AND it.locale = 'zh'
        ) THEN 1 END)::numeric / COUNT(*)::numeric * 100, 
        2
    ) as percentage_with_chinese;

-- 12. Show recent test ingredients
SELECT 
    i.name as english_name,
    it.term as chinese_name,
    i.category,
    i.created_at
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name LIKE 'Test %'
ORDER BY i.created_at DESC;

-- 13. Clean up test data (optional - comment out if you want to keep the test data)
-- DELETE FROM public.ingredient_terms WHERE ingredient_id IN (
--     SELECT id FROM public.ingredients WHERE name LIKE 'Test %'
-- );
-- DELETE FROM public.ingredients WHERE name LIKE 'Test %';
-- DELETE FROM public.ingredient_translations WHERE english_name LIKE 'Test %';
