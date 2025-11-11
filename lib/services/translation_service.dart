import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class TranslationService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Translate an ingredient using Supabase Edge Function + Translation API
  /// This uses real translation APIs instead of manual lookup tables
  static Future<Map<String, String>?> translateIngredient(String englishName) async {
    try {
      final response = await _client.functions.invoke(
        'translate-ingredient',
        body: {
          'ingredient_name': englishName,
          'target_language': 'zh',
        },
      );

      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'english_name': data['english_name'] as String,
          'chinese_name': data['chinese_name'] as String,
        };
      }
      return null;
    } catch (e) {
      logDebug('Error translating ingredient: $e');
      return null;
    }
  }

  /// Add a new ingredient translation to the cache
  /// This will help cache translations for future use
  static Future<void> addIngredientTranslation({
    required String englishName,
    required String chineseName,
    String? category,
  }) async {
    try {
      await _client.rpc('update_ingredient_translation', params: {
        'ingredient_name_param': englishName,
        'chinese_translation_param': chineseName,
      });
    } catch (e) {
      logDebug('Error caching ingredient translation: $e');
      rethrow;
    }
  }

  /// Get all available translations for reference
  static Future<List<Map<String, dynamic>>> getAllTranslations() async {
    try {
      final response = await _client
          .from('ingredient_translations')
          .select('*')
          .order('english_name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      logDebug('Error fetching translations: $e');
      return [];
    }
  }

  /// Search for translations by English name (case-insensitive)
  static Future<List<Map<String, dynamic>>> searchTranslations(String query) async {
    try {
      final response = await _client
          .from('ingredient_translations')
          .select('*')
          .ilike('english_name', '%$query%')
          .order('english_name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      logDebug('Error searching translations: $e');
      return [];
    }
  }

  /// Get translation for a specific English ingredient name
  static Future<Map<String, dynamic>?> getTranslation(String englishName) async {
    try {
      final response = await _client
          .from('ingredient_translations')
          .select('*')
          .eq('english_name', englishName)
          .maybeSingle();
      
      return response;
    } catch (e) {
      logDebug('Error getting translation: $e');
      return null;
    }
  }

  /// Check if an ingredient has a Chinese translation available
  static Future<bool> hasTranslation(String englishName) async {
    final translation = await getTranslation(englishName);
    return translation != null;
  }

  /// Get the Chinese name for an English ingredient
  static Future<String?> getChineseName(String englishName) async {
    final translation = await getTranslation(englishName);
    return translation?['chinese_name'];
  }

  /// Apply retroactive translations to existing ingredients
  /// This will translate ingredients that were added before the auto-translation system
  static Future<int> applyRetroactiveTranslations() async {
    try {
      final response = await _client.rpc('apply_retroactive_translations');
      return response as int;
    } catch (e) {
      logDebug('Error applying retroactive translations: $e');
      return 0;
    }
  }

  /// Get statistics about the translation system
  static Future<Map<String, int>> getTranslationStats() async {
    try {
      final response = await _client
          .from('ingredient_translations')
          .select('*');
      
      final totalTranslations = response.length;
      
      // Get count of ingredients with Chinese aliases
      final ingredientsWithChinese = await _client
          .from('ingredient_terms')
          .select('ingredient_id')
          .eq('locale', 'zh');
      
      final chineseCount = ingredientsWithChinese.length;
      
      // Get total ingredients
      final totalIngredients = await _client
          .from('ingredients')
          .select('*');
      
      final ingredientCount = totalIngredients.length;
      
      return {
        'total_translations': totalTranslations,
        'ingredients_with_chinese': chineseCount,
        'total_ingredients': ingredientCount,
        'missing_translations': ingredientCount - chineseCount,
      };
    } catch (e) {
      logDebug('Error getting translation stats: $e');
      return {};
    }
  }
}

