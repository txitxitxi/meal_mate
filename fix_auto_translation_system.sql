-- Fix the auto-translation system to add BOTH English and Chinese terms

-- 1. First, let's see the current trigger function
SELECT 
    'CURRENT TRIGGER FUNCTION' as check_type,
    proname as function_name,
    prosrc as function_source
FROM pg_proc 
WHERE proname = 'auto_translate_ingredient_edge_function';

-- 2. Drop the existing trigger function and recreate it properly
DROP FUNCTION IF EXISTS public.auto_translate_ingredient_edge_function();

-- 3. Create a new trigger function that adds BOTH English and Chinese terms
CREATE OR REPLACE FUNCTION public.auto_translate_ingredient_edge_function()
RETURNS TRIGGER AS $$
DECLARE
    translation_result JSONB;
    chinese_term TEXT;
BEGIN
    -- Call the Edge Function to get translation
    SELECT net.http_post(
        url := 'https://your-project-ref.supabase.co/functions/v1/translate-ingredient',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.settings.service_role_key') || '"}'::jsonb,
        body := ('{"ingredient_name": "' || NEW.name || '"}')::jsonb
    ) INTO translation_result;
    
    -- Extract the Chinese translation from the response
    chinese_term := translation_result->>'chinese_term';
    
    -- If we got a valid translation, add both English and Chinese terms
    IF chinese_term IS NOT NULL AND chinese_term != '' AND chinese_term != NEW.name THEN
        -- Add the English term (original ingredient name)
        INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
        VALUES (NEW.id, NEW.name, 'en', true, 100)
        ON CONFLICT (ingredient_id, term, locale) DO NOTHING;
        
        -- Add the Chinese translation
        INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
        VALUES (NEW.id, chinese_term, 'zh', false, 50)
        ON CONFLICT (ingredient_id, term, locale) DO NOTHING;
        
        -- Update the translation cache
        INSERT INTO public.ingredient_translation_cache (english_term, chinese_term)
        VALUES (NEW.name, chinese_term)
        ON CONFLICT (english_term) DO UPDATE SET 
            chinese_term = EXCLUDED.chinese_term,
            updated_at = NOW();
            
        RAISE NOTICE 'Added both English and Chinese terms for ingredient: % -> %', NEW.name, chinese_term;
    ELSE
        -- If translation failed, at least add the English term
        INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
        VALUES (NEW.id, NEW.name, 'en', true, 100)
        ON CONFLICT (ingredient_id, term, locale) DO NOTHING;
        
        RAISE NOTICE 'Added English term only for ingredient: %', NEW.name;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Recreate the trigger
DROP TRIGGER IF EXISTS trigger_auto_translate_ingredient_edge_function ON public.ingredients;
CREATE TRIGGER trigger_auto_translate_ingredient_edge_function
    AFTER INSERT ON public.ingredients
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_translate_ingredient_edge_function();

-- 5. Let's also create a function to backfill existing ingredients that are missing English terms
CREATE OR REPLACE FUNCTION public.backfill_english_terms()
RETURNS TABLE(
    result_ingredient_id UUID,
    result_ingredient_name TEXT,
    result_terms_added INTEGER
) AS $$
DECLARE
    ingredient_record RECORD;
    terms_count INTEGER;
BEGIN
    FOR ingredient_record IN 
        SELECT i.id, i.name
        FROM public.ingredients i
        WHERE NOT EXISTS (
            SELECT 1 FROM public.ingredient_terms it 
            WHERE it.ingredient_id = i.id AND it.locale = 'en'
        )
    LOOP
        -- Add English term for this ingredient
        INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
        VALUES (ingredient_record.id, ingredient_record.name, 'en', true, 100)
        ON CONFLICT (ingredient_id, term, locale) DO NOTHING;
        
        GET DIAGNOSTICS terms_count = ROW_COUNT;
        
        result_ingredient_id := ingredient_record.id;
        result_ingredient_name := ingredient_record.name;
        result_terms_added := terms_count;
        
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 6. Run the backfill function to fix existing ingredients
SELECT 
    'BACKFILL RESULTS' as check_type,
    result_ingredient_name,
    result_terms_added
FROM public.backfill_english_terms();

-- 7. Verify the results
SELECT 
    'VERIFICATION - INGREDIENTS WITH/WITHOUT ENGLISH TERMS' as check_type,
    COUNT(DISTINCT i.id) as total_ingredients,
    COUNT(DISTINCT CASE WHEN it.locale = 'en' THEN it.ingredient_id END) as ingredients_with_english_terms,
    COUNT(DISTINCT i.id) - COUNT(DISTINCT CASE WHEN it.locale = 'en' THEN it.ingredient_id END) as ingredients_without_english_terms
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id;

-- 8. Test with Beef Ribs specifically
SELECT 
    'BEEF RIBS VERIFICATION' as check_type,
    it.term,
    it.locale,
    it.is_primary,
    it.weight,
    i.name as ingredient_name
FROM public.ingredient_terms it
JOIN public.ingredients i ON it.ingredient_id = i.id
WHERE i.name = 'Beef Ribs'
ORDER BY it.locale, it.is_primary DESC, it.weight DESC;

-- 9. Clean up the backfill function (optional)
DROP FUNCTION IF EXISTS public.backfill_english_terms();
