-- Add English term for "Beef Ribs" in ingredient_terms table

-- 1. Find the Beef Ribs ingredient ID
SELECT 
    'BEEF RIBS INGREDIENT ID' as check_type,
    i.id,
    i.name
FROM public.ingredients i
WHERE i.name = 'Beef Ribs';

-- 2. Check if it already has an English term
SELECT 
    'EXISTING ENGLISH TERMS' as check_type,
    it.term,
    it.locale,
    it.is_primary
FROM public.ingredient_terms it
JOIN public.ingredients i ON it.ingredient_id = i.id
WHERE i.name = 'Beef Ribs' AND it.locale = 'en';

-- 3. Add English term for Beef Ribs if it doesn't exist
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT 
    i.id,
    'Beef Ribs' as term,
    'en' as locale,
    true as is_primary,
    100 as weight
FROM public.ingredients i
WHERE i.name = 'Beef Ribs'
AND NOT EXISTS (
    SELECT 1 FROM public.ingredient_terms it2 
    WHERE it2.ingredient_id = i.id 
    AND it2.locale = 'en' 
    AND it2.term = 'Beef Ribs'
);

-- 4. Verify the addition
SELECT 
    'VERIFICATION - ALL TERMS FOR BEEF RIBS' as check_type,
    it.term,
    it.locale,
    it.is_primary,
    it.weight,
    i.name as ingredient_name
FROM public.ingredient_terms it
JOIN public.ingredients i ON it.ingredient_id = i.id
WHERE i.name = 'Beef Ribs'
ORDER BY it.locale, it.is_primary DESC, it.weight DESC;

-- 5. Test the search functionality
SELECT 
    'SEARCH TEST - BEEF' as check_type,
    it.term,
    it.locale,
    it.is_primary,
    i.name as ingredient_name
FROM public.ingredient_terms it
JOIN public.ingredients i ON it.ingredient_id = i.id
WHERE it.term ILIKE '%beef%' OR it.term_norm ILIKE '%beef%'
ORDER BY it.is_primary DESC, it.weight DESC;

SELECT 
    'SEARCH TEST - RIBS' as check_type,
    it.term,
    it.locale,
    it.is_primary,
    i.name as ingredient_name
FROM public.ingredient_terms it
JOIN public.ingredients i ON it.ingredient_id = i.id
WHERE it.term ILIKE '%ribs%' OR it.term_norm ILIKE '%ribs%'
ORDER BY it.is_primary DESC, it.weight DESC;
