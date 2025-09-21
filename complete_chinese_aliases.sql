-- Complete Chinese aliases for all missing ingredients
-- This script adds Chinese translations for the 310 ingredients missing Chinese aliases

-- Function to add Chinese alias if it doesn't exist
CREATE OR REPLACE FUNCTION add_chinese_alias_if_missing(
    english_name text,
    chinese_name text
) RETURNS void AS $$
BEGIN
    INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
    SELECT id, chinese_name, 'zh', true, 10 
    FROM public.ingredients 
    WHERE name = english_name
    AND NOT EXISTS (
        SELECT 1 FROM public.ingredient_terms it 
        WHERE it.ingredient_id = public.ingredients.id 
        AND it.locale = 'zh'
    );
END;
$$ LANGUAGE plpgsql;

-- Meat & Poultry - Additional specific cuts
SELECT add_chinese_alias_if_missing('Turkey Breast', '火鸡胸肉');
SELECT add_chinese_alias_if_missing('Ground Turkey', '火鸡肉馅');
SELECT add_chinese_alias_if_missing('Duck Breast', '鸭胸肉');
SELECT add_chinese_alias_if_missing('Beef Roast', '烤牛肉');
SELECT add_chinese_alias_if_missing('Beef Ribs', '牛排骨');
SELECT add_chinese_alias_if_missing('Beef Brisket', '牛胸肉');
SELECT add_chinese_alias_if_missing('Pork Tenderloin', '猪里脊');
SELECT add_chinese_alias_if_missing('Pork Shoulder', '猪肩肉');
SELECT add_chinese_alias_if_missing('Bacon', '培根');
SELECT add_chinese_alias_if_missing('Ham', '火腿');
SELECT add_chinese_alias_if_missing('Sausage', '香肠');
SELECT add_chinese_alias_if_missing('Lamb Chops', '羊排');
SELECT add_chinese_alias_if_missing('Ground Lamb', '羊肉馅');
SELECT add_chinese_alias_if_missing('Lamb Shoulder', '羊肩肉');

-- Seafood - Additional varieties
SELECT add_chinese_alias_if_missing('Halibut', '比目鱼');
SELECT add_chinese_alias_if_missing('Trout', '鳟鱼');
SELECT add_chinese_alias_if_missing('Crab', '螃蟹');
SELECT add_chinese_alias_if_missing('Lobster', '龙虾');
SELECT add_chinese_alias_if_missing('Scallops', '扇贝');
SELECT add_chinese_alias_if_missing('Mussels', '青口贝');
SELECT add_chinese_alias_if_missing('Clams', '蛤蜊');
SELECT add_chinese_alias_if_missing('Oysters', '牡蛎');
SELECT add_chinese_alias_if_missing('Calamari', '鱿鱼');
SELECT add_chinese_alias_if_missing('Tilapia', '罗非鱼');
SELECT add_chinese_alias_if_missing('Mahi Mahi', '鲯鲯鱼');

-- Dairy Products - Additional varieties
SELECT add_chinese_alias_if_missing('2% Milk', '2%牛奶');
SELECT add_chinese_alias_if_missing('Skim Milk', '脱脂牛奶');
SELECT add_chinese_alias_if_missing('Heavy Cream', '重奶油');
SELECT add_chinese_alias_if_missing('Half and Half', '半奶油半牛奶');
SELECT add_chinese_alias_if_missing('Unsalted Butter', '无盐黄油');
SELECT add_chinese_alias_if_missing('Margarine', '人造黄油');
SELECT add_chinese_alias_if_missing('Cheddar Cheese', '切达奶酪');
SELECT add_chinese_alias_if_missing('Mozzarella Cheese', '马苏里拉奶酪');
SELECT add_chinese_alias_if_missing('Parmesan Cheese', '帕尔马奶酪');
SELECT add_chinese_alias_if_missing('Feta Cheese', '羊奶酪');
SELECT add_chinese_alias_if_missing('Ricotta Cheese', '里科塔奶酪');
SELECT add_chinese_alias_if_missing('Cream Cheese', '奶油奶酪');
SELECT add_chinese_alias_if_missing('Sour Cream', '酸奶油');
SELECT add_chinese_alias_if_missing('Greek Yogurt', '希腊酸奶');
SELECT add_chinese_alias_if_missing('Plain Yogurt', '原味酸奶');
SELECT add_chinese_alias_if_missing('Buttermilk', '酪乳');

