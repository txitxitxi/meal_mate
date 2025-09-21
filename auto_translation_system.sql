-- Auto-translation system for new English ingredients
-- This creates an automated system to add Chinese aliases when new English ingredients are added

-- 1. Create a translation mapping table for common ingredients
CREATE TABLE IF NOT EXISTS public.ingredient_translations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    english_name text NOT NULL UNIQUE,
    chinese_name text NOT NULL,
    category text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 2. Populate the translation table with common ingredient mappings
INSERT INTO public.ingredient_translations (english_name, chinese_name, category) VALUES
-- Meat & Poultry
('Beef', '牛肉', 'meat'),
('Chicken', '鸡肉', 'meat'),
('Pork', '猪肉', 'meat'),
('Lamb', '羊肉', 'meat'),
('Turkey', '火鸡', 'meat'),
('Duck', '鸭肉', 'meat'),
('Ground Beef', '牛肉馅', 'meat'),
('Ground Pork', '猪肉馅', 'meat'),
('Ground Turkey', '火鸡肉馅', 'meat'),
('Ground Lamb', '羊肉馅', 'meat'),
('Ground Chicken', '鸡肉馅', 'meat'),
('Chicken Breast', '鸡胸肉', 'meat'),
('Chicken Thighs', '鸡腿', 'meat'),
('Chicken Wings', '鸡翅', 'meat'),
('Chicken Drumsticks', '鸡腿', 'meat'),
('Beef Steak', '牛排', 'meat'),
('Pork Chops', '猪排', 'meat'),
('Lamb Chops', '羊排', 'meat'),
('Bacon', '培根', 'meat'),
('Ham', '火腿', 'meat'),
('Sausage', '香肠', 'meat'),
('Hotpot Beef', '火锅牛肉', 'meat'),
('Hotpot Lamb', '火锅羊肉', 'meat'),

-- Seafood
('Fish', '鱼', 'seafood'),
('Salmon', '三文鱼', 'seafood'),
('Tuna', '金枪鱼', 'seafood'),
('Shrimp', '虾', 'seafood'),
('Crab', '螃蟹', 'seafood'),
('Lobster', '龙虾', 'seafood'),
('Scallops', '扇贝', 'seafood'),
('Mussels', '青口贝', 'seafood'),
('Clams', '蛤蜊', 'seafood'),
('Oysters', '牡蛎', 'seafood'),
('Calamari', '鱿鱼', 'seafood'),
('Cod', '鳕鱼', 'seafood'),
('Halibut', '比目鱼', 'seafood'),
('Trout', '鳟鱼', 'seafood'),
('Sea Bass', '鲈鱼', 'seafood'),
('Mackerel', '鲭鱼', 'seafood'),
('Sardines', '沙丁鱼', 'seafood'),
('Anchovies', '凤尾鱼', 'seafood'),

-- Dairy & Eggs
('Milk', '牛奶', 'dairy'),
('Whole Milk', '全脂牛奶', 'dairy'),
('2% Milk', '2%牛奶', 'dairy'),
('Skim Milk', '脱脂牛奶', 'dairy'),
('Cream', '奶油', 'dairy'),
('Heavy Cream', '重奶油', 'dairy'),
('Half and Half', '半奶油半牛奶', 'dairy'),
('Butter', '黄油', 'dairy'),
('Unsalted Butter', '无盐黄油', 'dairy'),
('Margarine', '人造黄油', 'dairy'),
('Cheese', '奶酪', 'dairy'),
('Cheddar Cheese', '切达奶酪', 'dairy'),
('Mozzarella Cheese', '马苏里拉奶酪', 'dairy'),
('Parmesan Cheese', '帕尔马奶酪', 'dairy'),
('Feta Cheese', '羊奶酪', 'dairy'),
('Ricotta Cheese', '里科塔奶酪', 'dairy'),
('Cream Cheese', '奶油奶酪', 'dairy'),
('Sour Cream', '酸奶油', 'dairy'),
('Yogurt', '酸奶', 'dairy'),
('Greek Yogurt', '希腊酸奶', 'dairy'),
('Plain Yogurt', '原味酸奶', 'dairy'),
('Goat Yogurt', '山羊酸奶', 'dairy'),
('Buttermilk', '酪乳', 'dairy'),
('Eggs', '鸡蛋', 'dairy'),
('Egg', '鸡蛋', 'dairy'),
('Egg Whites', '蛋白', 'dairy'),
('Egg Yolks', '蛋黄', 'dairy'),

