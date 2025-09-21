-- Debug why store search can't find "Beef Ribs"

-- 1. Check if "Beef Ribs" ingredient exists
SELECT 
    'BEEF RIBS INGREDIENT CHECK' as check_type,
    i.id,
    i.name as english_name,
    i.category,
    i.created_at
FROM public.ingredients i
WHERE i.name ILIKE '%beef ribs%' OR i.name ILIKE '%beef%ribs%'
ORDER BY i.created_at DESC;

-- 2. Check if "Beef Ribs" has Chinese aliases
SELECT 
    'BEEF RIBS CHINESE ALIAS CHECK' as check_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name ILIKE '%beef ribs%' OR i.name ILIKE '%beef%ribs%'
ORDER BY i.created_at DESC;

-- 3. Check if "Beef Ribs" is in any store's inventory
SELECT 
    'BEEF RIBS STORE INVENTORY CHECK' as check_type,
    i.name as ingredient_name,
    s.name as store_name,
    si.id as store_item_id,
    si.created_at
FROM public.ingredients i
LEFT JOIN public.store_items si ON i.id = si.ingredient_id
LEFT JOIN public.stores s ON si.store_id = s.id
WHERE i.name ILIKE '%beef ribs%' OR i.name ILIKE '%beef%ribs%'
ORDER BY si.created_at DESC;

-- 4. Check all stores and their ingredients
SELECT 
    'ALL STORE INVENTORIES' as check_type,
    s.name as store_name,
    i.name as ingredient_name,
    si.created_at
FROM public.stores s
LEFT JOIN public.store_items si ON s.id = si.store_id
LEFT JOIN public.ingredients i ON si.ingredient_id = i.id
WHERE s.user_id = '90e7c0dc-fe3c-4882-aa40-0e31261775cf'
ORDER BY s.priority, i.name;

-- 5. Check which ingredients are in recipes but not in stores
SELECT 
    'INGREDIENTS IN RECIPES BUT NOT IN STORES' as check_type,
    i.name as ingredient_name,
    COUNT(ri.recipe_id) as recipe_count,
    CASE 
        WHEN si.id IS NOT NULL THEN 'IN STORES'
        ELSE 'NOT IN STORES'
    END as store_status
FROM public.ingredients i
JOIN public.recipe_ingredients ri ON i.id = ri.ingredient_id
LEFT JOIN public.store_items si ON i.id = si.ingredient_id
GROUP BY i.id, i.name, si.id
HAVING si.id IS NULL
ORDER BY recipe_count DESC, i.name
LIMIT 10;

-- 6. Summary of the issue
SELECT 
    'SEARCH ISSUE SUMMARY' as check_type,
    'Beef Ribs exists in recipes but not in any store inventory' as issue,
    'Store search only finds ingredients that are actually stocked in stores' as explanation,
    'Solution: Add Beef Ribs to at least one store inventory' as solution;
