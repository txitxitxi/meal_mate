import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Simple translation mapping for common ingredients (no API key needed)
const commonTranslations: Record<string, string> = {
  // Meat & Poultry
  'chicken': '鸡肉',
  'beef': '牛肉',
  'beef ribs': '牛排骨',
  'pork': '猪肉',
  'lamb': '羊肉',
  'turkey': '火鸡',
  'duck': '鸭肉',
  'fish': '鱼',
  'salmon': '三文鱼',
  'tuna': '金枪鱼',
  'shrimp': '虾',
  'crab': '螃蟹',
  'lobster': '龙虾',
  
  // Vegetables
  'tomato': '西红柿',
  'onion': '洋葱',
  'garlic': '大蒜',
  'potato': '土豆',
  'carrot': '胡萝卜',
  'broccoli': '西兰花',
  'lettuce': '生菜',
  'cabbage': '卷心菜',
  'spinach': '菠菜',
  'mushroom': '蘑菇',
  'pepper': '辣椒',
  'cucumber': '黄瓜',
  'eggplant': '茄子',
  'corn': '玉米',
  'peas': '豌豆',
  'beans': '豆类',
  
  // Fruits
  'apple': '苹果',
  'banana': '香蕉',
  'orange': '橙子',
  'lemon': '柠檬',
  'grape': '葡萄',
  'strawberry': '草莓',
  'blueberry': '蓝莓',
  'cherry': '樱桃',
  'peach': '桃子',
  'pear': '梨',
  
  // Grains & Starches
  'rice': '米饭',
  'noodle': '面条',
  'pasta': '意大利面',
  'bread': '面包',
  'flour': '面粉',
  'oats': '燕麦',
  'quinoa': '藜麦',
  
  // Dairy & Eggs
  'milk': '牛奶',
  'cheese': '奶酪',
  'yogurt': '酸奶',
  'butter': '黄油',
  'egg': '鸡蛋',
  'cream': '奶油',
  
  // Spices & Seasonings
  'salt': '盐',
  'pepper': '胡椒',
  'sugar': '糖',
  'honey': '蜂蜜',
  'oil': '油',
  'vinegar': '醋',
  'soy sauce': '酱油',
  'ginger': '姜',
  'garlic': '大蒜',
  'onion': '洋葱',
  
  // Common cooking terms
  'water': '水',
  'soup': '汤',
  'sauce': '酱',
  'spice': '香料',
  'herb': '香草',
  'seasoning': '调料',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const { ingredient_name, target_language = 'zh' } = await req.json()

    if (!ingredient_name) {
      return new Response(
        JSON.stringify({ error: 'ingredient_name is required' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const lowerIngredientName = ingredient_name.toLowerCase().trim()

    // First, check if we already have a translation in our cache
    const { data: existingTranslation } = await supabaseClient
      .from('ingredient_translation_cache')
      .select('chinese_term')
      .eq('english_term', lowerIngredientName)
      .single()

    if (existingTranslation) {
      return new Response(
        JSON.stringify({ 
          english_name: ingredient_name,
          chinese_term: existingTranslation.chinese_term,
          cached: true,
          source: 'database_cache'
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Check our common translations mapping
    let chineseTranslation = commonTranslations[lowerIngredientName]
    let translationSource = 'common_mapping'

    // If not found in common mappings, try partial matches
    if (!chineseTranslation) {
      for (const [english, chinese] of Object.entries(commonTranslations)) {
        if (lowerIngredientName.includes(english) || english.includes(lowerIngredientName)) {
          chineseTranslation = chinese
          translationSource = 'partial_match'
          break
        }
      }
    }

    // If still not found, create a placeholder that can be manually updated
    if (!chineseTranslation) {
      chineseTranslation = `[需要翻译: ${ingredient_name}]`
      translationSource = 'placeholder'
    }

    // Cache the translation in our database
    const { error: insertError } = await supabaseClient
      .from('ingredient_translation_cache')
      .insert({
        english_term: lowerIngredientName,
        chinese_term: chineseTranslation,
        created_at: new Date().toISOString()
      })

    if (insertError) {
      console.error('Error caching translation:', insertError)
      // Don't fail the request, just log the error
    }

    return new Response(
      JSON.stringify({ 
        english_name: ingredient_name,
        chinese_term: chineseTranslation,
        cached: false,
        source: translationSource
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Translation error:', error)
    return new Response(
      JSON.stringify({ error: 'Translation failed' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})