-- Vegetables
('Onions', '洋葱', 'vegetable'),
('Yellow Onions', '黄洋葱', 'vegetable'),
('Red Onions', '红洋葱', 'vegetable'),
('Sweet Onions', '甜洋葱', 'vegetable'),
('Green Onions', '青葱', 'vegetable'),
('Bell Peppers', '甜椒', 'vegetable'),
('Red Bell Peppers', '红椒', 'vegetable'),
('Green Bell Peppers', '青椒', 'vegetable'),
('Yellow Bell Peppers', '黄椒', 'vegetable'),
('Green Pepper', '青椒', 'vegetable'),
('Jalapeños', '墨西哥胡椒', 'vegetable'),
('Tomatoes', '西红柿', 'vegetable'),
('Cherry Tomatoes', '圣女果', 'vegetable'),
('Roma Tomatoes', '罗马番茄', 'vegetable'),
('Cucumbers', '黄瓜', 'vegetable'),
('Lettuce', '生菜', 'vegetable'),
('Romaine Lettuce', '罗马生菜', 'vegetable'),
('Iceberg Lettuce', '卷心菜生菜', 'vegetable'),
('Spinach', '菠菜', 'vegetable'),
('Baby Spinach', '嫩菠菜', 'vegetable'),
('Kale', '羽衣甘蓝', 'vegetable'),
('Arugula', '芝麻菜', 'vegetable'),
('Watercress', '西洋菜', 'vegetable'),
('Bok Choy', '小白菜', 'vegetable'),
('Chinese Cabbage', '大白菜', 'vegetable'),
('Napa Cabbage', '娃娃菜', 'vegetable'),
('Cabbage', '卷心菜', 'vegetable'),
('Red Cabbage', '红卷心菜', 'vegetable'),
('Cauliflower', '花椰菜', 'vegetable'),
('Broccoli', '西兰花', 'vegetable'),
('Brussels Sprouts', '球芽甘蓝', 'vegetable'),
('Potatoes', '土豆', 'vegetable'),
('Russet Potatoes', '褐色土豆', 'vegetable'),
('Red Potatoes', '红土豆', 'vegetable'),
('Yukon Gold Potatoes', '黄金土豆', 'vegetable'),
('Sweet Potatoes', '红薯', 'vegetable'),
('Mushrooms', '蘑菇', 'vegetable'),
('White Mushrooms', '白蘑菇', 'vegetable'),
('Portobello Mushrooms', '大蘑菇', 'vegetable'),
('Shiitake Mushrooms', '香菇', 'vegetable'),
('Eggplant', '茄子', 'vegetable'),
('Zucchini', '西葫芦', 'vegetable'),
('Squash', '南瓜', 'vegetable'),
('Butternut Squash', '南瓜', 'vegetable'),
('Asparagus', '芦笋', 'vegetable'),
('Peas', '豌豆', 'vegetable'),
('Snow Peas', '荷兰豆', 'vegetable'),
('Frozen Peas', '冷冻豌豆', 'frozen'),
('Corn', '玉米', 'vegetable'),
('Avocado', '鳄梨', 'vegetable'),
('Carrots', '胡萝卜', 'vegetable'),
('Radishes', '萝卜', 'vegetable'),
('Daikon Radish', '白萝卜', 'vegetable'),
('Beets', '甜菜', 'vegetable'),
('Turnips', '芜菁', 'vegetable'),
('Jicama', '豆薯', 'vegetable'),
('Fennel', '茴香', 'vegetable'),
('Leeks', '韭葱', 'vegetable'),
('Shallots', '小葱', 'vegetable'),
('Scallions', '青葱', 'vegetable'),
('Chives', '细香葱', 'vegetable'),
('Cilantro', '香菜', 'vegetable'),
('Parsley', '欧芹', 'vegetable'),
('Basil', '罗勒', 'vegetable'),
('Thyme', '百里香', 'vegetable'),
('Rosemary', '迷迭香', 'vegetable'),
('Oregano', '牛至', 'vegetable'),
('Mint', '薄荷', 'vegetable'),
('Sage', '鼠尾草', 'vegetable'),
('Tarragon', '龙蒿', 'vegetable'),
('Dill', '莳萝', 'vegetable'),
('Marjoram', '马郁兰', 'vegetable'),
('Bay Leaves', '月桂叶', 'vegetable'),
('Lemongrass', '柠檬草', 'vegetable'),
('Ginger', '姜', 'vegetable'),
('Garlic', '大蒜', 'vegetable'),
('Lotus Root', '莲藕', 'other'),
('Lotus Rooot', '莲藕', 'other'),

