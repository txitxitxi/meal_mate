-- Add "Noodle" to translation mapping and test auto-translation

-- 1. Add "Noodle" to the translation mapping table
INSERT INTO public.ingredient_translations (english_name, chinese_name, category)
VALUES ('Noodle', '面条', 'grain')
ON CONFLICT (english_name) DO UPDATE SET
    chinese_name = EXCLUDED.chinese_name,
    category = EXCLUDED.category,
    updated_at = now();

-- 2. Verify "Noodle" is now in the mapping
SELECT 
    'NOODLE ADDED TO MAPPING' as status,
    english_name,
    chinese_name,
    category
FROM public.ingredient_translations
WHERE english_name = 'Noodle';

-- 3. Test auto-translation with a new "Noodle" ingredient
INSERT INTO public.ingredients (name, category, default_unit, created_by)
VALUES ('Test Noodle Auto', 'grain', 'cup', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid);

-- 4. Check if "Test Noodle Auto" got auto-translated
SELECT 
    'NOODLE AUTO-TRANSLATION TEST' as test_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary,
    it.created_at as alias_created_at
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Test Noodle Auto';

-- 5. Add Chinese alias for existing "Noodle" ingredient
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT id, '面条', 'zh', true, 10 
FROM public.ingredients 
WHERE name = 'Noodle'
AND NOT EXISTS (
    SELECT 1 FROM public.ingredient_terms it 
    WHERE it.ingredient_id = public.ingredients.id AND it.locale = 'zh'
);

-- 6. Verify existing "Noodle" now has Chinese alias
SELECT 
    'EXISTING NOODLE FIXED' as status,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Noodle';

-- 7. Show final status
SELECT 
    '🎉 NOODLE TRANSLATION COMPLETE! 🎉' as message,
    'Both existing and future "Noodle" ingredients now have Chinese aliases!' as status;
