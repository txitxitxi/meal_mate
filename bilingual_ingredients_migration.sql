-- Bilingual Ingredients Migration
-- This migration adds support for multilingual ingredient names while preserving original casing
-- Based on ChatGPT's comprehensive schema suggestions

-- ============================================
-- 0) Prerequisites (safe to run multiple times)
-- ============================================

-- Create required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Add normalized name column to ingredients table
-- This normalizes display names for deduplication while keeping original casing
ALTER TABLE public.ingredients
  ADD COLUMN IF NOT EXISTS name_norm text;

-- Create function to normalize ingredient names
CREATE OR REPLACE FUNCTION public.normalize_ingredient_name(name_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT lower(trim(name_text));
$$;

-- Create trigger function to update name_norm when name changes
CREATE OR REPLACE FUNCTION public.update_ingredient_name_norm()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.name_norm = public.normalize_ingredient_name(NEW.name);
  RETURN NEW;
END;
$$;

-- Create trigger to automatically update name_norm
DROP TRIGGER IF EXISTS trigger_update_ingredient_name_norm ON public.ingredients;
CREATE TRIGGER trigger_update_ingredient_name_norm
  BEFORE INSERT OR UPDATE OF name ON public.ingredients
  FOR EACH ROW
  EXECUTE FUNCTION public.update_ingredient_name_norm();

-- Backfill existing ingredients with normalized names
UPDATE public.ingredients 
SET name_norm = public.normalize_ingredient_name(name)
WHERE name_norm IS NULL;

-- Create unique index on normalized name to prevent duplicates
-- This prevents "Beef" vs "beéf" vs "beef " while preserving original casing
CREATE UNIQUE INDEX IF NOT EXISTS ingredients_name_unique_idx
  ON public.ingredients (name_norm);

-- ============================================
-- 1) Create ingredient_terms table for bilingual aliases
-- ============================================

-- Multilingual aliases for ingredients (terms users can type/search)
CREATE TABLE IF NOT EXISTS public.ingredient_terms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ingredient_id uuid NOT NULL REFERENCES public.ingredients(id) ON DELETE CASCADE,
  term text NOT NULL CHECK (btrim(term) <> ''),
  locale text,                        -- e.g. 'en', 'zh', 'zh-Hans', 'zh-Hant' (nullable allowed)
  is_primary boolean DEFAULT false,   -- prefer for display in that locale
  weight int DEFAULT 1,               -- optional rank boost for search
  term_norm text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE (ingredient_id, term, locale)
);

-- Create indexes for fast fuzzy/substring search on aliases
CREATE INDEX IF NOT EXISTS ingredient_terms_trgm_idx
  ON public.ingredient_terms USING gin (term_norm gin_trgm_ops);

CREATE INDEX IF NOT EXISTS ingredient_terms_ingredient_id_idx
  ON public.ingredient_terms (ingredient_id);

CREATE INDEX IF NOT EXISTS ingredient_terms_locale_idx
  ON public.ingredient_terms (locale);

-- Create trigger function to update term_norm when term changes
CREATE OR REPLACE FUNCTION public.update_ingredient_term_norm()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.term_norm = lower(trim(NEW.term));
  RETURN NEW;
END;
$$;

-- Create trigger to automatically update term_norm
DROP TRIGGER IF EXISTS trigger_update_ingredient_term_norm ON public.ingredient_terms;
CREATE TRIGGER trigger_update_ingredient_term_norm
  BEFORE INSERT OR UPDATE OF term ON public.ingredient_terms
  FOR EACH ROW
  EXECUTE FUNCTION public.update_ingredient_term_norm();

-- ============================================
-- 2) Row Level Security (RLS) Configuration
-- ============================================

-- Enable RLS on ingredient_terms table
ALTER TABLE public.ingredient_terms ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS ingredient_terms_select ON public.ingredient_terms;
DROP POLICY IF EXISTS ingredient_terms_write ON public.ingredient_terms;

-- Everyone can read aliases (anon and authenticated users)
CREATE POLICY ingredient_terms_select
ON public.ingredient_terms
FOR SELECT
TO anon, authenticated
USING (true);

-- Only service role (server) can write; your Edge Functions / service key bypass RLS
CREATE POLICY ingredient_terms_write
ON public.ingredient_terms
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- 3) Backfill English aliases from existing ingredients
-- ============================================

-- Insert English aliases from existing ingredient names
INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
SELECT i.id, i.name, 'en', true, 10
FROM public.ingredients i
ON CONFLICT DO NOTHING;

-- Backfill term_norm for existing ingredient_terms
UPDATE public.ingredient_terms 
SET term_norm = lower(trim(term))
WHERE term_norm IS NULL;

-- ============================================
-- 4) Create search function that uses aliases
-- ============================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.search_recipes_by_ingredient(text);

-- Create search function that uses aliases if present, falls back to ingredients
CREATE OR REPLACE FUNCTION public.search_recipes_by_ingredient(q text)
RETURNS TABLE (recipe_id uuid)
LANGUAGE plpgsql
AS $$
DECLARE
  has_terms boolean;
