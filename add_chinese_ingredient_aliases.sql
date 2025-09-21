-- Add Chinese aliases for common ingredients
-- Run this after the main migration to add Chinese translations

-- Common ingredient translations from English to Chinese
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '牛肉', 'zh', true, 10 FROM public.ingredients WHERE name = 'Beef' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '鸡肉', 'zh', true, 10 FROM public.ingredients WHERE name = 'Chicken' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '猪肉', 'zh', true, 10 FROM public.ingredients WHERE name = 'Pork' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '羊肉', 'zh', true, 10 FROM public.ingredients WHERE name = 'Lamb' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '鱼', 'zh', true, 10 FROM public.ingredients WHERE name = 'Fish' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '虾', 'zh', true, 10 FROM public.ingredients WHERE name = 'Shrimp' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '鸡蛋', 'zh', true, 10 FROM public.ingredients WHERE name = 'Eggs' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '牛奶', 'zh', true, 10 FROM public.ingredients WHERE name = 'Milk' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '奶酪', 'zh', true, 10 FROM public.ingredients WHERE name = 'Cheese' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '黄油', 'zh', true, 10 FROM public.ingredients WHERE name = 'Butter' ON CONFLICT DO NOTHING;

-- Vegetables
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '土豆', 'zh', true, 10 FROM public.ingredients WHERE name = 'Potato' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '西红柿', 'zh', true, 10 FROM public.ingredients WHERE name = 'Tomato' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '洋葱', 'zh', true, 10 FROM public.ingredients WHERE name = 'Onion' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '胡萝卜', 'zh', true, 10 FROM public.ingredients WHERE name = 'Carrot' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '芹菜', 'zh', true, 10 FROM public.ingredients WHERE name = 'Celery' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '菠菜', 'zh', true, 10 FROM public.ingredients WHERE name = 'Spinach' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '白菜', 'zh', true, 10 FROM public.ingredients WHERE name = 'Cabbage' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '蘑菇', 'zh', true, 10 FROM public.ingredients WHERE name = 'Mushroom' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '青椒', 'zh', true, 10 FROM public.ingredients WHERE name = 'Bell Pepper' ON CONFLICT DO NOTHING;

-- Grains and Starches
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '米饭', 'zh', true, 10 FROM public.ingredients WHERE name = 'Rice' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '面条', 'zh', true, 10 FROM public.ingredients WHERE name = 'Pasta' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '面包', 'zh', true, 10 FROM public.ingredients WHERE name = 'Bread' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '面粉', 'zh', true, 10 FROM public.ingredients WHERE name = 'Flour' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '燕麦', 'zh', true, 10 FROM public.ingredients WHERE name = 'Oats' ON CONFLICT DO NOTHING;

-- Fruits
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '苹果', 'zh', true, 10 FROM public.ingredients WHERE name = 'Apple' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '香蕉', 'zh', true, 10 FROM public.ingredients WHERE name = 'Banana' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '橙子', 'zh', true, 10 FROM public.ingredients WHERE name = 'Orange' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '柠檬', 'zh', true, 10 FROM public.ingredients WHERE name = 'Lemon' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '草莓', 'zh', true, 10 FROM public.ingredients WHERE name = 'Strawberry' ON CONFLICT DO NOTHING;

-- Herbs and Spices
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '大蒜', 'zh', true, 10 FROM public.ingredients WHERE name = 'Garlic' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '姜', 'zh', true, 10 FROM public.ingredients WHERE name = 'Ginger' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '盐', 'zh', true, 10 FROM public.ingredients WHERE name = 'Salt' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '胡椒', 'zh', true, 10 FROM public.ingredients WHERE name = 'Pepper' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '糖', 'zh', true, 10 FROM public.ingredients WHERE name = 'Sugar' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '油', 'zh', true, 10 FROM public.ingredients WHERE name = 'Oil' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '橄榄油', 'zh', true, 10 FROM public.ingredients WHERE name = 'Olive Oil' ON CONFLICT DO NOTHING;

-- Legumes and Nuts
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '豆子', 'zh', true, 10 FROM public.ingredients WHERE name = 'Beans' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '豆腐', 'zh', true, 10 FROM public.ingredients WHERE name = 'Tofu' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '花生', 'zh', true, 10 FROM public.ingredients WHERE name = 'Peanut' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '杏仁', 'zh', true, 10 FROM public.ingredients WHERE name = 'Almond' ON CONFLICT DO NOTHING;

-- Additional common ingredients
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '冰淇淋', 'zh', true, 10 FROM public.ingredients WHERE name = 'Ice Cream' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '酸奶', 'zh', true, 10 FROM public.ingredients WHERE name = 'Yogurt' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '蜂蜜', 'zh', true, 10 FROM public.ingredients WHERE name = 'Honey' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '醋', 'zh', true, 10 FROM public.ingredients WHERE name = 'Vinegar' ON CONFLICT DO NOTHING;

INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '酱油', 'zh', true, 10 FROM public.ingredients WHERE name = 'Soy Sauce' ON CONFLICT DO NOTHING;

-- Test query to see what Chinese aliases were added
SELECT 
  i.name as english_name,
  it.term as chinese_name,
  it.locale,
  it.is_primary
FROM public.ingredients i 
JOIN public.ingredient_terms it ON i.id = it.ingredient_id 
WHERE it.locale = 'zh'
ORDER BY i.name;
