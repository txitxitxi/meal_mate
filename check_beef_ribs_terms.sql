-- Check if "Beef Ribs" has entries in ingredient_terms table

-- 1. Find the Beef Ribs ingredient
SELECT 
    'BEEF RIBS INGREDIENT' as check_type,
    i.id,
    i.name,
    i.category,
    i.created_at
FROM public.ingredients i
WHERE i.name = 'Beef Ribs';

-- 2. Check if it has any entries in ingredient_terms
SELECT 
    'BEEF RIBS TERMS' as check_type,
    it.id,
    it.term,
    it.locale,
    it.is_primary,
    it.weight,
    it.created_at
FROM public.ingredient_terms it
JOIN public.ingredients i ON it.ingredient_id = i.id
WHERE i.name = 'Beef Ribs'
ORDER BY it.is_primary DESC, it.weight DESC;

-- 3. Check what happens when we search for "beef" in ingredient_terms
SELECT 
    'SEARCH BEEF IN TERMS' as check_type,
    it.term,
    it.locale,
    it.is_primary,
    i.name as ingredient_name,
    i.category
FROM public.ingredient_terms it
JOIN public.ingredients i ON it.ingredient_id = i.id
WHERE it.term ILIKE '%beef%' OR it.term_norm ILIKE '%beef%'
ORDER BY it.is_primary DESC, it.weight DESC
LIMIT 10;

-- 4. Check what happens when we search for "ribs" in ingredient_terms
SELECT 
    'SEARCH RIBS IN TERMS' as check_type,
    it.term,
    it.locale,
    it.is_primary,
    i.name as ingredient_name,
    i.category
FROM public.ingredient_terms it
JOIN public.ingredients i ON it.ingredient_id = i.id
WHERE it.term ILIKE '%ribs%' OR it.term_norm ILIKE '%ribs%'
ORDER BY it.is_primary DESC, it.weight DESC
LIMIT 10;

-- 5. Check how many ingredients have terms vs don't have terms
SELECT 
    'INGREDIENTS WITH/WITHOUT TERMS' as check_type,
    COUNT(DISTINCT i.id) as total_ingredients,
    COUNT(DISTINCT it.ingredient_id) as ingredients_with_terms,
    COUNT(DISTINCT i.id) - COUNT(DISTINCT it.ingredient_id) as ingredients_without_terms
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id;
