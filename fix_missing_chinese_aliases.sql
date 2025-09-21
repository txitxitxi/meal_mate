-- Fix missing Chinese aliases for ingredients with plural names
-- This adds Chinese aliases for ingredients that weren't matched due to name differences

-- Bell Peppers (plural) -> 青椒
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '青椒', 'zh', true, 10 FROM public.ingredients WHERE name = 'Bell Peppers' ON CONFLICT DO NOTHING;

-- Red Bell Peppers -> 红椒
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '红椒', 'zh', true, 10 FROM public.ingredients WHERE name = 'Red Bell Peppers' ON CONFLICT DO NOTHING;

-- Green Bell Peppers -> 青椒
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '青椒', 'zh', true, 10 FROM public.ingredients WHERE name = 'Green Bell Peppers' ON CONFLICT DO NOTHING;

-- Yellow Bell Peppers -> 黄椒
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '黄椒', 'zh', true, 10 FROM public.ingredients WHERE name = 'Yellow Bell Peppers' ON CONFLICT DO NOTHING;

-- Chicken Breast -> 鸡胸肉
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '鸡胸肉', 'zh', true, 10 FROM public.ingredients WHERE name = 'Chicken Breast' ON CONFLICT DO NOTHING;

-- Chicken Thighs -> 鸡腿肉
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '鸡腿肉', 'zh', true, 10 FROM public.ingredients WHERE name = 'Chicken Thighs' ON CONFLICT DO NOTHING;

-- Ground Chicken -> 鸡肉馅
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '鸡肉馅', 'zh', true, 10 FROM public.ingredients WHERE name = 'Ground Chicken' ON CONFLICT DO NOTHING;

-- Whole Chicken -> 整鸡
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '整鸡', 'zh', true, 10 FROM public.ingredients WHERE name = 'Whole Chicken' ON CONFLICT DO NOTHING;

-- Beef Steak -> 牛排
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '牛排', 'zh', true, 10 FROM public.ingredients WHERE name = 'Beef Steak' ON CONFLICT DO NOTHING;

-- Ground Beef -> 牛肉馅
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '牛肉馅', 'zh', true, 10 FROM public.ingredients WHERE name = 'Ground Beef' ON CONFLICT DO NOTHING;

-- Pork Chops -> 猪排
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '猪排', 'zh', true, 10 FROM public.ingredients WHERE name = 'Pork Chops' ON CONFLICT DO NOTHING;

-- Ground Pork -> 猪肉馅
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '猪肉馅', 'zh', true, 10 FROM public.ingredients WHERE name = 'Ground Pork' ON CONFLICT DO NOTHING;

-- Salmon Fillet -> 三文鱼片
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '三文鱼片', 'zh', true, 10 FROM public.ingredients WHERE name = 'Salmon Fillet' ON CONFLICT DO NOTHING;

-- Cod Fillet -> 鳕鱼片
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '鳕鱼片', 'zh', true, 10 FROM public.ingredients WHERE name = 'Cod Fillet' ON CONFLICT DO NOTHING;

-- Tuna Steak -> 金枪鱼排
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '金枪鱼排', 'zh', true, 10 FROM public.ingredients WHERE name = 'Tuna Steak' ON CONFLICT DO NOTHING;

-- Cherry Tomatoes -> 圣女果
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '圣女果', 'zh', true, 10 FROM public.ingredients WHERE name = 'Cherry Tomatoes' ON CONFLICT DO NOTHING;

-- Roma Tomatoes -> 罗马番茄
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '罗马番茄', 'zh', true, 10 FROM public.ingredients WHERE name = 'Roma Tomatoes' ON CONFLICT DO NOTHING;

-- Sweet Potatoes -> 红薯
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '红薯', 'zh', true, 10 FROM public.ingredients WHERE name = 'Sweet Potatoes' ON CONFLICT DO NOTHING;

-- Russet Potatoes -> 褐色土豆
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '褐色土豆', 'zh', true, 10 FROM public.ingredients WHERE name = 'Russet Potatoes' ON CONFLICT DO NOTHING;

-- Red Potatoes -> 红土豆
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '红土豆', 'zh', true, 10 FROM public.ingredients WHERE name = 'Red Potatoes' ON CONFLICT DO NOTHING;

-- Yukon Gold Potatoes -> 黄金土豆
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '黄金土豆', 'zh', true, 10 FROM public.ingredients WHERE name = 'Yukon Gold Potatoes' ON CONFLICT DO NOTHING;

-- White Mushrooms -> 白蘑菇
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '白蘑菇', 'zh', true, 10 FROM public.ingredients WHERE name = 'White Mushrooms' ON CONFLICT DO NOTHING;

-- Portobello Mushrooms -> 大蘑菇
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '大蘑菇', 'zh', true, 10 FROM public.ingredients WHERE name = 'Portobello Mushrooms' ON CONFLICT DO NOTHING;

-- Shiitake Mushrooms -> 香菇
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '香菇', 'zh', true, 10 FROM public.ingredients WHERE name = 'Shiitake Mushrooms' ON CONFLICT DO NOTHING;

-- Butternut Squash -> 南瓜
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '南瓜', 'zh', true, 10 FROM public.ingredients WHERE name = 'Butternut Squash' ON CONFLICT DO NOTHING;

-- Green Beans -> 青豆
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '青豆', 'zh', true, 10 FROM public.ingredients WHERE name = 'Green Beans' ON CONFLICT DO NOTHING;

-- Snow Peas -> 荷兰豆
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '荷兰豆', 'zh', true, 10 FROM public.ingredients WHERE name = 'Snow Peas' ON CONFLICT DO NOTHING;

-- Show what we just added
SELECT 
  i.name as english_name,
  it.term as chinese_name,
  it.locale
FROM public.ingredients i 
JOIN public.ingredient_terms it ON i.id = it.ingredient_id 
WHERE it.locale = 'zh' AND it.term IN ('青椒', '红椒', '黄椒', '鸡胸肉', '鸡腿肉', '牛肉馅', '猪排', '三文鱼片', '圣女果', '红薯')
ORDER BY i.name;
