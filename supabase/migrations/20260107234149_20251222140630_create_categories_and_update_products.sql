/*
  # Add Categories and Subcategories Management
  
  1. New Tables
    - `categories`
      - `id` (uuid, primary key)
      - `name` (text, unique, required) - category name
      - `description` (text, optional) - category description
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `subcategories`
      - `id` (uuid, primary key)
      - `category_id` (uuid, foreign key to categories)
      - `name` (text, required) - subcategory name
      - `description` (text, optional) - subcategory description
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
  
  2. Updates to Existing Tables
    - `products`
      - Add `image_url` (text, optional) - URL of product image
      - Add `category_id` (uuid, optional, foreign key to categories)
      - Add `subcategory_id` (uuid, optional, foreign key to subcategories)
  
  3. Security
    - Enable RLS on `categories` and `subcategories` tables
    - Add policies for authenticated users to read categories/subcategories
    - Add policies for admin/superviseur to manage categories/subcategories
    - Update products policies to handle new fields
*/

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create subcategories table
CREATE TABLE IF NOT EXISTS subcategories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(category_id, name)
);

-- Add new columns to products table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'products' AND column_name = 'image_url'
  ) THEN
    ALTER TABLE products ADD COLUMN image_url text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'products' AND column_name = 'category_id'
  ) THEN
    ALTER TABLE products ADD COLUMN category_id uuid REFERENCES categories(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'products' AND column_name = 'subcategory_id'
  ) THEN
    ALTER TABLE products ADD COLUMN subcategory_id uuid REFERENCES subcategories(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Enable RLS on categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Enable RLS on subcategories
ALTER TABLE subcategories ENABLE ROW LEVEL SECURITY;

-- Policies for categories - authenticated users can read
CREATE POLICY "Authenticated users can view categories"
  ON categories FOR SELECT
  TO authenticated
  USING (true);

-- Policies for categories - admin and superviseur can insert
CREATE POLICY "Admin and superviseur can create categories"
  ON categories FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  );

-- Policies for categories - admin and superviseur can update
CREATE POLICY "Admin and superviseur can update categories"
  ON categories FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  );

-- Policies for categories - admin and superviseur can delete
CREATE POLICY "Admin and superviseur can delete categories"
  ON categories FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  );

-- Policies for subcategories - authenticated users can read
CREATE POLICY "Authenticated users can view subcategories"
  ON subcategories FOR SELECT
  TO authenticated
  USING (true);

-- Policies for subcategories - admin and superviseur can insert
CREATE POLICY "Admin and superviseur can create subcategories"
  ON subcategories FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  );

-- Policies for subcategories - admin and superviseur can update
CREATE POLICY "Admin and superviseur can update subcategories"
  ON subcategories FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  );

-- Policies for subcategories - admin and superviseur can delete
CREATE POLICY "Admin and superviseur can delete subcategories"
  ON subcategories FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  );

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_subcategories_category_id ON subcategories(category_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_subcategory_id ON products(subcategory_id);