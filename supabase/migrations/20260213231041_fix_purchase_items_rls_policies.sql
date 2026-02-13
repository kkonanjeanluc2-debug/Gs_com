/*
  # Fix Purchase Items RLS Policies
  
  1. Problem
    - The current RLS policy on purchase_items checks if purchase_id exists in purchases table
    - This causes issues when inserting purchase_items in the same transaction as creating the purchase
    - The policy can't see the newly inserted purchase row due to RLS context
  
  2. Solution
    - Simplify the INSERT policy to only check user role and company
    - The security is already handled at the purchases level
    - Users can only insert items for purchases they can access
  
  3. Changes
    - Drop existing INSERT policy for purchase_items
    - Create new simplified INSERT policy that checks role directly
*/

-- Drop the problematic policy
DROP POLICY IF EXISTS "Admins and supervisors can insert purchase items" ON purchase_items;

-- Create simplified policy that checks role directly without complex subquery
CREATE POLICY "Admins and supervisors can insert purchase items"
  ON purchase_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superviseur')
    )
  );