-- Fruits
('Apples', '苹果', 'fruit'),
('Red Apples', '红苹果', 'fruit'),
('Green Apples', '青苹果', 'fruit'),
('Oranges', '橙子', 'fruit'),
('Bananas', '香蕉', 'fruit'),
('Lemons', '柠檬', 'fruit'),
('Limes', '青柠', 'fruit'),
('Grapefruit', '葡萄柚', 'fruit'),
('Grapes', '葡萄', 'fruit'),
('Strawberries', '草莓', 'fruit'),
('Blueberries', '蓝莓', 'fruit'),
('Raspberries', '树莓', 'fruit'),
('Blackberries', '黑莓', 'fruit'),
('Cherries', '樱桃', 'fruit'),
('Peaches', '桃子', 'fruit'),
('Pears', '梨', 'fruit'),
('Plums', '李子', 'fruit'),
('Apricots', '杏子', 'fruit'),
('Mangoes', '芒果', 'fruit'),
('Pineapple', '菠萝', 'fruit'),
('Watermelon', '西瓜', 'fruit'),
('Cantaloupe', '哈密瓜', 'fruit'),
('Honeydew', '蜜瓜', 'fruit'),
('Kiwi', '猕猴桃', 'fruit'),
('Pomegranate', '石榴', 'fruit'),
('Cranberries', '蔓越莓', 'fruit'),
('Raisins', '葡萄干', 'fruit'),
('Dates', '椰枣', 'fruit'),

-- Grains & Starches
('Rice', '米饭', 'grain'),
('White Rice', '白米', 'grain'),
('Brown Rice', '糙米', 'grain'),
('Jasmine Rice', '茉莉香米', 'grain'),
('Basmati Rice', '印度香米', 'grain'),
('Wild Rice', '野米', 'grain'),
('Arborio Rice', '意大利米', 'grain'),
('Pasta', '意大利面', 'grain'),
('Spaghetti', '意大利面', 'grain'),
('Penne', '通心粉', 'grain'),
('Fettuccine', '宽面条', 'grain'),
('Macaroni', '通心粉', 'grain'),
('Fusilli', '螺旋面', 'grain'),
('Rigatoni', '粗管面', 'grain'),
('Lasagna Noodles', '千层面', 'grain'),
('Ravioli', '意大利饺子', 'grain'),
('Tortellini', '意大利馄饨', 'grain'),
('Tortillas', '墨西哥饼', 'grain'),
('Bread', '面包', 'grain'),
('White Bread', '白面包', 'grain'),
('Whole Wheat Bread', '全麦面包', 'grain'),
('Sourdough Bread', '酸面包', 'grain'),
('French Bread', '法式面包', 'grain'),
('Bagels', '贝果', 'grain'),
('English Muffins', '英式松饼', 'grain'),
('Flour Tortillas', '面粉饼', 'grain'),
('Corn Tortillas', '玉米饼', 'grain'),
('Flour', '面粉', 'grain'),
('All-Purpose Flour', '通用面粉', 'grain'),
('Whole Wheat Flour', '全麦面粉', 'grain'),
('Bread Flour', '面包粉', 'grain'),
('Cake Flour', '蛋糕粉', 'grain'),
('Almond Flour', '杏仁粉', 'grain'),
('Coconut Flour', '椰子粉', 'grain'),
('Oats', '燕麦', 'grain'),
('Rolled Oats', '燕麦片', 'grain'),
('Steel Cut Oats', '钢切燕麦', 'grain'),
('Barley', '大麦', 'grain'),
('Bulgur', '布格麦', 'grain'),
('Couscous', '古斯米', 'grain'),
('Polenta', '玉米粥', 'grain'),
('Quinoa', '藜麦', 'grain'),

-- Legumes & Nuts
('Beans', '豆类', 'legume'),
('Black Beans', '黑豆', 'legume'),
('Kidney Beans', '芸豆', 'legume'),
('Pinto Beans', '斑豆', 'legume'),
('Navy Beans', '白豆', 'legume'),
('Chickpeas', '鹰嘴豆', 'legume'),
('Lentils', '扁豆', 'legume'),
('Red Lentils', '红扁豆', 'legume'),
('Green Lentils', '绿扁豆', 'legume'),
('Black Lentils', '黑扁豆', 'legume'),
('Split Peas', '豌豆', 'legume'),
('Lima Beans', '利马豆', 'legume'),
('Black-Eyed Peas', '豇豆', 'legume'),
('Tofu', '豆腐', 'legume'),
('Tempeh', '天贝', 'legume'),
('Edamame', '毛豆', 'legume'),
('Nuts', '坚果', 'legume'),
('Almonds', '杏仁', 'legume'),
('Walnuts', '核桃', 'legume'),
('Pecans', '山核桃', 'legume'),
('Pistachios', '开心果', 'legume'),
('Hazelnuts', '榛子', 'legume'),
('Macadamia Nuts', '夏威夷果', 'legume'),
('Brazil Nuts', '巴西坚果', 'legume'),
('Pine Nuts', '松子', 'legume'),
('Cashews', '腰果', 'legume'),
('Peanuts', '花生', 'legume'),
('Seeds', '种子', 'legume'),
('Sunflower Seeds', '葵花籽', 'legume'),
('Pumpkin Seeds', '南瓜籽', 'legume'),
('Sesame Seeds', '芝麻', 'legume'),
('Chia Seeds', '奇亚籽', 'legume'),
('Flax Seeds', '亚麻籽', 'legume'),
('Hemp Seeds', '大麻籽', 'legume'),

-- Herbs & Spices
('Salt', '盐', 'spice'),
('Sea Salt', '海盐', 'spice'),
('Kosher Salt', '粗盐', 'spice'),
('Pepper', '胡椒', 'spice'),
('Black Pepper', '黑胡椒', 'spice'),
('White Pepper', '白胡椒', 'spice'),
('Cayenne Pepper', '辣椒粉', 'spice'),
('Paprika', '辣椒粉', 'spice'),
('Smoked Paprika', '烟熏辣椒粉', 'spice'),
('Chili Powder', '辣椒粉', 'spice'),
('Cumin', '孜然', 'spice'),
('Coriander', '香菜籽', 'spice'),
('Turmeric', '姜黄', 'spice'),
('Cinnamon', '肉桂', 'spice'),
('Nutmeg', '肉豆蔻', 'spice'),
('Allspice', '多香果', 'spice'),
('Cloves', '丁香', 'spice'),
('Cardamom', '豆蔻', 'spice'),
('Star Anise', '八角', 'spice'),
('Fennel Seeds', '茴香籽', 'spice'),
('Mustard Seeds', '芥菜籽', 'spice'),
('Poppy Seeds', '罂粟籽', 'spice'),
('Caraway Seeds', '葛缕子', 'spice'),
('Italian Seasoning', '意大利调料', 'spice'),
('Herbs de Provence', '普罗旺斯香草', 'spice'),
('Old Bay Seasoning', '老湾调料', 'spice'),
('Garlic Powder', '大蒜粉', 'spice'),
('Onion Powder', '洋葱粉', 'spice'),
('Mustard Powder', '芥末粉', 'spice'),
('Red Pepper Flakes', '红辣椒片', 'spice'),
('Vanilla Extract', '香草精', 'spice'),
('Almond Extract', '杏仁精', 'spice'),