-- Vegetables - Additional varieties
SELECT add_chinese_alias_if_missing('Yellow Onions', '黄洋葱');
SELECT add_chinese_alias_if_missing('Red Onions', '红洋葱');
SELECT add_chinese_alias_if_missing('Sweet Onions', '甜洋葱');
SELECT add_chinese_alias_if_missing('Green Onions', '青葱');
SELECT add_chinese_alias_if_missing('Red Bell Peppers', '红椒');
SELECT add_chinese_alias_if_missing('Green Bell Peppers', '青椒');
SELECT add_chinese_alias_if_missing('Yellow Bell Peppers', '黄椒');
SELECT add_chinese_alias_if_missing('Jalapeños', '墨西哥胡椒');
SELECT add_chinese_alias_if_missing('Cherry Tomatoes', '圣女果');
SELECT add_chinese_alias_if_missing('Roma Tomatoes', '罗马番茄');
SELECT add_chinese_alias_if_missing('Cucumbers', '黄瓜');
SELECT add_chinese_alias_if_missing('Romaine Lettuce', '罗马生菜');
SELECT add_chinese_alias_if_missing('Iceberg Lettuce', '卷心菜生菜');
SELECT add_chinese_alias_if_missing('Kale', '羽衣甘蓝');
SELECT add_chinese_alias_if_missing('Arugula', '芝麻菜');
SELECT add_chinese_alias_if_missing('Cauliflower', '花椰菜');
SELECT add_chinese_alias_if_missing('Brussels Sprouts', '球芽甘蓝');
SELECT add_chinese_alias_if_missing('Red Cabbage', '红卷心菜');
SELECT add_chinese_alias_if_missing('Russet Potatoes', '褐色土豆');
SELECT add_chinese_alias_if_missing('Red Potatoes', '红土豆');
SELECT add_chinese_alias_if_missing('Yukon Gold Potatoes', '黄金土豆');
SELECT add_chinese_alias_if_missing('White Mushrooms', '白蘑菇');
SELECT add_chinese_alias_if_missing('Portobello Mushrooms', '大蘑菇');
SELECT add_chinese_alias_if_missing('Shiitake Mushrooms', '香菇');
SELECT add_chinese_alias_if_missing('Eggplant', '茄子');
SELECT add_chinese_alias_if_missing('Zucchini', '西葫芦');
SELECT add_chinese_alias_if_missing('Squash', '南瓜');
SELECT add_chinese_alias_if_missing('Butternut Squash', '南瓜');
SELECT add_chinese_alias_if_missing('Asparagus', '芦笋');
SELECT add_chinese_alias_if_missing('Snow Peas', '荷兰豆');
SELECT add_chinese_alias_if_missing('Corn', '玉米');
SELECT add_chinese_alias_if_missing('Avocado', '鳄梨');
SELECT add_chinese_alias_if_missing('Radishes', '萝卜');
SELECT add_chinese_alias_if_missing('Beets', '甜菜');
SELECT add_chinese_alias_if_missing('Turnips', '芜菁');

-- Fruits - Additional varieties
SELECT add_chinese_alias_if_missing('Red Apples', '红苹果');
SELECT add_chinese_alias_if_missing('Green Apples', '青苹果');
SELECT add_chinese_alias_if_missing('Grapefruit', '葡萄柚');
SELECT add_chinese_alias_if_missing('Grapes', '葡萄');
SELECT add_chinese_alias_if_missing('Blueberries', '蓝莓');
SELECT add_chinese_alias_if_missing('Raspberries', '树莓');
SELECT add_chinese_alias_if_missing('Blackberries', '黑莓');
SELECT add_chinese_alias_if_missing('Cherries', '樱桃');
SELECT add_chinese_alias_if_missing('Peaches', '桃子');
SELECT add_chinese_alias_if_missing('Pears', '梨');
SELECT add_chinese_alias_if_missing('Plums', '李子');
SELECT add_chinese_alias_if_missing('Apricots', '杏子');
SELECT add_chinese_alias_if_missing('Mangoes', '芒果');
SELECT add_chinese_alias_if_missing('Pineapple', '菠萝');
SELECT add_chinese_alias_if_missing('Watermelon', '西瓜');
SELECT add_chinese_alias_if_missing('Cantaloupe', '哈密瓜');
SELECT add_chinese_alias_if_missing('Honeydew', '蜜瓜');
SELECT add_chinese_alias_if_missing('Kiwi', '猕猴桃');
SELECT add_chinese_alias_if_missing('Pomegranate', '石榴');
SELECT add_chinese_alias_if_missing('Cranberries', '蔓越莓');
SELECT add_chinese_alias_if_missing('Raisins', '葡萄干');
SELECT add_chinese_alias_if_missing('Dates', '椰枣');

