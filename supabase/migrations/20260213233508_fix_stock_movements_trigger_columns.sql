/*
  # Fix stock movements trigger columns

  1. Changes
    - Update `update_stock_on_purchase_completion()` to use correct stock_movements table structure
    - Use `type` instead of `movement_type`
    - Use `reason` instead of `notes`
    - Remove `reference` column which doesn't exist
    - Add required `user_id` column
  
  2. Impact
    - Stock movements will be correctly recorded when purchases are completed
    - Purchases can now be validated successfully
*/

-- Recreate the function with correct column names
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
    INSERT INTO stock_movements (product_id, user_id, type, quantity, reason, created_at)
    SELECT 
      pi.product_id,
      NEW.created_by,
      'entree'::text,
      pi.quantity,
      'Achat ' || NEW.purchase_number || ' validé - Fournisseur: ' || s.name,
      now()
    FROM purchase_items pi
    INNER JOIN suppliers s ON s.id = NEW.supplier_id
    WHERE pi.purchase_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;