-- Oils & Vinegars
('Oil', '油', 'oil'),
('Olive Oil', '橄榄油', 'oil'),
('Extra Virgin Olive Oil', '特级初榨橄榄油', 'oil'),
('Vegetable Oil', '植物油', 'oil'),
('Canola Oil', '菜籽油', 'oil'),
('Avocado Oil', '鳄梨油', 'oil'),
('Grape Seed Oil', '葡萄籽油', 'oil'),
('Sunflower Oil', '葵花籽油', 'oil'),
('Peanut Oil', '花生油', 'oil'),
('Sesame Oil', '芝麻油', 'oil'),
('Coconut Oil', '椰子油', 'oil'),
('Lard', '猪油', 'oil'),
('Shortening', '起酥油', 'oil'),
('Vinegar', '醋', 'oil'),
('White Vinegar', '白醋', 'oil'),
('Apple Cider Vinegar', '苹果醋', 'oil'),
('Red Wine Vinegar', '红酒醋', 'oil'),
('White Wine Vinegar', '白酒醋', 'oil'),
('Rice Vinegar', '米醋', 'oil'),
('Balsamic Vinegar', '香醋', 'oil'),
('Sherry Vinegar', '雪利醋', 'oil'),
('Lemon Juice', '柠檬汁', 'oil'),
('Lime Juice', '青柠汁', 'oil'),

-- Condiments & Sauces
('Ketchup', '番茄酱', 'condiment'),
('Mustard', '芥末', 'condiment'),
('Dijon Mustard', '第戎芥末', 'condiment'),
('Whole Grain Mustard', '全粒芥末', 'condiment'),
('Mayonnaise', '蛋黄酱', 'condiment'),
('Worcestershire Sauce', '伍斯特沙司', 'condiment'),
('Hot Sauce', '辣酱', 'condiment'),
('Tabasco Sauce', '塔巴斯科辣酱', 'condiment'),
('Sriracha', '是拉差辣酱', 'condiment'),
('Barbecue Sauce', '烧烤酱', 'condiment'),
('Teriyaki Sauce', '照烧酱', 'condiment'),
('Soy Sauce', '酱油', 'condiment'),
('Pesto', '香蒜酱', 'condiment'),
('Hoisin Sauce', '海鲜酱', 'condiment'),
('Fish Sauce', '鱼露', 'condiment'),
('Oyster Sauce', '蚝油', 'condiment'),
('Tomato Paste', '番茄酱', 'condiment'),
('Tomato Sauce', '番茄沙司', 'condiment'),
('Crushed Tomatoes', '碎番茄', 'condiment'),
('Diced Tomatoes', '番茄丁', 'condiment'),
('Salsa', '莎莎酱', 'condiment'),
('Guacamole', '鳄梨酱', 'condiment'),
('Hummus', '鹰嘴豆泥', 'condiment'),
('Tahini', '芝麻酱', 'condiment'),
('Miso Paste', '味噌酱', 'condiment'),

