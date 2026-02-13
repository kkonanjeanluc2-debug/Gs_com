/*
  # Add pending sales system

  1. New Tables
    - `pending_sales`
      - `id` (uuid, primary key)
      - `company_id` (uuid, references companies)
      - `created_by` (uuid, references profiles)
      - `client_id` (uuid, references clients)
      - `sale_data` (jsonb) - Stores the complete sale form data
      - `name` (text) - Optional name for the pending sale
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
  
  2. Security
    - Enable RLS on `pending_sales` table
    - Add policies for authenticated users to manage their company's pending sales
*/

-- Create pending_sales table
CREATE TABLE IF NOT EXISTS pending_sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  created_by uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  client_id uuid REFERENCES clients(id) ON DELETE SET NULL,
  sale_data jsonb NOT NULL,
  name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_pending_sales_company_id ON pending_sales(company_id);
CREATE INDEX IF NOT EXISTS idx_pending_sales_created_by ON pending_sales(created_by);

-- Enable RLS
ALTER TABLE pending_sales ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their company's pending sales"
  ON pending_sales FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can create pending sales for their company"
  ON pending_sales FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
    AND created_by = auth.uid()
  );

CREATE POLICY "Users can update their company's pending sales"
  ON pending_sales FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their company's pending sales"
  ON pending_sales FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );
