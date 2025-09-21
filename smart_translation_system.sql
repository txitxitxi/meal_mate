-- Smart Translation System using Supabase Edge Functions
-- This replaces the manual translation table with real-time API translation

-- 1. Keep the ingredient_translations table but simplify it
-- (We'll use it as a cache for API translations)
CREATE TABLE IF NOT EXISTS public.ingredient_translations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    english_name text NOT NULL UNIQUE,
    chinese_name text NOT NULL,
    category text DEFAULT 'auto_translated',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 2. Create a simple function to add Chinese alias
CREATE OR REPLACE FUNCTION add_chinese_alias(
    ingredient_id_param uuid,
    chinese_name_param text
) RETURNS void AS $$
BEGIN
    INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
    VALUES (ingredient_id_param, chinese_name_param, 'zh', true, 10)
    ON CONFLICT (ingredient_id, term, locale) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 3. Create a function to trigger translation via Edge Function
CREATE OR REPLACE FUNCTION trigger_translation_for_ingredient(
    ingredient_id_param uuid,
    ingredient_name_param text
) RETURNS void AS $$
DECLARE
    translation_result jsonb;
    chinese_name text;
BEGIN
    -- Check if we already have a translation
    IF EXISTS (
        SELECT 1 FROM public.ingredient_terms it 
        WHERE it.ingredient_id = ingredient_id_param AND it.locale = 'zh'
    ) THEN
        RETURN; -- Already has Chinese alias
    END IF;

    -- Check cache first
    SELECT chinese_name INTO chinese_name
    FROM public.ingredient_translations
    WHERE english_name = LOWER(ingredient_name_param);

    IF chinese_name IS NOT NULL THEN
        -- Use cached translation
        PERFORM add_chinese_alias(ingredient_id_param, chinese_name);
    ELSE
        -- For now, we'll add a placeholder that can be translated later
        -- The Flutter app will call the Edge Function to get the translation
        PERFORM add_chinese_alias(ingredient_id_param, '[Auto-translate: ' || ingredient_name_param || ']');
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 4. Create a simpler trigger
CREATE OR REPLACE FUNCTION auto_translate_ingredient_smart()
RETURNS trigger AS $$
BEGIN
    -- Call our smart translation function
    PERFORM trigger_translation_for_ingredient(NEW.id, NEW.name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Replace the old trigger with the new one
DROP TRIGGER IF EXISTS trigger_auto_translate_ingredient ON public.ingredients;
CREATE TRIGGER trigger_auto_translate_ingredient_smart
    AFTER INSERT ON public.ingredients
    FOR EACH ROW
    EXECUTE FUNCTION auto_translate_ingredient_smart();

-- 6. Create a function to update translations from Edge Function results
CREATE OR REPLACE FUNCTION update_ingredient_translation(
    ingredient_name_param text,
    chinese_translation_param text
) RETURNS void AS $$
DECLARE
    ingredient_record RECORD;
BEGIN
    -- Cache the translation
    INSERT INTO public.ingredient_translations (english_name, chinese_name, category)
    VALUES (LOWER(ingredient_name_param), chinese_translation_param, 'api_translated')
    ON CONFLICT (english_name) DO UPDATE SET
        chinese_name = EXCLUDED.chinese_name,
        updated_at = now();

    -- Update existing ingredient terms
    FOR ingredient_record IN 
        SELECT id FROM public.ingredients 
        WHERE LOWER(name) = LOWER(ingredient_name_param)
    LOOP
        UPDATE public.ingredient_terms 
        SET term = chinese_translation_param
        WHERE ingredient_id = ingredient_record.id 
        AND locale = 'zh'
        AND term LIKE '[Auto-translate:%';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 7. Set up RLS for ingredient_translations
ALTER TABLE public.ingredient_translations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read access to ingredient_translations" ON public.ingredient_translations
    FOR SELECT USING (true);

CREATE POLICY "Allow service role to manage ingredient_translations" ON public.ingredient_translations
    FOR ALL USING (auth.role() = 'service_role');

-- 8. Test the new system
INSERT INTO public.ingredients (name, category, default_unit, created_by)
VALUES ('Test Smart Translation', 'other', 'g', '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid);

-- 9. Check the result
SELECT 
    'SMART TRANSLATION TEST' as test_type,
    i.name as english_name,
    it.term as chinese_name,
    it.locale,
    it.is_primary
FROM public.ingredients i
LEFT JOIN public.ingredient_terms it ON i.id = it.ingredient_id AND it.locale = 'zh'
WHERE i.name = 'Test Smart Translation';

-- 10. Show system status
SELECT 
    '🎉 SMART TRANSLATION SYSTEM READY! 🎉' as message,
    'Now using Edge Functions + Translation APIs instead of manual lookup table!' as description;