-- Grains & Starches - Additional varieties
SELECT add_chinese_alias_if_missing('Brown Rice', '糙米');
SELECT add_chinese_alias_if_missing('Jasmine Rice', '茉莉香米');
SELECT add_chinese_alias_if_missing('Basmati Rice', '印度香米');
SELECT add_chinese_alias_if_missing('Wild Rice', '野米');
SELECT add_chinese_alias_if_missing('Arborio Rice', '意大利米');
SELECT add_chinese_alias_if_missing('Penne', '通心粉');
SELECT add_chinese_alias_if_missing('Fettuccine', '宽面条');
SELECT add_chinese_alias_if_missing('Macaroni', '通心粉');
SELECT add_chinese_alias_if_missing('Fusilli', '螺旋面');
SELECT add_chinese_alias_if_missing('Rigatoni', '粗管面');
SELECT add_chinese_alias_if_missing('Lasagna Noodles', '千层面');
SELECT add_chinese_alias_if_missing('Ravioli', '意大利饺子');
SELECT add_chinese_alias_if_missing('Tortellini', '意大利馄饨');
SELECT add_chinese_alias_if_missing('White Bread', '白面包');
SELECT add_chinese_alias_if_missing('Whole Wheat Bread', '全麦面包');
SELECT add_chinese_alias_if_missing('Sourdough Bread', '酸面包');
SELECT add_chinese_alias_if_missing('French Bread', '法式面包');
SELECT add_chinese_alias_if_missing('Bagels', '贝果');
SELECT add_chinese_alias_if_missing('English Muffins', '英式松饼');
SELECT add_chinese_alias_if_missing('Flour Tortillas', '面粉饼');
SELECT add_chinese_alias_if_missing('Corn Tortillas', '玉米饼');
SELECT add_chinese_alias_if_missing('Whole Wheat Flour', '全麦面粉');
SELECT add_chinese_alias_if_missing('Bread Flour', '面包粉');
SELECT add_chinese_alias_if_missing('Cake Flour', '蛋糕粉');
SELECT add_chinese_alias_if_missing('Almond Flour', '杏仁粉');
SELECT add_chinese_alias_if_missing('Coconut Flour', '椰子粉');
SELECT add_chinese_alias_if_missing('Rolled Oats', '燕麦片');
SELECT add_chinese_alias_if_missing('Steel Cut Oats', '钢切燕麦');
SELECT add_chinese_alias_if_missing('Barley', '大麦');
SELECT add_chinese_alias_if_missing('Bulgur', '布格麦');
SELECT add_chinese_alias_if_missing('Couscous', '古斯米');
SELECT add_chinese_alias_if_missing('Polenta', '玉米粥');

