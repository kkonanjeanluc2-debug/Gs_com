/*
  # Mise à jour automatique du stock après livraison

  1. Nouvelles Fonctions
    - `update_stock_on_delivery()` - Fonction trigger qui se déclenche quand une commande est livrée
    - Parcourt tous les articles de la commande
    - Déduit les quantités du stock des produits
    - Crée des enregistrements de mouvements de stock
  
  2. Fonctionnement
    - Se déclenche uniquement quand le statut passe à 'delivered'
    - Vérifie que le statut précédent n'était pas déjà 'delivered' (évite les doubles déductions)
    - Crée un mouvement de stock de type 'sortie' pour chaque article
    - Met à jour la quantité en stock de chaque produit
  
  3. Sécurité
    - La fonction s'exécute avec les privilèges du définer (SECURITY DEFINER)
    - Les mouvements de stock sont automatiquement liés à l'utilisateur qui a modifié la commande
*/

-- Fonction pour mettre à jour le stock lors de la livraison d'une commande
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
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crée le trigger sur la table orders
DROP TRIGGER IF EXISTS trigger_update_stock_on_delivery ON orders;
CREATE TRIGGER trigger_update_stock_on_delivery
  AFTER UPDATE OF status ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_stock_on_delivery();