-- Sweeteners & Baking
('Sugar', '糖', 'sweetener'),
('Brown Sugar', '红糖', 'sweetener'),
('Powdered Sugar', '糖粉', 'sweetener'),
('Honey', '蜂蜜', 'sweetener'),
('Maple Syrup', '枫糖浆', 'sweetener'),
('Agave Nectar', '龙舌兰花蜜', 'sweetener'),
('Molasses', '糖蜜', 'sweetener'),
('Stevia', '甜菊糖', 'sweetener'),
('Baking Soda', '小苏打', 'baking'),
('Baking Powder', '泡打粉', 'baking'),
('Yeast', '酵母', 'baking'),
('Active Dry Yeast', '活性干酵母', 'baking'),
('Instant Yeast', '速溶酵母', 'baking'),
('Cornstarch', '玉米淀粉', 'baking'),
('Arrowroot', '竹芋粉', 'baking'),
('Cocoa Powder', '可可粉', 'baking'),
('Chocolate', '巧克力', 'baking'),
('Dark Chocolate', '黑巧克力', 'baking'),
('Milk Chocolate', '牛奶巧克力', 'baking'),
('White Chocolate', '白巧克力', 'baking'),
('Chocolate Chips', '巧克力豆', 'baking'),
('Vanilla Beans', '香草豆', 'baking'),

-- Canned & Packaged Goods
('Broth', '汤', 'canned'),
('Chicken Broth', '鸡汤', 'canned'),
('Beef Broth', '牛肉汤', 'canned'),
('Vegetable Broth', '蔬菜汤', 'canned'),
('Coconut Milk', '椰浆', 'canned'),
('Coconut Cream', '椰浆', 'canned'),
('Evaporated Milk', '淡奶', 'canned'),
('Condensed Milk', '炼乳', 'canned'),
('Canned Corn', '玉米罐头', 'canned'),
('Canned Beans', '豆类罐头', 'canned'),
('Canned Tuna', '金枪鱼罐头', 'canned'),
('Canned Salmon', '三文鱼罐头', 'canned'),
('Capers', '酸豆', 'canned'),
('Olives', '橄榄', 'canned'),
('Green Olives', '绿橄榄', 'canned'),
('Black Olives', '黑橄榄', 'canned'),
('Kalamata Olives', '卡拉马塔橄榄', 'canned'),
('Artichoke Hearts', '朝鲜蓟心', 'canned'),
('Sun-Dried Tomatoes', '番茄干', 'canned'),
('Roasted Red Peppers', '烤红椒', 'canned'),
('Pickles', '腌黄瓜', 'canned'),
('Chipotle Peppers', '烟熏辣椒', 'canned'),

-- Frozen Foods
('Frozen Corn', '冷冻玉米', 'frozen'),
('Frozen Broccoli', '冷冻西兰花', 'frozen'),
('Frozen Spinach', '冷冻菠菜', 'frozen'),
('Frozen Berries', '冷冻浆果', 'frozen'),
('Frozen Mixed Vegetables', '冷冻混合蔬菜', 'frozen'),
('Frozen French Fries', '冷冻薯条', 'frozen'),
('Frozen Hash Browns', '冷冻薯饼', 'frozen'),
('Frozen Yogurt', '冷冻酸奶', 'frozen'),
('Frozen Pizza Dough', '冷冻披萨面团', 'frozen'),
('Frozen Pie Crust', '冷冻派皮', 'frozen')

ON CONFLICT (english_name) DO UPDATE SET 
    chinese_name = EXCLUDED.chinese_name,
    category = EXCLUDED.category,
    updated_at = now();

-- 3. Create function to auto-translate ingredients
CREATE OR REPLACE FUNCTION auto_translate_ingredient()
RETURNS trigger AS $$
DECLARE
    translation_record RECORD;
BEGIN
    -- Look for exact match first
    SELECT * INTO translation_record
    FROM public.ingredient_translations
    WHERE LOWER(english_name) = LOWER(NEW.name);
    
    -- If exact match found, add Chinese alias
    IF FOUND THEN
        INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
        VALUES (NEW.id, translation_record.chinese_name, 'zh', true, 10)
        ON CONFLICT (ingredient_id, term, locale) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Create trigger to automatically add Chinese aliases
CREATE OR REPLACE TRIGGER trigger_auto_translate_ingredient
    AFTER INSERT ON public.ingredients
    FOR EACH ROW
    EXECUTE FUNCTION auto_translate_ingredient();