-- Legumes & Nuts - Additional varieties
SELECT add_chinese_alias_if_missing('Kidney Beans', '芸豆');
SELECT add_chinese_alias_if_missing('Pinto Beans', '斑豆');
SELECT add_chinese_alias_if_missing('Navy Beans', '白豆');
SELECT add_chinese_alias_if_missing('Red Lentils', '红扁豆');
SELECT add_chinese_alias_if_missing('Green Lentils', '绿扁豆');
SELECT add_chinese_alias_if_missing('Black Lentils', '黑扁豆');
SELECT add_chinese_alias_if_missing('Split Peas', '豌豆');
SELECT add_chinese_alias_if_missing('Lima Beans', '利马豆');
SELECT add_chinese_alias_if_missing('Black-Eyed Peas', '豇豆');
SELECT add_chinese_alias_if_missing('Tempeh', '天贝');
SELECT add_chinese_alias_if_missing('Edamame', '毛豆');
SELECT add_chinese_alias_if_missing('Walnuts', '核桃');
SELECT add_chinese_alias_if_missing('Pecans', '山核桃');
SELECT add_chinese_alias_if_missing('Pistachios', '开心果');
SELECT add_chinese_alias_if_missing('Hazelnuts', '榛子');
SELECT add_chinese_alias_if_missing('Macadamia Nuts', '夏威夷果');
SELECT add_chinese_alias_if_missing('Brazil Nuts', '巴西坚果');
SELECT add_chinese_alias_if_missing('Pine Nuts', '松子');
SELECT add_chinese_alias_if_missing('Almond Butter', '杏仁酱');
SELECT add_chinese_alias_if_missing('Peanut Butter', '花生酱');
SELECT add_chinese_alias_if_missing('Cashew Butter', '腰果酱');
SELECT add_chinese_alias_if_missing('Sunflower Seeds', '葵花籽');
SELECT add_chinese_alias_if_missing('Pumpkin Seeds', '南瓜籽');
SELECT add_chinese_alias_if_missing('Sesame Seeds', '芝麻');
SELECT add_chinese_alias_if_missing('Chia Seeds', '奇亚籽');
SELECT add_chinese_alias_if_missing('Flax Seeds', '亚麻籽');
SELECT add_chinese_alias_if_missing('Hemp Seeds', '大麻籽');

-- Herbs & Spices - Additional varieties
SELECT add_chinese_alias_if_missing('Sea Salt', '海盐');
SELECT add_chinese_alias_if_missing('Kosher Salt', '粗盐');
SELECT add_chinese_alias_if_missing('White Pepper', '白胡椒');
SELECT add_chinese_alias_if_missing('Cayenne Pepper', '辣椒粉');
SELECT add_chinese_alias_if_missing('Smoked Paprika', '烟熏辣椒粉');
SELECT add_chinese_alias_if_missing('Chili Powder', '辣椒粉');
SELECT add_chinese_alias_if_missing('Coriander', '香菜籽');
SELECT add_chinese_alias_if_missing('Turmeric', '姜黄');
SELECT add_chinese_alias_if_missing('Nutmeg', '肉豆蔻');
SELECT add_chinese_alias_if_missing('Allspice', '多香果');
SELECT add_chinese_alias_if_missing('Cloves', '丁香');
SELECT add_chinese_alias_if_missing('Cardamom', '豆蔻');
SELECT add_chinese_alias_if_missing('Star Anise', '八角');
SELECT add_chinese_alias_if_missing('Bay Leaves', '月桂叶');
SELECT add_chinese_alias_if_missing('Rosemary', '迷迭香');
SELECT add_chinese_alias_if_missing('Oregano', '牛至');
SELECT add_chinese_alias_if_missing('Parsley', '欧芹');
SELECT add_chinese_alias_if_missing('Dill', '莳萝');
SELECT add_chinese_alias_if_missing('Mint', '薄荷');
SELECT add_chinese_alias_if_missing('Sage', '鼠尾草');
SELECT add_chinese_alias_if_missing('Tarragon', '龙蒿');
SELECT add_chinese_alias_if_missing('Chives', '细香葱');
SELECT add_chinese_alias_if_missing('Marjoram', '马郁兰');
SELECT add_chinese_alias_if_missing('Italian Seasoning', '意大利调料');
SELECT add_chinese_alias_if_missing('Herbs de Provence', '普罗旺斯香草');
SELECT add_chinese_alias_if_missing('Old Bay Seasoning', '老湾调料');
SELECT add_chinese_alias_if_missing('Garlic Powder', '大蒜粉');
SELECT add_chinese_alias_if_missing('Onion Powder', '洋葱粉');
SELECT add_chinese_alias_if_missing('Mustard Powder', '芥末粉');
SELECT add_chinese_alias_if_missing('Red Pepper Flakes', '红辣椒片');
SELECT add_chinese_alias_if_missing('Vanilla Extract', '香草精');
SELECT add_chinese_alias_if_missing('Almond Extract', '杏仁精');

