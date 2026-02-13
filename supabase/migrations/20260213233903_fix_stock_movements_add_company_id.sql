/*
  # Fix stock movements trigger to include company_id

  1. Changes
    - Update `update_stock_on_purchase_completion()` to include company_id in stock_movements insert
    - company_id is required (NOT NULL) and must come from the purchase record
  
  2. Impact
    - Stock movements will now properly include company_id
    - Purchases can be validated without constraint violations
*/

-- Recreate the function with company_id
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
    INSERT INTO stock_movements (product_id, company_id, user_id, type, quantity, reason, created_at)
    SELECT 
      pi.product_id,
      NEW.company_id,
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
