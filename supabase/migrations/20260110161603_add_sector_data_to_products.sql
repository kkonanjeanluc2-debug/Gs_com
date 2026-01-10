/*
  # Ajouter les données spécifiques au secteur pour les produits

  1. Modifications de la table products
    - Ajouter `sector_data` (JSONB) pour stocker les informations spécifiques au secteur
    - Index sur sector_data pour améliorer les performances des requêtes
    
  2. Usage
    - Les champs spécifiques à chaque secteur d'activité seront stockés dans cette colonne
    - Permet une flexibilité totale sans modifier le schéma pour chaque secteur
*/

-- Ajouter la colonne sector_data à la table products
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'products' AND column_name = 'sector_data'
  ) THEN
    ALTER TABLE products ADD COLUMN sector_data jsonb DEFAULT '{}'::jsonb;
  END IF;
END $$;

-- Créer un index GIN pour améliorer les requêtes sur sector_data
CREATE INDEX IF NOT EXISTS idx_products_sector_data ON products USING GIN (sector_data);