-- Oils & Vinegars - Additional varieties
SELECT add_chinese_alias_if_missing('Extra Virgin Olive Oil', '特级初榨橄榄油');
SELECT add_chinese_alias_if_missing('Vegetable Oil', '植物油');
SELECT add_chinese_alias_if_missing('Canola Oil', '菜籽油');
SELECT add_chinese_alias_if_missing('Avocado Oil', '鳄梨油');
SELECT add_chinese_alias_if_missing('Grape Seed Oil', '葡萄籽油');
SELECT add_chinese_alias_if_missing('Sunflower Oil', '葵花籽油');
SELECT add_chinese_alias_if_missing('Peanut Oil', '花生油');
SELECT add_chinese_alias_if_missing('White Vinegar', '白醋');
SELECT add_chinese_alias_if_missing('Apple Cider Vinegar', '苹果醋');
SELECT add_chinese_alias_if_missing('Red Wine Vinegar', '红酒醋');
SELECT add_chinese_alias_if_missing('White Wine Vinegar', '白酒醋');
SELECT add_chinese_alias_if_missing('Rice Vinegar', '米醋');
SELECT add_chinese_alias_if_missing('Sherry Vinegar', '雪利醋');
SELECT add_chinese_alias_if_missing('Lime Juice', '青柠汁');

-- Condiments & Sauces - Additional varieties
SELECT add_chinese_alias_if_missing('Dijon Mustard', '第戎芥末');
SELECT add_chinese_alias_if_missing('Whole Grain Mustard', '全粒芥末');
SELECT add_chinese_alias_if_missing('Worcestershire Sauce', '伍斯特沙司');
SELECT add_chinese_alias_if_missing('Hot Sauce', '辣酱');
SELECT add_chinese_alias_if_missing('Tabasco Sauce', '塔巴斯科辣酱');
SELECT add_chinese_alias_if_missing('Sriracha', '是拉差辣酱');
SELECT add_chinese_alias_if_missing('Barbecue Sauce', '烧烤酱');
SELECT add_chinese_alias_if_missing('Teriyaki Sauce', '照烧酱');
SELECT add_chinese_alias_if_missing('Pesto', '香蒜酱');
SELECT add_chinese_alias_if_missing('Hoisin Sauce', '海鲜酱');
SELECT add_chinese_alias_if_missing('Fish Sauce', '鱼露');
SELECT add_chinese_alias_if_missing('Oyster Sauce', '蚝油');
SELECT add_chinese_alias_if_missing('Tomato Paste', '番茄酱');
SELECT add_chinese_alias_if_missing('Tomato Sauce', '番茄沙司');
SELECT add_chinese_alias_if_missing('Crushed Tomatoes', '碎番茄');
SELECT add_chinese_alias_if_missing('Diced Tomatoes', '番茄丁');
SELECT add_chinese_alias_if_missing('Salsa', '莎莎酱');
SELECT add_chinese_alias_if_missing('Guacamole', '鳄梨酱');
SELECT add_chinese_alias_if_missing('Hummus', '鹰嘴豆泥');
SELECT add_chinese_alias_if_missing('Tahini', '芝麻酱');
SELECT add_chinese_alias_if_missing('Miso Paste', '味噌酱');

-- Sweeteners & Baking - Additional varieties
SELECT add_chinese_alias_if_missing('Brown Sugar', '红糖');
SELECT add_chinese_alias_if_missing('Powdered Sugar', '糖粉');
SELECT add_chinese_alias_if_missing('Maple Syrup', '枫糖浆');
SELECT add_chinese_alias_if_missing('Agave Nectar', '龙舌兰花蜜');
SELECT add_chinese_alias_if_missing('Molasses', '糖蜜');
SELECT add_chinese_alias_if_missing('Stevia', '甜菊糖');
SELECT add_chinese_alias_if_missing('Baking Soda', '小苏打');
SELECT add_chinese_alias_if_missing('Baking Powder', '泡打粉');
SELECT add_chinese_alias_if_missing('Active Dry Yeast', '活性干酵母');
SELECT add_chinese_alias_if_missing('Instant Yeast', '速溶酵母');
SELECT add_chinese_alias_if_missing('Cornstarch', '玉米淀粉');
SELECT add_chinese_alias_if_missing('Arrowroot', '竹芋粉');
SELECT add_chinese_alias_if_missing('Cocoa Powder', '可可粉');
SELECT add_chinese_alias_if_missing('Dark Chocolate', '黑巧克力');
SELECT add_chinese_alias_if_missing('Milk Chocolate', '牛奶巧克力');
SELECT add_chinese_alias_if_missing('White Chocolate', '白巧克力');
SELECT add_chinese_alias_if_missing('Chocolate Chips', '巧克力豆');
SELECT add_chinese_alias_if_missing('Vanilla Beans', '香草豆');

