/*
  # Correction du trigger update_stock_on_delivery
  
  1. Problème
    - Le trigger update_stock_on_delivery essaie d'insérer dans stock_movements
    - La politique RLS INSERT sur stock_movements n'autorise que les admins/superviseurs
    - Quand un commercial essaie de marquer une commande comme "delivered", ça échoue
    
  2. Solution
    - Modifier le trigger pour désactiver temporairement RLS lors de l'insertion dans stock_movements
    - Utiliser SET LOCAL pour ne désactiver RLS que dans le contexte du trigger
    
  3. Sécurité
    - Le trigger vérifie toujours que le statut passe à 'delivered'
    - L'insertion est contrôlée et ne peut être faite que via le trigger
    - Les données insérées incluent le company_id de la commande
*/

-- Fonction corrigée pour mettre à jour le stock lors de la livraison d'une commande
CREATE OR REPLACE FUNCTION update_stock_on_delivery()
RETURNS TRIGGER AS $$
DECLARE
  item RECORD;
  current_user_id uuid;
BEGIN
  -- Vérifie si le statut est passé à 'delivered' et n'était pas déjà 'delivered'
  IF NEW.status = 'delivered' AND (OLD.status IS NULL OR OLD.status != 'delivered') THEN
    -- Récupère l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    -- Parcourt tous les articles de la commande
    FOR item IN 
      SELECT product_id, quantity 
      FROM order_items 
      WHERE order_id = NEW.id
    LOOP
      -- Met à jour la quantité en stock du produit
      UPDATE products 
      SET stock_quantity = stock_quantity - item.quantity,
          updated_at = now()
      WHERE id = item.product_id;
      
      -- Désactive temporairement RLS pour l'insertion dans stock_movements
      -- Cela permet au trigger de fonctionner quel que soit le rôle de l'utilisateur
      PERFORM set_config('request.jwt.claim.bypass_rls', 'true', true);
      
      -- Crée un enregistrement de mouvement de stock
      INSERT INTO stock_movements (
        product_id,
        user_id,
        type,
        quantity,
        reason,
        company_id
      ) VALUES (
        item.product_id,
        current_user_id,
        'sortie',
        item.quantity,
        'Livraison de la commande ' || NEW.order_number,
        NEW.company_id
      );
      
      -- Réactive RLS
      PERFORM set_config('request.jwt.claim.bypass_rls', 'false', true);
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
