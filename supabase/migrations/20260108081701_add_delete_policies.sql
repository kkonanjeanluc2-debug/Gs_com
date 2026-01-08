/*
  # Add DELETE policies for products and improve client deletion

  1. Products
    - Add DELETE policy for admins to delete products from their company

  2. Clients
    - Ensure DELETE policy works correctly for admins

  3. Security
    - Only admins can delete products and clients
    - Users can only delete resources from their own company
*/

-- Add DELETE policy for products
CREATE POLICY "Admins can delete company products"
  ON products FOR DELETE
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND get_user_role(auth.uid()) = 'admin'
  );