-- 5. Create function to manually add translations to the mapping table
CREATE OR REPLACE FUNCTION add_ingredient_translation(
    english_name_param text,
    chinese_name_param text,
    category_param text DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.ingredient_translations (english_name, chinese_name, category)
    VALUES (english_name_param, chinese_name_param, category_param)
    ON CONFLICT (english_name) DO UPDATE SET
        chinese_name = EXCLUDED.chinese_name,
        category = EXCLUDED.category,
        updated_at = now();
END;
$$ LANGUAGE plpgsql;

-- 6. Create function to retroactively translate existing ingredients
CREATE OR REPLACE FUNCTION retroactively_translate_ingredients()
RETURNS TABLE(
    ingredient_id uuid,
    english_name text,
    chinese_name text,
    translated boolean
) AS $$
BEGIN
    RETURN QUERY
    WITH translations AS (
        SELECT 
            i.id,
            i.name,
            it.chinese_name,
            CASE 
                WHEN EXISTS (
                    SELECT 1 FROM public.ingredient_terms it2 
                    WHERE it2.ingredient_id = i.id AND it2.locale = 'zh'
                ) THEN true 
                ELSE false 
            END as already_translated
        FROM public.ingredients i
        JOIN public.ingredient_translations it ON LOWER(i.name) = LOWER(it.english_name)
        WHERE NOT EXISTS (
            SELECT 1 FROM public.ingredient_terms it3 
            WHERE it3.ingredient_id = i.id AND it3.locale = 'zh'
        )
    )
    SELECT 
        t.id,
        t.name,
        t.chinese_name,
        false as translated
    FROM translations t
    WHERE NOT t.already_translated;
END;
$$ LANGUAGE plpgsql;

-- 7. Create function to apply retroactive translations
CREATE OR REPLACE FUNCTION apply_retroactive_translations()
RETURNS integer AS $$
DECLARE
    translation_count integer := 0;
    rec RECORD;
BEGIN
    FOR rec IN SELECT * FROM retroactively_translate_ingredients()
    LOOP
        INSERT INTO public.ingredient_terms (ingredient_id, term, locale, is_primary, weight)
        VALUES (rec.ingredient_id, rec.chinese_name, 'zh', true, 10)
        ON CONFLICT (ingredient_id, term, locale) DO NOTHING;
        
        translation_count := translation_count + 1;
    END LOOP;
    
    RETURN translation_count;
END;
$$ LANGUAGE plpgsql;

-- 8. Set up RLS for the translation table
ALTER TABLE public.ingredient_translations ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read translations
CREATE POLICY "Allow read access to ingredient_translations" ON public.ingredient_translations
    FOR SELECT USING (true);

-- Allow service role to manage translations
CREATE POLICY "Allow service role to manage ingredient_translations" ON public.ingredient_translations
    FOR ALL USING (auth.role() = 'service_role');

-- 9. Create updated_at trigger for ingredient_translations
CREATE OR REPLACE FUNCTION update_ingredient_translations_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ingredient_translations_updated_at
    BEFORE UPDATE ON public.ingredient_translations
    FOR EACH ROW
    EXECUTE FUNCTION update_ingredient_translations_updated_at();

-- 10. Test the system by checking how many ingredients would be auto-translated
SELECT 
    'AUTO-TRANSLATION SYSTEM READY' as status,
    COUNT(*) as total_translations_available,
    (SELECT COUNT(*) FROM public.ingredients i 
     WHERE EXISTS (
         SELECT 1 FROM public.ingredient_translations it 
         WHERE LOWER(i.name) = LOWER(it.english_name)
     )) as ingredients_with_translations,
    (SELECT COUNT(*) FROM public.ingredients i 
     WHERE NOT EXISTS (
         SELECT 1 FROM public.ingredient_terms it 
         WHERE it.ingredient_id = i.id AND it.locale = 'zh'
     )) as ingredients_still_missing_chinese;

-- 11. Apply retroactive translations to existing ingredients
SELECT apply_retroactive_translations() as retroactive_translations_applied;
