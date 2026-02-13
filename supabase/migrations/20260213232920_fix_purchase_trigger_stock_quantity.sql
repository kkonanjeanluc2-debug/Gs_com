/*
  # Fix purchase stock update trigger

  1. Changes
    - Fix the `update_stock_on_purchase_completion()` function to use `stock_quantity` instead of `quantity`
    - The products table uses `stock_quantity` column, not `quantity`
  
  2. Impact
    - Purchases can now be completed successfully
    - Stock will be updated correctly when purchase status changes to 'completed'
*/

-- Recreate the function with correct column name
CREATE OR REPLACE FUNCTION update_stock_on_purchase_completion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Si l'achat passe au statut 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Mettre à jour le stock de tous les produits de l'achat
    UPDATE products p
    SET 
      stock_quantity = p.stock_quantity + pi.quantity,
      updated_at = now()
    FROM purchase_items pi
    WHERE pi.purchase_id = NEW.id
    AND pi.product_id = p.id;
    
    -- Enregistrer les mouvements de stock
    INSERT INTO stock_movements (product_id, movement_type, quantity, reference, notes, created_at)
    SELECT 
      pi.product_id,
      'purchase'::text,
      pi.quantity,
      NEW.purchase_number,
      'Achat validé - Fournisseur: ' || s.name,
      now()
    FROM purchase_items pi
    INNER JOIN suppliers s ON s.id = NEW.supplier_id
    WHERE pi.purchase_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;
