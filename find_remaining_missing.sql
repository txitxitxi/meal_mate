-- Find the remaining 52 ingredients that still need Chinese aliases

-- Show the specific ingredients that are missing Chinese aliases
SELECT 
    i.id,
    i.name,
    i.category,
    i.default_unit
FROM public.ingredients i
WHERE NOT EXISTS (
    SELECT 1 FROM public.ingredient_terms it 
    WHERE it.ingredient_id = i.id 
    AND it.locale = 'zh'
)
ORDER BY i.category, i.name;

-- Count by category
SELECT 
    i.category,
    COUNT(*) as missing_count
FROM public.ingredients i
WHERE NOT EXISTS (
    SELECT 1 FROM public.ingredient_terms it 
    WHERE it.ingredient_id = i.id 
    AND it.locale = 'zh'
)
GROUP BY i.category
ORDER BY missing_count DESC;

-- Show summary
SELECT 
    'REMAINING MISSING' as report_type,
    COUNT(*) as total_missing,
    COUNT(DISTINCT i.category) as categories_affected
FROM public.ingredients i
WHERE NOT EXISTS (
    SELECT 1 FROM public.ingredient_terms it 
    WHERE it.ingredient_id = i.id 
    AND it.locale = 'zh'
);
