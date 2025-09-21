-- Add common English ingredients to the database (Safe Version)
-- This script adds a comprehensive list of common cooking ingredients
-- Uses a safer approach that won't fail if constraints don't exist

-- Meat & Poultry
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Chicken Breast', 'poultry', 'lb'),
('Chicken Thighs', 'poultry', 'lb'),
('Ground Chicken', 'poultry', 'lb'),
('Whole Chicken', 'poultry', 'whole'),
('Turkey Breast', 'poultry', 'lb'),
('Ground Turkey', 'poultry', 'lb'),
('Duck Breast', 'poultry', 'lb'),
('Beef Steak', 'meat', 'lb'),
('Ground Beef', 'meat', 'lb'),
('Beef Roast', 'meat', 'lb'),
('Beef Ribs', 'meat', 'lb'),
('Beef Brisket', 'meat', 'lb'),
('Pork Chops', 'meat', 'lb'),
('Ground Pork', 'meat', 'lb'),
('Pork Tenderloin', 'meat', 'lb'),
('Pork Shoulder', 'meat', 'lb'),
('Bacon', 'meat', 'slice'),
('Ham', 'meat', 'lb'),
('Sausage', 'meat', 'lb'),
('Lamb Chops', 'meat', 'lb'),
('Ground Lamb', 'meat', 'lb'),
('Lamb Shoulder', 'meat', 'lb')
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Seafood
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Salmon Fillet', 'fish', 'lb'),
('Cod Fillet', 'fish', 'lb'),
('Tuna Steak', 'fish', 'lb'),
('Halibut', 'fish', 'lb'),
('Trout', 'fish', 'lb'),
('Shrimp', 'seafood', 'lb'),
('Crab', 'seafood', 'lb'),
('Lobster', 'seafood', 'whole'),
('Scallops', 'seafood', 'lb'),
('Mussels', 'seafood', 'lb'),
('Clams', 'seafood', 'lb'),
('Oysters', 'seafood', 'dozen'),
('Calamari', 'seafood', 'lb'),
('Tilapia', 'fish', 'lb'),
('Mahi Mahi', 'fish', 'lb')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Dairy Products
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Whole Milk', 'dairy', 'cup'),
('2% Milk', 'dairy', 'cup'),
('Skim Milk', 'dairy', 'cup'),
('Heavy Cream', 'dairy', 'cup'),
('Half and Half', 'dairy', 'cup'),
('Butter', 'dairy', 'tbsp'),
('Unsalted Butter', 'dairy', 'tbsp'),
('Margarine', 'dairy', 'tbsp'),
('Cheddar Cheese', 'dairy', 'cup'),
('Mozzarella Cheese', 'dairy', 'cup'),
('Parmesan Cheese', 'dairy', 'cup'),
('Feta Cheese', 'dairy', 'cup'),
('Ricotta Cheese', 'dairy', 'cup'),
('Cream Cheese', 'dairy', 'oz'),
('Sour Cream', 'dairy', 'cup'),
('Greek Yogurt', 'dairy', 'cup'),
('Plain Yogurt', 'dairy', 'cup'),
('Buttermilk', 'dairy', 'cup')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Vegetables
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Onions', 'vegetable', 'whole'),
('Yellow Onions', 'vegetable', 'whole'),
('Red Onions', 'vegetable', 'whole'),
('Sweet Onions', 'vegetable', 'whole'),
('Green Onions', 'vegetable', 'bunch'),
('Garlic', 'vegetable', 'clove'),
('Ginger', 'vegetable', 'inch'),
('Carrots', 'vegetable', 'whole'),
('Celery', 'vegetable', 'stalk'),
('Bell Peppers', 'vegetable', 'whole'),
('Red Bell Peppers', 'vegetable', 'whole'),
('Green Bell Peppers', 'vegetable', 'whole'),
('Yellow Bell Peppers', 'vegetable', 'whole'),
('Jalapeños', 'vegetable', 'whole'),
('Tomatoes', 'vegetable', 'whole'),
('Cherry Tomatoes', 'vegetable', 'cup'),
('Roma Tomatoes', 'vegetable', 'whole'),
('Cucumbers', 'vegetable', 'whole'),
('Lettuce', 'vegetable', 'head'),
('Romaine Lettuce', 'vegetable', 'head'),
('Iceberg Lettuce', 'vegetable', 'head'),
('Spinach', 'vegetable', 'cup'),
('Kale', 'vegetable', 'cup'),
('Arugula', 'vegetable', 'cup'),
('Broccoli', 'vegetable', 'cup'),
('Cauliflower', 'vegetable', 'cup'),
('Brussels Sprouts', 'vegetable', 'cup'),
('Cabbage', 'vegetable', 'head'),
('Red Cabbage', 'vegetable', 'head'),
('Potatoes', 'vegetable', 'whole'),
('Russet Potatoes', 'vegetable', 'whole'),
('Red Potatoes', 'vegetable', 'whole'),
('Sweet Potatoes', 'vegetable', 'whole'),
('Yukon Gold Potatoes', 'vegetable', 'whole'),
('Mushrooms', 'vegetable', 'cup'),
('White Mushrooms', 'vegetable', 'cup'),
('Portobello Mushrooms', 'vegetable', 'whole'),
('Shiitake Mushrooms', 'vegetable', 'cup'),
('Eggplant', 'vegetable', 'whole'),
('Zucchini', 'vegetable', 'whole'),
('Squash', 'vegetable', 'whole'),
('Butternut Squash', 'vegetable', 'whole'),
('Asparagus', 'vegetable', 'bunch'),
('Green Beans', 'vegetable', 'cup'),
('Snow Peas', 'vegetable', 'cup'),
('Corn', 'vegetable', 'cup'),
('Avocado', 'vegetable', 'whole'),
('Radishes', 'vegetable', 'cup'),
('Beets', 'vegetable', 'whole'),
('Turnips', 'vegetable', 'whole')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Fruits
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Apples', 'fruit', 'whole'),
('Red Apples', 'fruit', 'whole'),
('Green Apples', 'fruit', 'whole'),
('Bananas', 'fruit', 'whole'),
('Oranges', 'fruit', 'whole'),
('Lemons', 'fruit', 'whole'),
('Limes', 'fruit', 'whole'),
('Grapefruit', 'fruit', 'whole'),
('Grapes', 'fruit', 'cup'),
('Strawberries', 'fruit', 'cup'),
('Blueberries', 'fruit', 'cup'),
('Raspberries', 'fruit', 'cup'),
('Blackberries', 'fruit', 'cup'),
('Cherries', 'fruit', 'cup'),
('Peaches', 'fruit', 'whole'),
('Pears', 'fruit', 'whole'),
('Plums', 'fruit', 'whole'),
('Apricots', 'fruit', 'whole'),
('Mangoes', 'fruit', 'whole'),
('Pineapple', 'fruit', 'cup'),
('Watermelon', 'fruit', 'cup'),
('Cantaloupe', 'fruit', 'cup'),
('Honeydew', 'fruit', 'cup'),
('Kiwi', 'fruit', 'whole'),
('Pomegranate', 'fruit', 'whole'),
('Cranberries', 'fruit', 'cup'),
('Raisins', 'fruit', 'cup'),
('Dates', 'fruit', 'whole')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Grains & Starches
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('White Rice', 'grain', 'cup'),
('Brown Rice', 'grain', 'cup'),
('Jasmine Rice', 'grain', 'cup'),
('Basmati Rice', 'grain', 'cup'),
('Wild Rice', 'grain', 'cup'),
('Arborio Rice', 'grain', 'cup'),
('Pasta', 'grain', 'cup'),
('Spaghetti', 'grain', 'cup'),
('Penne', 'grain', 'cup'),
('Fettuccine', 'grain', 'cup'),
('Macaroni', 'grain', 'cup'),
('Fusilli', 'grain', 'cup'),
('Rigatoni', 'grain', 'cup'),
('Lasagna Noodles', 'grain', 'sheet'),
('Ravioli', 'grain', 'cup'),
('Tortellini', 'grain', 'cup'),
('Bread', 'grain', 'slice'),
('White Bread', 'grain', 'slice'),
('Whole Wheat Bread', 'grain', 'slice'),
('Sourdough Bread', 'grain', 'slice'),
('French Bread', 'grain', 'loaf'),
('Bagels', 'grain', 'whole'),
('English Muffins', 'grain', 'whole'),
('Tortillas', 'grain', 'whole'),
('Flour Tortillas', 'grain', 'whole'),
('Corn Tortillas', 'grain', 'whole'),
('All-Purpose Flour', 'grain', 'cup'),
('Whole Wheat Flour', 'grain', 'cup'),
('Bread Flour', 'grain', 'cup'),
('Cake Flour', 'grain', 'cup'),
('Almond Flour', 'grain', 'cup'),
('Coconut Flour', 'grain', 'cup'),
('Oats', 'grain', 'cup'),
('Rolled Oats', 'grain', 'cup'),
('Steel Cut Oats', 'grain', 'cup'),
('Quinoa', 'grain', 'cup'),
('Barley', 'grain', 'cup'),
('Bulgur', 'grain', 'cup'),
('Couscous', 'grain', 'cup'),
('Polenta', 'grain', 'cup')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Legumes & Nuts
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Black Beans', 'legumes', 'cup'),
('Kidney Beans', 'legumes', 'cup'),
('Pinto Beans', 'legumes', 'cup'),
('Navy Beans', 'legumes', 'cup'),
('Chickpeas', 'legumes', 'cup'),
('Lentils', 'legumes', 'cup'),
('Red Lentils', 'legumes', 'cup'),
('Green Lentils', 'legumes', 'cup'),
('Black Lentils', 'legumes', 'cup'),
('Split Peas', 'legumes', 'cup'),
('Lima Beans', 'legumes', 'cup'),
('Black-Eyed Peas', 'legumes', 'cup'),
('Tofu', 'legumes', 'oz'),
('Tempeh', 'legumes', 'oz'),
('Edamame', 'legumes', 'cup'),
('Almonds', 'nuts', 'cup'),
('Walnuts', 'nuts', 'cup'),
('Pecans', 'nuts', 'cup'),
('Cashews', 'nuts', 'cup'),
('Pistachios', 'nuts', 'cup'),
('Hazelnuts', 'nuts', 'cup'),
('Macadamia Nuts', 'nuts', 'cup'),
('Brazil Nuts', 'nuts', 'cup'),
('Pine Nuts', 'nuts', 'cup'),
('Peanuts', 'nuts', 'cup'),
('Almond Butter', 'nuts', 'tbsp'),
('Peanut Butter', 'nuts', 'tbsp'),
('Cashew Butter', 'nuts', 'tbsp'),
('Sunflower Seeds', 'nuts', 'cup'),
('Pumpkin Seeds', 'nuts', 'cup'),
('Sesame Seeds', 'nuts', 'tbsp'),
('Chia Seeds', 'nuts', 'tbsp'),
('Flax Seeds', 'nuts', 'tbsp'),
('Hemp Seeds', 'nuts', 'tbsp')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Herbs & Spices
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Salt', 'spice', 'tsp'),
('Sea Salt', 'spice', 'tsp'),
('Kosher Salt', 'spice', 'tsp'),
('Black Pepper', 'spice', 'tsp'),
('White Pepper', 'spice', 'tsp'),
('Cayenne Pepper', 'spice', 'tsp'),
('Paprika', 'spice', 'tsp'),
('Smoked Paprika', 'spice', 'tsp'),
('Chili Powder', 'spice', 'tsp'),
('Cumin', 'spice', 'tsp'),
('Coriander', 'spice', 'tsp'),
('Turmeric', 'spice', 'tsp'),
('Cinnamon', 'spice', 'tsp'),
('Nutmeg', 'spice', 'tsp'),
('Allspice', 'spice', 'tsp'),
('Cloves', 'spice', 'tsp'),
('Cardamom', 'spice', 'tsp'),
('Star Anise', 'spice', 'whole'),
('Bay Leaves', 'spice', 'whole'),
('Thyme', 'herb', 'tsp'),
('Rosemary', 'herb', 'tsp'),
('Oregano', 'herb', 'tsp'),
('Basil', 'herb', 'tsp'),
('Parsley', 'herb', 'tsp'),
('Cilantro', 'herb', 'tsp'),
('Dill', 'herb', 'tsp'),
('Mint', 'herb', 'tsp'),
('Sage', 'herb', 'tsp'),
('Tarragon', 'herb', 'tsp'),
('Chives', 'herb', 'tsp'),
('Marjoram', 'herb', 'tsp'),
('Italian Seasoning', 'spice', 'tsp'),
('Herbs de Provence', 'spice', 'tsp'),
('Old Bay Seasoning', 'spice', 'tsp'),
('Garlic Powder', 'spice', 'tsp'),
('Onion Powder', 'spice', 'tsp'),
('Mustard Powder', 'spice', 'tsp'),
('Red Pepper Flakes', 'spice', 'tsp'),
('Vanilla Extract', 'spice', 'tsp'),
('Almond Extract', 'spice', 'tsp')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Oils & Vinegars
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Olive Oil', 'oil', 'tbsp'),
('Extra Virgin Olive Oil', 'oil', 'tbsp'),
('Vegetable Oil', 'oil', 'tbsp'),
('Canola Oil', 'oil', 'tbsp'),
('Coconut Oil', 'oil', 'tbsp'),
('Sesame Oil', 'oil', 'tbsp'),
('Avocado Oil', 'oil', 'tbsp'),
('Grape Seed Oil', 'oil', 'tbsp'),
('Sunflower Oil', 'oil', 'tbsp'),
('Peanut Oil', 'oil', 'tbsp'),
('Balsamic Vinegar', 'vinegar', 'tbsp'),
('White Vinegar', 'vinegar', 'tbsp'),
('Apple Cider Vinegar', 'vinegar', 'tbsp'),
('Red Wine Vinegar', 'vinegar', 'tbsp'),
('White Wine Vinegar', 'vinegar', 'tbsp'),
('Rice Vinegar', 'vinegar', 'tbsp'),
('Sherry Vinegar', 'vinegar', 'tbsp'),
('Lemon Juice', 'vinegar', 'tbsp'),
('Lime Juice', 'vinegar', 'tbsp')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Condiments & Sauces
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Ketchup', 'condiment', 'tbsp'),
('Mustard', 'condiment', 'tbsp'),
('Dijon Mustard', 'condiment', 'tbsp'),
('Whole Grain Mustard', 'condiment', 'tbsp'),
('Mayonnaise', 'condiment', 'tbsp'),
('Soy Sauce', 'condiment', 'tbsp'),
('Worcestershire Sauce', 'condiment', 'tbsp'),
('Hot Sauce', 'condiment', 'tsp'),
('Tabasco Sauce', 'condiment', 'tsp'),
('Sriracha', 'condiment', 'tsp'),
('Barbecue Sauce', 'condiment', 'tbsp'),
('Teriyaki Sauce', 'condiment', 'tbsp'),
('Pesto', 'condiment', 'tbsp'),
('Hoisin Sauce', 'condiment', 'tbsp'),
('Fish Sauce', 'condiment', 'tsp'),
('Oyster Sauce', 'condiment', 'tbsp'),
('Tomato Paste', 'condiment', 'tbsp'),
('Tomato Sauce', 'condiment', 'cup'),
('Crushed Tomatoes', 'condiment', 'cup'),
('Diced Tomatoes', 'condiment', 'cup'),
('Salsa', 'condiment', 'cup'),
('Guacamole', 'condiment', 'cup'),
('Hummus', 'condiment', 'cup'),
('Tahini', 'condiment', 'tbsp'),
('Miso Paste', 'condiment', 'tbsp')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Sweeteners & Baking
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Sugar', 'sweetener', 'cup'),
('Brown Sugar', 'sweetener', 'cup'),
('Powdered Sugar', 'sweetener', 'cup'),
('Honey', 'sweetener', 'tbsp'),
('Maple Syrup', 'sweetener', 'tbsp'),
('Agave Nectar', 'sweetener', 'tbsp'),
('Molasses', 'sweetener', 'tbsp'),
('Stevia', 'sweetener', 'tsp'),
('Baking Soda', 'baking', 'tsp'),
('Baking Powder', 'baking', 'tsp'),
('Yeast', 'baking', 'tsp'),
('Active Dry Yeast', 'baking', 'tsp'),
('Instant Yeast', 'baking', 'tsp'),
('Cornstarch', 'baking', 'tbsp'),
('Arrowroot', 'baking', 'tbsp'),
('Cocoa Powder', 'baking', 'tbsp'),
('Dark Chocolate', 'baking', 'oz'),
('Milk Chocolate', 'baking', 'oz'),
('White Chocolate', 'baking', 'oz'),
('Chocolate Chips', 'baking', 'cup'),
('Vanilla Beans', 'baking', 'whole')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Canned & Packaged Goods
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Chicken Broth', 'canned', 'cup'),
('Beef Broth', 'canned', 'cup'),
('Vegetable Broth', 'canned', 'cup'),
('Coconut Milk', 'canned', 'cup'),
('Coconut Cream', 'canned', 'cup'),
('Evaporated Milk', 'canned', 'cup'),
('Condensed Milk', 'canned', 'cup'),
('Canned Corn', 'canned', 'cup'),
('Canned Beans', 'canned', 'cup'),
('Canned Tuna', 'canned', 'can'),
('Canned Salmon', 'canned', 'can'),
('Anchovies', 'canned', 'oz'),
('Capers', 'canned', 'tbsp'),
('Olives', 'canned', 'cup'),
('Green Olives', 'canned', 'cup'),
('Black Olives', 'canned', 'cup'),
('Kalamata Olives', 'canned', 'cup'),
('Artichoke Hearts', 'canned', 'cup'),
('Sun-Dried Tomatoes', 'canned', 'cup'),
('Roasted Red Peppers', 'canned', 'cup'),
('Pickles', 'canned', 'whole'),
('Jalapeños', 'canned', 'whole'),
('Chipotle Peppers', 'canned', 'whole')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Frozen Foods
INSERT INTO public.ingredients (name, category, default_unit) VALUES
('Frozen Peas', 'frozen', 'cup'),
('Frozen Corn', 'frozen', 'cup'),
('Frozen Broccoli', 'frozen', 'cup'),
('Frozen Spinach', 'frozen', 'cup'),
('Frozen Berries', 'frozen', 'cup'),
('Frozen Mixed Vegetables', 'frozen', 'cup'),
('Frozen French Fries', 'frozen', 'cup'),
('Frozen Hash Browns', 'frozen', 'cup'),
('Ice Cream', 'frozen', 'cup'),
('Frozen Yogurt', 'frozen', 'cup'),
('Frozen Pizza Dough', 'frozen', 'whole'),
('Frozen Pie Crust', 'frozen', 'whole')
)
ON CONFLICT (name_norm) DO UPDATE SET
    category = EXCLUDED.category,
    default_unit = EXCLUDED.default_unit;

-- Check how many ingredients were added
SELECT 
  'Total ingredients in database' as summary,
  COUNT(*) as count
FROM public.ingredients;

-- Show ingredients by category
SELECT 
  category,
  COUNT(*) as count
FROM public.ingredients
GROUP BY category
ORDER BY count DESC;

-- Show sample ingredients from each category
SELECT 
  category,
  string_agg(name, ', ' ORDER BY name) as sample_ingredients
FROM public.ingredients
GROUP BY category
ORDER BY category;
