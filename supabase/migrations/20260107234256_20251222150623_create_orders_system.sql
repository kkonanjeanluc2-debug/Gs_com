/*
  # Create Orders System

  1. New Tables
    - `orders`
      - `id` (uuid, primary key)
      - `order_number` (text, unique) - Auto-generated order number
      - `client_id` (uuid) - Reference to clients table
      - `commercial_id` (uuid) - Reference to profiles table (the salesperson)
      - `total_amount` (decimal) - Total order amount
      - `status` (text) - Order status: pending, confirmed, delivered, cancelled
      - `notes` (text, optional) - Order notes
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `order_items`
      - `id` (uuid, primary key)
      - `order_id` (uuid) - Reference to orders table
      - `product_id` (uuid) - Reference to products table
      - `quantity` (integer) - Quantity ordered
      - `unit_price` (decimal) - Price at time of order
      - `subtotal` (decimal) - quantity * unit_price
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on both tables
    - Commercials can create and view their own orders
    - Admins can view all orders
    - Clients cannot directly access orders
*/

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number text UNIQUE NOT NULL,
  client_id uuid REFERENCES clients(id) ON DELETE RESTRICT NOT NULL,
  commercial_id uuid REFERENCES profiles(id) ON DELETE RESTRICT NOT NULL,
  total_amount decimal(10, 2) DEFAULT 0 NOT NULL,
  status text DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'confirmed', 'delivered', 'cancelled')),
  notes text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  product_id uuid REFERENCES products(id) ON DELETE RESTRICT NOT NULL,
  quantity integer DEFAULT 1 NOT NULL CHECK (quantity > 0),
  unit_price decimal(10, 2) NOT NULL,
  subtotal decimal(10, 2) NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Create function to generate order numbers
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS text AS $$
DECLARE
  new_number text;
  max_num integer;
BEGIN
  SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 4) AS integer)), 0) + 1
  INTO max_num
  FROM orders
  WHERE order_number LIKE 'CMD%';
  
  new_number := 'CMD' || LPAD(max_num::text, 6, '0');
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

-- Create trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Orders policies
CREATE POLICY "Admins can view all orders"
  ON orders FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Commercials can view their own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (commercial_id = auth.uid());

CREATE POLICY "Commercials can create orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (
    commercial_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('commercial', 'admin')
    )
  );

CREATE POLICY "Commercials can update their own orders"
  ON orders FOR UPDATE
  TO authenticated
  USING (commercial_id = auth.uid())
  WITH CHECK (commercial_id = auth.uid());

CREATE POLICY "Admins can update any order"
  ON orders FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Order items policies
CREATE POLICY "Users can view order items of their orders"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND (orders.commercial_id = auth.uid() OR EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
      ))
    )
  );

CREATE POLICY "Users can insert order items for their orders"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.commercial_id = auth.uid()
    )
  );

CREATE POLICY "Users can update order items for their orders"
  ON order_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.commercial_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.commercial_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete order items for their orders"
  ON order_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.commercial_id = auth.uid()
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_client_id ON orders(client_id);
CREATE INDEX IF NOT EXISTS idx_orders_commercial_id ON orders(commercial_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);