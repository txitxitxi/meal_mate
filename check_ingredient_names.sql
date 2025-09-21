-- Check what ingredients actually exist in the database

-- 1. Search for any ingredient containing "beef"
SELECT 
    'BEEF INGREDIENTS' as check_type,
    i.id,
    i.name as english_name,
    i.category,
    i.created_at
FROM public.ingredients i
WHERE i.name ILIKE '%beef%'
ORDER BY i.created_at DESC;

-- 2. Search for any ingredient containing "ribs"
SELECT 
    'RIBS INGREDIENTS' as check_type,
    i.id,
    i.name as english_name,
    i.category,
    i.created_at
FROM public.ingredients i
WHERE i.name ILIKE '%ribs%'
ORDER BY i.created_at DESC;

-- 3. Check recent ingredients (last 20)
SELECT 
    'RECENT INGREDIENTS' as check_type,
    i.id,
    i.name as english_name,
    i.category,
    i.created_at
FROM public.ingredients i
ORDER BY i.created_at DESC
LIMIT 20;

-- 4. Check if there are any ingredients with similar names
SELECT 
    'SIMILAR NAMES' as check_type,
    i.name as english_name,
    i.category,
    i.created_at
FROM public.ingredients i
WHERE i.name ILIKE '%beef%' OR i.name ILIKE '%rib%' OR i.name ILIKE '%cow%' OR i.name ILIKE '%ox%'
ORDER BY i.name;

-- 5. Check all ingredients with Chinese aliases containing beef-related terms
SELECT 
    'CHINESE BEEF ALIASES' as check_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    i.created_at
FROM public.ingredients i
JOIN public.ingredient_terms it ON i.id = it.ingredient_id
WHERE it.locale = 'zh' 
AND (it.term ILIKE '%牛%' OR it.term ILIKE '%肉%')
ORDER BY i.created_at DESC;

-- 6. Check if "Beef Ribs" exists with exact match
SELECT 
    'EXACT BEEF RIBS CHECK' as check_type,
    i.id,
    i.name as english_name,
    i.category,
    i.created_at
FROM public.ingredients i
WHERE i.name = 'Beef Ribs';

-- 7. Check case variations
SELECT 
    'CASE VARIATIONS' as check_type,
    i.id,
    i.name as english_name,
    i.category,
    i.created_at
FROM public.ingredients i
WHERE LOWER(i.name) = LOWER('Beef Ribs') OR i.name ILIKE '%beef%ribs%';
