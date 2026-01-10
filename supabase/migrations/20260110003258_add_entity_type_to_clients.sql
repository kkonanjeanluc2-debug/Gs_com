/*
  # Ajouter le type d'entité (particulier/entreprise) aux clients

  1. Modifications
    - Ajouter la colonne `entity_type` pour distinguer "particulier" et "entreprise"
    - Ajouter la colonne `company_name` pour le nom de l'entreprise (si applicable)
    - Ajouter la colonne `sector` pour le secteur d'activité de l'entreprise
    - Ajouter la colonne `contact_person` pour le nom du contact dans l'entreprise
    
  2. Notes
    - Les clients existants auront `entity_type` défini à "particulier" par défaut
    - `company_name` sera utilisé uniquement pour les entreprises
    - Pour les particuliers, `name` reste le champ principal
    - Pour les entreprises, `company_name` devient le nom principal et `contact_person` le nom du contact
*/

-- Ajouter le champ entity_type avec une valeur par défaut
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'clients' AND column_name = 'entity_type'
  ) THEN
    ALTER TABLE clients ADD COLUMN entity_type text NOT NULL DEFAULT 'particulier';
    
    -- Ajouter une contrainte pour valider les valeurs
    ALTER TABLE clients ADD CONSTRAINT clients_entity_type_check 
      CHECK (entity_type IN ('particulier', 'entreprise'));
  END IF;
END $$;

-- Ajouter le champ company_name pour les entreprises
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'clients' AND column_name = 'company_name'
  ) THEN
    ALTER TABLE clients ADD COLUMN company_name text;
  END IF;
END $$;

-- Ajouter le champ sector (secteur d'activité) pour les entreprises
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'clients' AND column_name = 'sector'
  ) THEN
    ALTER TABLE clients ADD COLUMN sector text;
  END IF;
END $$;

-- Ajouter le champ contact_person pour les entreprises
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'clients' AND column_name = 'contact_person'
  ) THEN
    ALTER TABLE clients ADD COLUMN contact_person text;
  END IF;
END $$;

-- Créer un index pour améliorer les performances de filtrage par entity_type
CREATE INDEX IF NOT EXISTS idx_clients_entity_type ON clients(entity_type);