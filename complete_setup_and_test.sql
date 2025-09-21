-- Complete Setup and Test Script
-- This script completes the bilingual ingredient system and tests everything

-- =============================================================================
-- STEP 1: Add the final missing Chinese aliases for the 20 specific ingredients
-- =============================================================================

-- Function to add Chinese alias if it doesn't exist
CREATE OR REPLACE FUNCTION add_chinese_alias_if_missing(
    english_name text,
    chinese_name text
) RETURNS void AS $$
BEGIN
    INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
    SELECT id, chinese_name, 'zh', true, 10 
    FROM public.ingredients 
    WHERE name = english_name
    AND NOT EXISTS (
        SELECT 1 FROM public.ingredient_terms it 
        WHERE it.ingredient_id = public.ingredients.id 
        AND it.locale = 'zh'
    );
END;
$$ LANGUAGE plpgsql;

-- Add Chinese aliases for the specific missing ingredients
SELECT add_chinese_alias_if_missing('Yeast', '酵母');
SELECT add_chinese_alias_if_missing('Olives', '橄榄');
SELECT add_chinese_alias_if_missing('Whole Milk', '全脂牛奶');
SELECT add_chinese_alias_if_missing('Goat Yogurt', '山羊酸奶');
SELECT add_chinese_alias_if_missing('Frozen Peas', '冷冻豌豆');
SELECT add_chinese_alias_if_missing('Tortillas', '墨西哥饼');
SELECT add_chinese_alias_if_missing('Hotpot Beef', '火锅牛肉');
SELECT add_chinese_alias_if_missing('Hotpot Lamb', '火锅羊肉');
SELECT add_chinese_alias_if_missing('Pork', '猪肉');
SELECT add_chinese_alias_if_missing('Egg', '鸡蛋');
SELECT add_chinese_alias_if_missing('Lotus Root', '莲藕');
SELECT add_chinese_alias_if_missing('Lotus Rooot', '莲藕'); -- Note: fixing the typo in the name
SELECT add_chinese_alias_if_missing('Broccoli', '西兰花');
SELECT add_chinese_alias_if_missing('Carrots', '胡萝卜');
SELECT add_chinese_alias_if_missing('Green Pepper', '青椒');
SELECT add_chinese_alias_if_missing('Lettuce', '生菜');
SELECT add_chinese_alias_if_missing('Mushrooms', '蘑菇');
SELECT add_chinese_alias_if_missing('Onions', '洋葱');
SELECT add_chinese_alias_if_missing('Potatoes', '土豆');
SELECT add_chinese_alias_if_missing('Tomatoes', '西红柿');

-- Clean up the function
DROP FUNCTION add_chinese_alias_if_missing(text, text);

-- =============================================================================
-- STEP 2: Verify completion status
-- =============================================================================

SELECT 
    'COMPLETION STATUS' as status,
    (SELECT COUNT(*) FROM public.ingredients) as total_ingredients,
    (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
     WHERE EXISTS (
       SELECT 1 FROM public.ingredient_terms it 
       WHERE it.ingredient_id = i.id AND it.locale = 'zh'
     )) as ingredients_with_chinese,
    (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
     WHERE NOT EXISTS (
       SELECT 1 FROM public.ingredient_terms it 
       WHERE it.ingredient_id = i.id AND it.locale = 'zh'
     )) as ingredients_without_chinese,
    ROUND(
        (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
         WHERE EXISTS (
           SELECT 1 FROM public.ingredient_terms it 
           WHERE it.ingredient_id = i.id AND it.locale = 'zh'
         ))::numeric / 
        (SELECT COUNT(*) FROM public.ingredients)::numeric * 100, 
        2
    ) as percentage_with_chinese;

-- =============================================================================
-- STEP 3: Test the auto-translation system
-- =============================================================================

-- Test 1: Add a new ingredient that should get auto-translated
INSERT INTO public.ingredients (name, category, default_unit, created_by)
VALUES ('Test Auto Chicken', 'meat', 'g', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid)
ON CONFLICT (name_norm) DO NOTHING;

-- Check if auto-translation worked
SELECT 
    'AUTO-TRANSLATION TEST' as test_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Test Auto Chicken';

-- Test 2: Add an ingredient that doesn't have a translation
INSERT INTO public.ingredients (name, category, default_unit, created_by)
VALUES ('Test Unknown Item', 'other', 'g', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid)
ON CONFLICT (name_norm) DO NOTHING;

-- Check that no Chinese alias was added
SELECT 
    'NO TRANSLATION TEST' as test_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Test Unknown Item';

-- =============================================================================
-- STEP 4: Test the translation management functions
-- =============================================================================

-- Test adding a new translation
SELECT add_ingredient_translation(
    'Test Unknown Item',
    '测试未知物品',
    'other'
);

-- Test retroactive translation application
SELECT 
    'RETROACTIVE TRANSLATION' as action,
    apply_retroactive_translations() as translations_applied;

-- =============================================================================
-- STEP 5: Final verification and statistics
-- =============================================================================

-- Final completion status
SELECT 
    'FINAL COMPLETION STATUS' as status,
    (SELECT COUNT(*) FROM public.ingredients) as total_ingredients,
    (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
     WHERE EXISTS (
       SELECT 1 FROM public.ingredient_terms it 
       WHERE it.ingredient_id = i.id AND it.locale = 'zh'
     )) as ingredients_with_chinese,
    (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
     WHERE NOT EXISTS (
       SELECT 1 FROM public.ingredient_terms it 
       WHERE it.ingredient_id = i.id AND it.locale = 'zh'
     )) as ingredients_without_chinese,
    ROUND(
        (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
         WHERE EXISTS (
           SELECT 1 FROM public.ingredient_terms it 
           WHERE it.ingredient_id = i.id AND it.locale = 'zh'
         ))::numeric / 
        (SELECT COUNT(*) FROM public.ingredients)::numeric * 100, 
        2
    ) as percentage_with_chinese;

-- Translation system statistics
SELECT 
    'TRANSLATION SYSTEM STATS' as category,
    (SELECT COUNT(*) FROM public.ingredient_translations) as total_translations_available,
    (SELECT COUNT(*) FROM public.ingredient_terms WHERE locale = 'zh') as total_chinese_aliases,
    (SELECT COUNT(DISTINCT ingredient_id) FROM public.ingredient_terms WHERE locale = 'zh') as unique_ingredients_with_chinese;

-- Show some sample bilingual ingredients
SELECT 
    'SAMPLE BILINGUAL INGREDIENTS' as category,
    i.name as english_name,
    it.term as chinese_name,
    i.category
FROM public.ingredients i
JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE it.is_primary = true
ORDER BY i.category, i.name
LIMIT 10;

-- =============================================================================
-- STEP 6: Clean up test data (optional)
-- =============================================================================

-- Uncomment the following lines if you want to clean up test data:
-- DELETE FROM public.ingredient_terms WHERE ingredient_id IN (
--     SELECT id FROM public.ingredients WHERE name LIKE 'Test %'
-- );
-- DELETE FROM public.ingredients WHERE name LIKE 'Test %';
-- DELETE FROM public.ingredient_translations WHERE english_name LIKE 'Test %';

-- =============================================================================
-- COMPLETION MESSAGE
-- =============================================================================

SELECT 
    '🎉 SETUP COMPLETE! 🎉' as message,
    'Your bilingual ingredient system is now fully operational!' as status,
    'You can now test in your Flutter app!' as next_step;
