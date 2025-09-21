-- Simple ingredient addition script that works without constraints
-- This script will add ingredients only if they don't already exist

-- Function to safely add ingredients
CREATE OR REPLACE FUNCTION add_ingredient_if_not_exists(
    ingredient_name text,
    ingredient_category text,
    ingredient_unit text
) RETURNS void AS $$
BEGIN
    INSERT INTO public.ingredients (name, category, default_unit, created_by)
    SELECT ingredient_name, ingredient_category, ingredient_unit, '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid
    WHERE NOT EXISTS (
        SELECT 1 FROM public.ingredients 
        WHERE lower(trim(name)) = lower(trim(ingredient_name))
    );
END;
$$ LANGUAGE plpgsql;

-- Meat & Poultry
SELECT add_ingredient_if_not_exists('Chicken Breast', 'poultry', 'lb');
SELECT add_ingredient_if_not_exists('Chicken Thighs', 'poultry', 'lb');
SELECT add_ingredient_if_not_exists('Ground Chicken', 'poultry', 'lb');
SELECT add_ingredient_if_not_exists('Whole Chicken', 'poultry', 'whole');
SELECT add_ingredient_if_not_exists('Turkey Breast', 'poultry', 'lb');
SELECT add_ingredient_if_not_exists('Ground Turkey', 'poultry', 'lb');
SELECT add_ingredient_if_not_exists('Duck Breast', 'poultry', 'lb');
SELECT add_ingredient_if_not_exists('Beef Steak', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Ground Beef', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Beef Roast', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Beef Ribs', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Beef Brisket', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Pork Chops', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Ground Pork', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Pork Tenderloin', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Pork Shoulder', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Bacon', 'meat', 'slice');
SELECT add_ingredient_if_not_exists('Ham', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Sausage', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Lamb Chops', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Ground Lamb', 'meat', 'lb');
SELECT add_ingredient_if_not_exists('Lamb Shoulder', 'meat', 'lb');

-- Seafood
SELECT add_ingredient_if_not_exists('Salmon Fillet', 'fish', 'lb');
SELECT add_ingredient_if_not_exists('Cod Fillet', 'fish', 'lb');
SELECT add_ingredient_if_not_exists('Tuna Steak', 'fish', 'lb');
SELECT add_ingredient_if_not_exists('Halibut', 'fish', 'lb');
SELECT add_ingredient_if_not_exists('Trout', 'fish', 'lb');
SELECT add_ingredient_if_not_exists('Shrimp', 'seafood', 'lb');
SELECT add_ingredient_if_not_exists('Crab', 'seafood', 'lb');
SELECT add_ingredient_if_not_exists('Lobster', 'seafood', 'whole');
SELECT add_ingredient_if_not_exists('Scallops', 'seafood', 'lb');
SELECT add_ingredient_if_not_exists('Mussels', 'seafood', 'lb');
SELECT add_ingredient_if_not_exists('Clams', 'seafood', 'lb');
SELECT add_ingredient_if_not_exists('Oysters', 'seafood', 'dozen');
SELECT add_ingredient_if_not_exists('Calamari', 'seafood', 'lb');
SELECT add_ingredient_if_not_exists('Tilapia', 'fish', 'lb');
SELECT add_ingredient_if_not_exists('Mahi Mahi', 'fish', 'lb');

-- Dairy Products
SELECT add_ingredient_if_not_exists('Whole Milk', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('2% Milk', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Skim Milk', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Heavy Cream', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Half and Half', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Butter', 'dairy', 'tbsp');
SELECT add_ingredient_if_not_exists('Unsalted Butter', 'dairy', 'tbsp');
SELECT add_ingredient_if_not_exists('Margarine', 'dairy', 'tbsp');
SELECT add_ingredient_if_not_exists('Cheddar Cheese', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Mozzarella Cheese', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Parmesan Cheese', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Feta Cheese', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Ricotta Cheese', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Cream Cheese', 'dairy', 'oz');
SELECT add_ingredient_if_not_exists('Sour Cream', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Greek Yogurt', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Plain Yogurt', 'dairy', 'cup');
SELECT add_ingredient_if_not_exists('Buttermilk', 'dairy', 'cup');

-- Vegetables
SELECT add_ingredient_if_not_exists('Onions', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Yellow Onions', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Red Onions', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Sweet Onions', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Green Onions', 'vegetable', 'bunch');
SELECT add_ingredient_if_not_exists('Garlic', 'vegetable', 'clove');
SELECT add_ingredient_if_not_exists('Ginger', 'vegetable', 'inch');
SELECT add_ingredient_if_not_exists('Carrots', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Celery', 'vegetable', 'stalk');
SELECT add_ingredient_if_not_exists('Bell Peppers', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Red Bell Peppers', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Green Bell Peppers', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Yellow Bell Peppers', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Jalapeños', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Tomatoes', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Cherry Tomatoes', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Roma Tomatoes', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Cucumbers', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Lettuce', 'vegetable', 'head');
SELECT add_ingredient_if_not_exists('Romaine Lettuce', 'vegetable', 'head');
SELECT add_ingredient_if_not_exists('Iceberg Lettuce', 'vegetable', 'head');
SELECT add_ingredient_if_not_exists('Spinach', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Kale', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Arugula', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Broccoli', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Cauliflower', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Brussels Sprouts', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Cabbage', 'vegetable', 'head');
SELECT add_ingredient_if_not_exists('Red Cabbage', 'vegetable', 'head');
SELECT add_ingredient_if_not_exists('Potatoes', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Russet Potatoes', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Red Potatoes', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Sweet Potatoes', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Yukon Gold Potatoes', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Mushrooms', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('White Mushrooms', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Portobello Mushrooms', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Shiitake Mushrooms', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Eggplant', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Zucchini', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Squash', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Butternut Squash', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Asparagus', 'vegetable', 'bunch');
SELECT add_ingredient_if_not_exists('Green Beans', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Snow Peas', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Corn', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Avocado', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Radishes', 'vegetable', 'cup');
SELECT add_ingredient_if_not_exists('Beets', 'vegetable', 'whole');
SELECT add_ingredient_if_not_exists('Turnips', 'vegetable', 'whole');

-- Fruits
SELECT add_ingredient_if_not_exists('Apples', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Red Apples', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Green Apples', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Bananas', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Oranges', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Lemons', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Limes', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Grapefruit', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Grapes', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Strawberries', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Blueberries', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Raspberries', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Blackberries', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Cherries', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Peaches', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Pears', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Plums', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Apricots', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Mangoes', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Pineapple', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Watermelon', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Cantaloupe', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Honeydew', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Kiwi', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Pomegranate', 'fruit', 'whole');
SELECT add_ingredient_if_not_exists('Cranberries', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Raisins', 'fruit', 'cup');
SELECT add_ingredient_if_not_exists('Dates', 'fruit', 'whole');

-- Grains & Starches
SELECT add_ingredient_if_not_exists('White Rice', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Brown Rice', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Jasmine Rice', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Basmati Rice', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Wild Rice', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Arborio Rice', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Pasta', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Spaghetti', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Penne', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Fettuccine', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Macaroni', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Fusilli', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Rigatoni', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Lasagna Noodles', 'grain', 'sheet');
SELECT add_ingredient_if_not_exists('Ravioli', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Tortellini', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Bread', 'grain', 'slice');
SELECT add_ingredient_if_not_exists('White Bread', 'grain', 'slice');
SELECT add_ingredient_if_not_exists('Whole Wheat Bread', 'grain', 'slice');
SELECT add_ingredient_if_not_exists('Sourdough Bread', 'grain', 'slice');
SELECT add_ingredient_if_not_exists('French Bread', 'grain', 'loaf');
SELECT add_ingredient_if_not_exists('Bagels', 'grain', 'whole');
SELECT add_ingredient_if_not_exists('English Muffins', 'grain', 'whole');
SELECT add_ingredient_if_not_exists('Tortillas', 'grain', 'whole');
SELECT add_ingredient_if_not_exists('Flour Tortillas', 'grain', 'whole');
SELECT add_ingredient_if_not_exists('Corn Tortillas', 'grain', 'whole');
SELECT add_ingredient_if_not_exists('All-Purpose Flour', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Whole Wheat Flour', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Bread Flour', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Cake Flour', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Almond Flour', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Coconut Flour', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Oats', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Rolled Oats', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Steel Cut Oats', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Quinoa', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Barley', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Bulgur', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Couscous', 'grain', 'cup');
SELECT add_ingredient_if_not_exists('Polenta', 'grain', 'cup');

-- Legumes & Nuts
SELECT add_ingredient_if_not_exists('Black Beans', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Kidney Beans', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Pinto Beans', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Navy Beans', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Chickpeas', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Lentils', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Red Lentils', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Green Lentils', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Black Lentils', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Split Peas', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Lima Beans', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Black-Eyed Peas', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Tofu', 'legumes', 'oz');
SELECT add_ingredient_if_not_exists('Tempeh', 'legumes', 'oz');
SELECT add_ingredient_if_not_exists('Edamame', 'legumes', 'cup');
SELECT add_ingredient_if_not_exists('Almonds', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Walnuts', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Pecans', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Cashews', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Pistachios', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Hazelnuts', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Macadamia Nuts', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Brazil Nuts', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Pine Nuts', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Peanuts', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Almond Butter', 'nuts', 'tbsp');
SELECT add_ingredient_if_not_exists('Peanut Butter', 'nuts', 'tbsp');
SELECT add_ingredient_if_not_exists('Cashew Butter', 'nuts', 'tbsp');
SELECT add_ingredient_if_not_exists('Sunflower Seeds', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Pumpkin Seeds', 'nuts', 'cup');
SELECT add_ingredient_if_not_exists('Sesame Seeds', 'nuts', 'tbsp');
SELECT add_ingredient_if_not_exists('Chia Seeds', 'nuts', 'tbsp');
SELECT add_ingredient_if_not_exists('Flax Seeds', 'nuts', 'tbsp');
SELECT add_ingredient_if_not_exists('Hemp Seeds', 'nuts', 'tbsp');

-- Herbs & Spices
SELECT add_ingredient_if_not_exists('Salt', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Sea Salt', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Kosher Salt', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Black Pepper', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('White Pepper', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Cayenne Pepper', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Paprika', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Smoked Paprika', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Chili Powder', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Cumin', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Coriander', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Turmeric', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Cinnamon', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Nutmeg', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Allspice', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Cloves', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Cardamom', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Star Anise', 'spice', 'whole');
SELECT add_ingredient_if_not_exists('Bay Leaves', 'spice', 'whole');
SELECT add_ingredient_if_not_exists('Thyme', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Rosemary', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Oregano', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Basil', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Parsley', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Cilantro', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Dill', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Mint', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Sage', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Tarragon', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Chives', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Marjoram', 'herb', 'tsp');
SELECT add_ingredient_if_not_exists('Italian Seasoning', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Herbs de Provence', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Old Bay Seasoning', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Garlic Powder', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Onion Powder', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Mustard Powder', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Red Pepper Flakes', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Vanilla Extract', 'spice', 'tsp');
SELECT add_ingredient_if_not_exists('Almond Extract', 'spice', 'tsp');

-- Oils & Vinegars
SELECT add_ingredient_if_not_exists('Olive Oil', 'oil', 'tbsp');
SELECT add_ingredient_if_not_exists('Extra Virgin Olive Oil', 'oil', 'tbsp');
SELECT add_ingredient_if_not_exists('Vegetable Oil', 'oil', 'tbsp');
SELECT add_ingredient_if_not_exists('Canola Oil', 'oil', 'tbsp');
SELECT add_ingredient_if_not_exists('Coconut Oil', 'oil', 'tbsp');
SELECT add_ingredient_if_not_exists('Sesame Oil', 'oil', 'tbsp');
SELECT add_ingredient_if_not_exists('Avocado Oil', 'oil', 'tbsp');
SELECT add_ingredient_if_not_exists('Grape Seed Oil', 'oil', 'tbsp');
SELECT add_ingredient_if_not_exists('Sunflower Oil', 'oil', 'tbsp');
SELECT add_ingredient_if_not_exists('Peanut Oil', 'oil', 'tbsp');
SELECT add_ingredient_if_not_exists('Balsamic Vinegar', 'vinegar', 'tbsp');
SELECT add_ingredient_if_not_exists('White Vinegar', 'vinegar', 'tbsp');
SELECT add_ingredient_if_not_exists('Apple Cider Vinegar', 'vinegar', 'tbsp');
SELECT add_ingredient_if_not_exists('Red Wine Vinegar', 'vinegar', 'tbsp');
SELECT add_ingredient_if_not_exists('White Wine Vinegar', 'vinegar', 'tbsp');
SELECT add_ingredient_if_not_exists('Rice Vinegar', 'vinegar', 'tbsp');
SELECT add_ingredient_if_not_exists('Sherry Vinegar', 'vinegar', 'tbsp');
SELECT add_ingredient_if_not_exists('Lemon Juice', 'vinegar', 'tbsp');
SELECT add_ingredient_if_not_exists('Lime Juice', 'vinegar', 'tbsp');

-- Condiments & Sauces
SELECT add_ingredient_if_not_exists('Ketchup', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Mustard', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Dijon Mustard', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Whole Grain Mustard', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Mayonnaise', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Soy Sauce', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Worcestershire Sauce', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Hot Sauce', 'condiment', 'tsp');
SELECT add_ingredient_if_not_exists('Tabasco Sauce', 'condiment', 'tsp');
SELECT add_ingredient_if_not_exists('Sriracha', 'condiment', 'tsp');
SELECT add_ingredient_if_not_exists('Barbecue Sauce', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Teriyaki Sauce', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Pesto', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Hoisin Sauce', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Fish Sauce', 'condiment', 'tsp');
SELECT add_ingredient_if_not_exists('Oyster Sauce', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Tomato Paste', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Tomato Sauce', 'condiment', 'cup');
SELECT add_ingredient_if_not_exists('Crushed Tomatoes', 'condiment', 'cup');
SELECT add_ingredient_if_not_exists('Diced Tomatoes', 'condiment', 'cup');
SELECT add_ingredient_if_not_exists('Salsa', 'condiment', 'cup');
SELECT add_ingredient_if_not_exists('Guacamole', 'condiment', 'cup');
SELECT add_ingredient_if_not_exists('Hummus', 'condiment', 'cup');
SELECT add_ingredient_if_not_exists('Tahini', 'condiment', 'tbsp');
SELECT add_ingredient_if_not_exists('Miso Paste', 'condiment', 'tbsp');

-- Sweeteners & Baking
SELECT add_ingredient_if_not_exists('Sugar', 'sweetener', 'cup');
SELECT add_ingredient_if_not_exists('Brown Sugar', 'sweetener', 'cup');
SELECT add_ingredient_if_not_exists('Powdered Sugar', 'sweetener', 'cup');
SELECT add_ingredient_if_not_exists('Honey', 'sweetener', 'tbsp');
SELECT add_ingredient_if_not_exists('Maple Syrup', 'sweetener', 'tbsp');
SELECT add_ingredient_if_not_exists('Agave Nectar', 'sweetener', 'tbsp');
SELECT add_ingredient_if_not_exists('Molasses', 'sweetener', 'tbsp');
SELECT add_ingredient_if_not_exists('Stevia', 'sweetener', 'tsp');
SELECT add_ingredient_if_not_exists('Baking Soda', 'baking', 'tsp');
SELECT add_ingredient_if_not_exists('Baking Powder', 'baking', 'tsp');
SELECT add_ingredient_if_not_exists('Yeast', 'baking', 'tsp');
SELECT add_ingredient_if_not_exists('Active Dry Yeast', 'baking', 'tsp');
SELECT add_ingredient_if_not_exists('Instant Yeast', 'baking', 'tsp');
SELECT add_ingredient_if_not_exists('Cornstarch', 'baking', 'tbsp');
SELECT add_ingredient_if_not_exists('Arrowroot', 'baking', 'tbsp');
SELECT add_ingredient_if_not_exists('Cocoa Powder', 'baking', 'tbsp');
SELECT add_ingredient_if_not_exists('Dark Chocolate', 'baking', 'oz');
SELECT add_ingredient_if_not_exists('Milk Chocolate', 'baking', 'oz');
SELECT add_ingredient_if_not_exists('White Chocolate', 'baking', 'oz');
SELECT add_ingredient_if_not_exists('Chocolate Chips', 'baking', 'cup');
SELECT add_ingredient_if_not_exists('Vanilla Beans', 'baking', 'whole');

-- Canned & Packaged Goods
SELECT add_ingredient_if_not_exists('Chicken Broth', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Beef Broth', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Vegetable Broth', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Coconut Milk', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Coconut Cream', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Evaporated Milk', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Condensed Milk', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Canned Corn', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Canned Beans', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Canned Tuna', 'canned', 'can');
SELECT add_ingredient_if_not_exists('Canned Salmon', 'canned', 'can');
SELECT add_ingredient_if_not_exists('Anchovies', 'canned', 'oz');
SELECT add_ingredient_if_not_exists('Capers', 'canned', 'tbsp');
SELECT add_ingredient_if_not_exists('Olives', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Green Olives', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Black Olives', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Kalamata Olives', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Artichoke Hearts', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Sun-Dried Tomatoes', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Roasted Red Peppers', 'canned', 'cup');
SELECT add_ingredient_if_not_exists('Pickles', 'canned', 'whole');
SELECT add_ingredient_if_not_exists('Jalapeños', 'canned', 'whole');
SELECT add_ingredient_if_not_exists('Chipotle Peppers', 'canned', 'whole');

-- Frozen Foods
SELECT add_ingredient_if_not_exists('Frozen Peas', 'frozen', 'cup');
SELECT add_ingredient_if_not_exists('Frozen Corn', 'frozen', 'cup');
SELECT add_ingredient_if_not_exists('Frozen Broccoli', 'frozen', 'cup');
SELECT add_ingredient_if_not_exists('Frozen Spinach', 'frozen', 'cup');
SELECT add_ingredient_if_not_exists('Frozen Berries', 'frozen', 'cup');
SELECT add_ingredient_if_not_exists('Frozen Mixed Vegetables', 'frozen', 'cup');
SELECT add_ingredient_if_not_exists('Frozen French Fries', 'frozen', 'cup');
SELECT add_ingredient_if_not_exists('Frozen Hash Browns', 'frozen', 'cup');
SELECT add_ingredient_if_not_exists('Ice Cream', 'frozen', 'cup');
SELECT add_ingredient_if_not_exists('Frozen Yogurt', 'frozen', 'cup');
SELECT add_ingredient_if_not_exists('Frozen Pizza Dough', 'frozen', 'whole');
SELECT add_ingredient_if_not_exists('Frozen Pie Crust', 'frozen', 'whole');

-- Update existing ingredients that have empty created_by
UPDATE public.ingredients 
SET created_by = '90e7c0dc-fe3c-4882-aa40-0e31261775cf'::uuid
WHERE created_by IS NULL;

-- Clean up the function
DROP FUNCTION add_ingredient_if_not_exists(text, text, text);

-- Check results
SELECT 
  'Total ingredients in database' as summary,
  COUNT(*) as count
FROM public.ingredients;

SELECT 
  category,
  COUNT(*) as count
FROM public.ingredients
GROUP BY category
ORDER BY count DESC;

-- Show ingredients with created_by info
SELECT 
  'Ingredients with created_by set' as info,
  COUNT(*) as count
FROM public.ingredients
WHERE created_by IS NOT NULL;
