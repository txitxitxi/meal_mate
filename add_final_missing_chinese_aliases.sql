-- Add Chinese aliases for the final 20 missing ingredients
-- These are the specific ingredients that still don't have Chinese translations

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

-- Baking ingredients
SELECT add_chinese_alias_if_missing('Yeast', '酵母');

-- Canned ingredients
SELECT add_chinese_alias_if_missing('Olives', '橄榄');

-- Dairy ingredients
SELECT add_chinese_alias_if_missing('Whole Milk', '全脂牛奶');
SELECT add_chinese_alias_if_missing('Goat Yogurt', '山羊酸奶');

-- Frozen ingredients
SELECT add_chinese_alias_if_missing('Frozen Peas', '冷冻豌豆');

-- Grain ingredients
SELECT add_chinese_alias_if_missing('Tortillas', '墨西哥饼');

-- Meat ingredients
SELECT add_chinese_alias_if_missing('Hotpot Beef', '火锅牛肉');
SELECT add_chinese_alias_if_missing('Hotpot Lamb', '火锅羊肉');
SELECT add_chinese_alias_if_missing('Pork', '猪肉');

-- Other ingredients
SELECT add_chinese_alias_if_missing('Egg', '鸡蛋');
SELECT add_chinese_alias_if_missing('Lotus Root', '莲藕');
SELECT add_chinese_alias_if_missing('Lotus Rooot', '莲藕'); -- Note: fixing the typo in the name

-- Vegetable ingredients
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

-- Show final results
SELECT 
    'FINAL COMPLETE SUMMARY' as report_type,
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

-- Show the specific ingredients that were just added
SELECT 
    'JUST ADDED' as status,
    i.name as english_name,
    it.term as chinese_name,
    i.category
FROM public.ingredients i
JOIN public.ingredient_terms it ON i.id = it.ingredient_id
WHERE it.locale = 'zh'
AND i.name IN (
    'Yeast', 'Olives', 'Whole Milk', 'Goat Yogurt', 'Frozen Peas', 'Tortillas',
    'Hotpot Beef', 'Hotpot Lamb', 'Pork', 'Egg', 'Lotus Root', 'Lotus Rooot',
    'Broccoli', 'Carrots', 'Green Pepper', 'Lettuce', 'Mushrooms', 'Onions', 
    'Potatoes', 'Tomatoes'
)
ORDER BY i.category, i.name;
