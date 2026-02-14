/*
  # Ajout du prix de vente dans les achats

  1. Modifications
    - Ajouter la colonne `selling_price` à la table `purchase_items`
    - Cette colonne permet de définir le prix de vente lors de l'achat
    - Calculer automatiquement la marge (selling_price - unit_price)

  2. Notes
    - Le prix de vente peut être mis à jour lors de l'achat
    - Permet de voir la rentabilité prévue pour chaque produit acheté
*/

-- Ajouter la colonne selling_price à purchase_items
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'purchase_items' AND column_name = 'selling_price'
  ) THEN
    ALTER TABLE purchase_items
    ADD COLUMN selling_price numeric(12, 2) DEFAULT 0 CHECK (selling_price >= 0);
  END IF;
END $$;

-- Mettre à jour les valeurs existantes avec le prix du produit
UPDATE purchase_items pi
SET selling_price = COALESCE(
  (SELECT price FROM products WHERE id = pi.product_id),
  0
)
WHERE selling_price = 0 OR selling_price IS NULL;
