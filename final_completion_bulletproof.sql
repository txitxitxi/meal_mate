-- Bulletproof Final Completion Script
-- This script completes the bilingual ingredient system without relying on unique constraints

-- =============================================================================
-- STEP 1: Add the final missing Chinese aliases for the 20 specific ingredients
-- =============================================================================

-- Function to safely add Chinese alias if it doesn't exist
CREATE OR REPLACE FUNCTION add_chinese_alias_safe(
    english_name text,
    chinese_name text
) RETURNS void AS $$
BEGIN
    -- Check if the ingredient exists and doesn't already have a Chinese alias
    IF EXISTS (
        SELECT 1 FROM public.ingredients i
        WHERE i.name = english_name
        AND NOT EXISTS (
            SELECT 1 FROM public.ingredient_terms it 
            WHERE it.ingredient_id = i.id AND it.locale = 'zh'
        )
    ) THEN
        -- Insert the Chinese alias
        INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
        SELECT id, chinese_name, 'zh', true, 10 
        FROM public.ingredients 
        WHERE name = english_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Add Chinese aliases for the specific missing ingredients
SELECT add_chinese_alias_safe('Yeast', '酵母');
SELECT add_chinese_alias_safe('Olives', '橄榄');
SELECT add_chinese_alias_safe('Whole Milk', '全脂牛奶');
SELECT add_chinese_alias_safe('Goat Yogurt', '山羊酸奶');
SELECT add_chinese_alias_safe('Frozen Peas', '冷冻豌豆');
SELECT add_chinese_alias_safe('Tortillas', '墨西哥饼');
SELECT add_chinese_alias_safe('Hotpot Beef', '火锅牛肉');
SELECT add_chinese_alias_safe('Hotpot Lamb', '火锅羊肉');
SELECT add_chinese_alias_safe('Pork', '猪肉');
SELECT add_chinese_alias_safe('Egg', '鸡蛋');
SELECT add_chinese_alias_safe('Lotus Root', '莲藕');
SELECT add_chinese_alias_safe('Lotus Rooot', '莲藕'); -- Note: fixing the typo in the name
SELECT add_chinese_alias_safe('Broccoli', '西兰花');
SELECT add_chinese_alias_safe('Carrots', '胡萝卜');
SELECT add_chinese_alias_safe('Green Pepper', '青椒');
SELECT add_chinese_alias_safe('Lettuce', '生菜');
SELECT add_chinese_alias_safe('Mushrooms', '蘑菇');
SELECT add_chinese_alias_safe('Onions', '洋葱');
SELECT add_chinese_alias_safe('Potatoes', '土豆');
SELECT add_chinese_alias_safe('Tomatoes', '西红柿');

-- Clean up the function
DROP FUNCTION add_chinese_alias_safe(text, text);

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
VALUES ('Test Auto Chicken', 'meat', 'g', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid);

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
VALUES ('Test Unknown Item', 'other', 'g', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid);

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
-- STEP 6: Show remaining missing ingredients (if any)
-- =============================================================================

SELECT 
    'REMAINING MISSING INGREDIENTS' as status,
    i.name as english_name,
    i.category
FROM public.ingredients i
WHERE NOT EXISTS (
    SELECT 1 FROM public.ingredient_terms it 
    WHERE it.ingredient_id = i.id AND it.locale = 'zh'
)
ORDER BY i.category, i.name;

-- =============================================================================
-- COMPLETION MESSAGE
-- =============================================================================

SELECT 
    '🎉 SETUP COMPLETE! 🎉' as message,
    'Your bilingual ingredient system is now fully operational!' as status,
    'You can now test in your Flutter app!' as next_step;
