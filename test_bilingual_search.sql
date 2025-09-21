-- Test script for bilingual ingredient search functionality
-- Run this after the migration and Chinese aliases have been added

-- ============================================
-- Test 1: Verify the ingredient_terms table was created and populated
-- ============================================

-- Check if the table exists and has data
SELECT 'ingredient_terms table check' as test_name;
SELECT COUNT(*) as total_terms FROM public.ingredient_terms;
SELECT COUNT(*) as english_terms FROM public.ingredient_terms WHERE locale = 'en';
SELECT COUNT(*) as chinese_terms FROM public.ingredient_terms WHERE locale = 'zh';

-- Show sample terms
SELECT 'Sample terms by locale' as test_name;
SELECT locale, term, is_primary, weight 
FROM public.ingredient_terms 
ORDER BY locale, weight DESC, term 
LIMIT 20;

-- ============================================
-- Test 2: Verify the search function exists and works
-- ============================================

-- Test English search
SELECT 'English search test - beef' as test_name;
SELECT * FROM public.search_recipes_by_ingredient('beef');

-- Test English search with different casing
SELECT 'English search test - BEEF' as test_name;
SELECT * FROM public.search_recipes_by_ingredient('BEEF');

-- Test English search with partial match
SELECT 'English search test - chick' as test_name;
SELECT * FROM public.search_recipes_by_ingredient('chick');

-- Test Chinese search (if Chinese aliases were added)
SELECT 'Chinese search test - 牛肉' as test_name;
SELECT * FROM public.search_recipes_by_ingredient('牛肉');

SELECT 'Chinese search test - 鸡肉' as test_name;
SELECT * FROM public.search_recipes_by_ingredient('鸡肉');

-- ============================================
-- Test 3: Test the add_ingredient_alias function
-- ============================================

-- Find an ingredient to add an alias for (replace with actual ingredient ID)
SELECT 'Available ingredients for alias testing' as test_name;
SELECT id, name FROM public.ingredients LIMIT 5;

-- Example: Add a Chinese alias for an ingredient (uncomment and replace UUID)
-- SELECT public.add_ingredient_alias('your-ingredient-uuid-here', '测试', 'zh', false, 5);

-- ============================================
-- Test 4: Test fuzzy search capabilities
-- ============================================

-- Test with typos (should still find matches)
SELECT 'Fuzzy search test - beef (with typo)' as test_name;
SELECT * FROM public.search_recipes_by_ingredient('beff');

-- Test with accents (should still find matches)
SELECT 'Accent search test - café' as test_name;
SELECT * FROM public.search_recipes_by_ingredient('café');

-- ============================================
-- Test 5: Performance test
-- ============================================

-- Time the search function
SELECT 'Performance test' as test_name;
EXPLAIN ANALYZE SELECT * FROM public.search_recipes_by_ingredient('beef');

-- ============================================
-- Test 6: Verify RLS policies
-- ============================================

-- Test that authenticated users can read ingredient_terms
SELECT 'RLS test - authenticated read' as test_name;
SET ROLE authenticated;
SELECT COUNT(*) as readable_terms FROM public.ingredient_terms;
RESET ROLE;

-- Test that anonymous users can read ingredient_terms
SELECT 'RLS test - anonymous read' as test_name;
SET ROLE anon;
SELECT COUNT(*) as readable_terms FROM public.ingredient_terms;
RESET ROLE;

-- ============================================
-- Test 7: Integration test with recipes
-- ============================================

-- Check if there are any recipes to test with
SELECT 'Recipe integration test' as test_name;
SELECT COUNT(*) as total_recipes FROM public.recipes;
SELECT COUNT(*) as total_recipe_ingredients FROM public.recipe_ingredients;

-- Show sample recipe-ingredient relationships
SELECT 'Sample recipe-ingredient relationships' as test_name;
SELECT 
  r.title as recipe_title,
  i.name as ingredient_name,
  ri.quantity,
  ri.unit
FROM public.recipes r
JOIN public.recipe_ingredients ri ON r.id = ri.recipe_id
JOIN public.ingredients i ON ri.ingredient_id = i.id
LIMIT 10;

-- Test search with actual recipe data
SELECT 'Recipe search test' as test_name;
SELECT 
  r.title,
  r.id as recipe_id
FROM public.recipes r
WHERE r.id IN (
  SELECT recipe_id FROM public.search_recipes_by_ingredient('beef')
)
LIMIT 5;

-- ============================================
-- Summary Report
-- ============================================

SELECT 'Migration Summary' as report_section;

SELECT 
  'Total ingredients' as metric,
  COUNT(*)::text as value
FROM public.ingredients

UNION ALL

SELECT 
  'Total ingredient terms' as metric,
  COUNT(*)::text as value
FROM public.ingredient_terms

UNION ALL

SELECT 
  'English terms' as metric,
  COUNT(*)::text as value
FROM public.ingredient_terms WHERE locale = 'en'

UNION ALL

SELECT 
  'Chinese terms' as metric,
  COUNT(*)::text as value
FROM public.ingredient_terms WHERE locale = 'zh'

UNION ALL

SELECT 
  'Total recipes' as metric,
  COUNT(*)::text as value
FROM public.recipes

UNION ALL

SELECT 
  'Recipe-ingredient relationships' as metric,
  COUNT(*)::text as value
FROM public.recipe_ingredients;

-- ============================================
-- Next Steps
-- ============================================

SELECT 'Next Steps for Flutter Integration' as next_steps;

-- The following should be implemented in your Flutter app:

-- 1. Update your ingredient search to use the new search function:
--    supabase.rpc('search_recipes_by_ingredient', {'q': searchTerm})

-- 2. For ingredient autocomplete/typeahead, query ingredient_terms:
--    supabase.from('ingredient_terms').select('term, ingredient_id').ilike('term_norm', '%search%')

-- 3. When adding new ingredients, consider adding bilingual aliases:
--    supabase.rpc('add_ingredient_alias', {
--      'p_ingredient_id': ingredientId,
--      'p_term': newAlias,
--      'p_locale': 'zh', // or 'en'
--      'p_is_primary': false
--    })

-- 4. Display ingredients using the original name for consistent casing:
--    Keep using ingredients.name for display (it preserves "Beef", "Ice Cream", etc.)

SELECT 'Bilingual ingredients migration completed successfully!' as status;
