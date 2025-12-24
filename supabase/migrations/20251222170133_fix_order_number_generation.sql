/*
  # Fix Order Number Generation

  1. Changes
    - Create a sequence for order numbers to ensure uniqueness
    - Update the generate_order_number function to use the sequence
    - This prevents duplicate order numbers when multiple orders are created simultaneously

  2. Technical Details
    - Uses PostgreSQL sequences which are atomic and thread-safe
    - The sequence starts from the highest existing order number
    - Each call to nextval() is guaranteed to return a unique value
*/

-- Drop existing trigger and functions
DROP TRIGGER IF EXISTS trigger_set_order_number ON orders;
DROP FUNCTION IF EXISTS set_order_number();
DROP FUNCTION IF EXISTS generate_order_number();

-- Create a sequence for order numbers
DO $$
DECLARE
  max_order_num integer;
BEGIN
  -- Get the highest existing order number
  SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 4) AS integer)), 0)
  INTO max_order_num
  FROM orders
  WHERE order_number ~ '^CMD[0-9]+$';
  
  -- Create sequence starting from the next number
  EXECUTE format('CREATE SEQUENCE IF NOT EXISTS order_number_seq START WITH %s', max_order_num + 1);
END $$;

-- Create improved function to generate order numbers using sequence
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS text AS $$
DECLARE
  new_number text;
BEGIN
  new_number := 'CMD' || LPAD(nextval('order_number_seq')::text, 6, '0');
  RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate order number
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    NEW.order_number := generate_order_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_order_number
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION set_order_number();