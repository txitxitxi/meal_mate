-- Create home_inventory table
CREATE TABLE IF NOT EXISTS home_inventory (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
  ingredient_name TEXT NOT NULL,
  unit TEXT,
  quantity DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure one entry per user per ingredient
  UNIQUE(user_id, ingredient_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_home_inventory_user_id ON home_inventory(user_id);
CREATE INDEX IF NOT EXISTS idx_home_inventory_ingredient_id ON home_inventory(ingredient_id);

-- Enable Row Level Security
ALTER TABLE home_inventory ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own home inventory" ON home_inventory
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own home inventory" ON home_inventory
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own home inventory" ON home_inventory
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own home inventory" ON home_inventory
  FOR DELETE USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_home_inventory_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_home_inventory_updated_at
  BEFORE UPDATE ON home_inventory
  FOR EACH ROW
  EXECUTE FUNCTION update_home_inventory_updated_at();

-- Insert some common home inventory items for testing (optional)
-- You can uncomment these if you want some default items
/*
INSERT INTO home_inventory (user_id, ingredient_id, ingredient_name, unit, quantity)
SELECT 
  auth.uid(),
  i.id,
  i.name,
  CASE 
    WHEN i.name IN ('Rice', 'Pasta', 'Flour') THEN 'kg'
    WHEN i.name IN ('Garlic', 'Ginger', 'Onion') THEN 'pieces'
    WHEN i.name IN ('Salt', 'Pepper', 'Sugar') THEN 'g'
    ELSE 'pieces'
  END,
  CASE 
    WHEN i.name IN ('Rice', 'Pasta', 'Flour') THEN 2.0
    WHEN i.name IN ('Garlic', 'Ginger', 'Onion') THEN 5.0
    WHEN i.name IN ('Salt', 'Pepper', 'Sugar') THEN 500.0
    ELSE 1.0
  END
FROM ingredients i
WHERE i.name IN ('Rice', 'Garlic', 'Ginger', 'Salt', 'Pepper', 'Onion')
AND NOT EXISTS (
  SELECT 1 FROM home_inventory hi 
  WHERE hi.user_id = auth.uid() AND hi.ingredient_id = i.id
);
*/
