-- Find English ingredients that don't have Chinese aliases
-- This will help you identify which ingredients need Chinese translations

-- Method 1: Ingredients with no Chinese aliases at all
SELECT 
  'Ingredients with NO Chinese aliases' as category,
  COUNT(*) as count
FROM public.ingredients i
WHERE NOT EXISTS (
  SELECT 1 FROM public.ingredient_terms it 
  WHERE it.ingredient_id = i.id 
  AND it.locale = 'zh'
);

-- Method 2: Show the actual ingredients missing Chinese aliases
SELECT 
  i.name as english_name,
  i.category,
  i.default_unit,
  'Missing Chinese alias' as status
FROM public.ingredients i
WHERE NOT EXISTS (
  SELECT 1 FROM public.ingredient_terms it 
  WHERE it.ingredient_id = i.id 
  AND it.locale = 'zh'
)
ORDER BY i.category, i.name;

-- Method 3: Group by category to see which categories need the most work
SELECT 
  i.category,
  COUNT(*) as ingredients_without_chinese,
  string_agg(i.name, ', ' ORDER BY i.name) as missing_ingredients
FROM public.ingredients i
WHERE NOT EXISTS (
  SELECT 1 FROM public.ingredient_terms it 
  WHERE it.ingredient_id = i.id 
  AND it.locale = 'zh'
)
GROUP BY i.category
ORDER BY ingredients_without_chinese DESC;

-- Method 4: Show ingredients that DO have Chinese aliases (for comparison)
SELECT 
  'Ingredients WITH Chinese aliases' as category,
  COUNT(DISTINCT i.id) as count
FROM public.ingredients i
WHERE EXISTS (
  SELECT 1 FROM public.ingredient_terms it 
  WHERE it.ingredient_id = i.id 
  AND it.locale = 'zh'
);

-- Method 5: Show all Chinese aliases we currently have
SELECT 
  i.name as english_name,
  it.term as chinese_name,
  it.locale,
  i.category
FROM public.ingredients i
JOIN public.ingredient_terms it ON i.id = it.ingredient_id
WHERE it.locale = 'zh'
ORDER BY i.category, i.name;

-- Method 6: Summary statistics
SELECT 
  'SUMMARY' as report_type,
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