-- Canned & Packaged Goods - Additional varieties
SELECT add_chinese_alias_if_missing('Beef Broth', '牛肉汤');
SELECT add_chinese_alias_if_missing('Vegetable Broth', '蔬菜汤');
SELECT add_chinese_alias_if_missing('Coconut Cream', '椰浆');
SELECT add_chinese_alias_if_missing('Evaporated Milk', '淡奶');
SELECT add_chinese_alias_if_missing('Condensed Milk', '炼乳');
SELECT add_chinese_alias_if_missing('Canned Corn', '玉米罐头');
SELECT add_chinese_alias_if_missing('Canned Beans', '豆类罐头');
SELECT add_chinese_alias_if_missing('Canned Tuna', '金枪鱼罐头');
SELECT add_chinese_alias_if_missing('Canned Salmon', '三文鱼罐头');
SELECT add_chinese_alias_if_missing('Anchovies', '凤尾鱼');
SELECT add_chinese_alias_if_missing('Capers', '酸豆');
SELECT add_chinese_alias_if_missing('Green Olives', '绿橄榄');
SELECT add_chinese_alias_if_missing('Black Olives', '黑橄榄');
SELECT add_chinese_alias_if_missing('Kalamata Olives', '卡拉马塔橄榄');
SELECT add_chinese_alias_if_missing('Artichoke Hearts', '朝鲜蓟心');
SELECT add_chinese_alias_if_missing('Sun-Dried Tomatoes', '番茄干');
SELECT add_chinese_alias_if_missing('Roasted Red Peppers', '烤红椒');
SELECT add_chinese_alias_if_missing('Pickles', '腌黄瓜');
SELECT add_chinese_alias_if_missing('Chipotle Peppers', '烟熏辣椒');

-- Frozen Foods - Additional varieties
SELECT add_chinese_alias_if_missing('Frozen Corn', '冷冻玉米');
SELECT add_chinese_alias_if_missing('Frozen Broccoli', '冷冻西兰花');
SELECT add_chinese_alias_if_missing('Frozen Spinach', '冷冻菠菜');
SELECT add_chinese_alias_if_missing('Frozen Berries', '冷冻浆果');
SELECT add_chinese_alias_if_missing('Frozen Mixed Vegetables', '冷冻混合蔬菜');
SELECT add_chinese_alias_if_missing('Frozen French Fries', '冷冻薯条');
SELECT add_chinese_alias_if_missing('Frozen Hash Browns', '冷冻薯饼');
SELECT add_chinese_alias_if_missing('Frozen Yogurt', '冷冻酸奶');
SELECT add_chinese_alias_if_missing('Frozen Pizza Dough', '冷冻披萨面团');
SELECT add_chinese_alias_if_missing('Frozen Pie Crust', '冷冻派皮');

-- Clean up the function
DROP FUNCTION add_chinese_alias_if_missing(text, text);

-- Show final results
SELECT 
  'FINAL SUMMARY' as report_type,
  (SELECT COUNT(*) FROM public.ingredients) as total_ingredients,
  (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
   WHERE EXISTS (
     SELECT 1 FROM public.ingredient_terms it 
     WHERE it.ingredient_id = i.id AND it.locale = 'zh'
   )) as ingredients_with_chinese,
  (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
   WHERE NOT EXISTS (
     SELECT 1 FROM public.ingredient_terms it 
     WHERE it.ingredient_id = i.id AND it.locale = 'zh'
   )) as ingredients_without_chinese,
  ROUND(
    (SELECT COUNT(DISTINCT i.id) FROM public.ingredients i
     WHERE EXISTS (
       SELECT 1 FROM public.ingredient_terms it 
       WHERE it.ingredient_id = i.id AND it.locale = 'zh'
     ))::numeric / 
    (SELECT COUNT(*) FROM public.ingredients)::numeric * 100, 
    2
  ) as percentage_with_chinese;