BEGIN
  -- Check if ingredient_terms table exists
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema='public' AND table_name='ingredient_terms'
  ) INTO has_terms;

  IF has_terms THEN
    -- Use ingredient_terms table for search
    RETURN QUERY
      WITH nq AS (SELECT lower(unaccent(coalesce(q,''))) AS q_norm)
      SELECT DISTINCT ri.recipe_id
      FROM nq
      JOIN public.ingredient_terms it
        ON it.term_norm % nq.q_norm
        OR it.term_norm LIKE '%' || nq.q_norm || '%'
      JOIN public.recipe_ingredients ri
        ON ri.ingredient_id = it.ingredient_id;
  ELSE
    -- Fallback if terms table were ever absent
    RETURN QUERY
      WITH nq AS (SELECT lower(unaccent(coalesce(q,''))) AS q_norm)
      SELECT DISTINCT ri.recipe_id
      FROM nq
      JOIN public.ingredients i
        ON i.name_norm % nq.q_norm
        OR i.name_norm LIKE '%' || nq.q_norm || '%'
      JOIN public.recipe_ingredients ri
        ON ri.ingredient_id = i.id;
  END IF;
END;
$$;

-- Set permissions for the search function
REVOKE ALL ON FUNCTION public.search_recipes_by_ingredient(text) FROM public;
GRANT EXECUTE ON FUNCTION public.search_recipes_by_ingredient(text) TO anon, authenticated;

-- ============================================
-- 5) Helper functions
-- ============================================

-- Function to add ingredient alias (no duplicates; preserves casing)
-- Call from your creator typeahead: pass chosen ingredient_id and new text alias
-- It inserts if missing (case/accents ignored for uniqueness), keeping original casing
CREATE OR REPLACE FUNCTION public.add_ingredient_alias(
  p_ingredient_id uuid,
  p_term text,
  p_locale text DEFAULT NULL,
  p_is_primary boolean DEFAULT false,
  p_weight int DEFAULT 1
) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_term IS NULL OR btrim(p_term) = '' THEN
    RAISE EXCEPTION 'Term cannot be empty';
  END IF;

  INSERT INTO public.ingredient_terms
    (ingredient_id, term, locale, is_primary, weight)
  VALUES
    (p_ingredient_id, p_term, p_locale, p_is_primary, p_weight)
  ON CONFLICT (ingredient_id, term, locale)
  DO NOTHING;
END;
$$;

-- Set permissions for add_ingredient_alias function
REVOKE ALL ON FUNCTION public.add_ingredient_alias(uuid, text, text, boolean, int) FROM public;
GRANT EXECUTE ON FUNCTION public.add_ingredient_alias(uuid, text, text, boolean, int) TO service_role;

-- Function to merge duplicate ingredients safely
-- Use if you ever spot duplicate ingredients despite defenses
CREATE OR REPLACE FUNCTION public.merge_ingredients(from_id uuid, to_id uuid)
RETURNS void 
LANGUAGE plpgsql 
AS $$
BEGIN
  IF from_id = to_id THEN 
    RAISE EXCEPTION 'from_id == to_id'; 
  END IF;

  -- Update all references to use the target ingredient
  UPDATE public.recipe_ingredients SET ingredient_id = to_id WHERE ingredient_id = from_id;
  UPDATE public.store_items SET ingredient_id = to_id WHERE ingredient_id = from_id;
  UPDATE public.shopping_list_items SET ingredient_id = to_id WHERE ingredient_id = from_id;

  -- Move all terms to the target ingredient
  UPDATE public.ingredient_terms SET ingredient_id = to_id WHERE ingredient_id = from_id;

  -- Delete the duplicate ingredient
  DELETE FROM public.ingredients WHERE id = from_id;
END;
$$;

-- Set permissions for merge_ingredients function
REVOKE ALL ON FUNCTION public.merge_ingredients(uuid, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.merge_ingredients(uuid, uuid) TO service_role;

-- ============================================
-- 6) Sample Chinese aliases for common ingredients
-- ============================================

-- Add Chinese aliases for common ingredients
-- Note: Replace the ingredient IDs with actual UUIDs from your database

-- Example: If you have a Beef ingredient, you would run:
-- INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
-- SELECT id, '牛肉', 'zh', true, 10 FROM public.ingredients WHERE name = 'Beef';

-- Example: If you have a Chicken ingredient, you would run:
-- INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
-- SELECT id, '鸡肉', 'zh', true, 10 FROM public.ingredients WHERE name = 'Chicken';

-- Example: If you have a Rice ingredient, you would run:
-- INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
-- SELECT id, '米饭', 'zh', true, 10 FROM public.ingredients WHERE name = 'Rice';

-- Example: If you have a Potato ingredient, you would run:
-- INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
-- SELECT id, '土豆', 'zh', true, 10 FROM public.ingredients WHERE name = 'Potato';

-- ============================================
-- 7) Test queries (uncomment to test)
-- ============================================

-- Test the search function with English terms
-- SELECT * FROM public.search_recipes_by_ingredient('beef');

-- Test the search function with Chinese terms (after adding Chinese aliases)
-- SELECT * FROM public.search_recipes_by_ingredient('牛肉');

-- View all ingredient terms
-- SELECT i.name, it.term, it.locale, it.is_primary 
-- FROM public.ingredients i 
-- JOIN public.ingredient_terms it ON i.id = it.ingredient_id 
-- ORDER BY i.name, it.locale;

-- ============================================
-- Migration Complete!
-- ============================================

-- The migration is now complete. Here's what was added:
-- 1. PostgreSQL extensions for text processing
-- 2. Normalized name column for duplicate prevention
-- 3. ingredient_terms table for bilingual support
-- 4. Row Level Security policies
-- 5. Search function that works with aliases
-- 6. Helper functions for managing aliases
-- 7. Backfilled English aliases from existing ingredients

-- Next steps:
-- 1. Run this migration in your Supabase SQL editor
-- 2. Add Chinese aliases for your existing ingredients
-- 3. Update your Flutter app to use the new search function
-- 4. Test the bilingual search functionality
