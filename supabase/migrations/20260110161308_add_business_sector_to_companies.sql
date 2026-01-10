/*
  # Ajouter le secteur d'activité aux entreprises

  1. Modifications de la table companies
    - Ajouter `business_sector` pour définir le secteur d'activité
    - Contrainte CHECK pour valider les secteurs autorisés
    
  2. Secteurs d'activité disponibles
    - distribution : Distribution et commerce
    - agroalimentaire : Agroalimentaire
    - telecom_numerique : Télécom et services numériques
    - pharmacie_sante : Pharmacie et santé
    - btp : Bâtiment et travaux publics
    - transport_logistique : Transport et logistique
    - services : Services (nettoyage, sécurité, maintenance)
    
  3. Note
    - Les entreprises existantes auront NULL par défaut (pourront être mises à jour)
    - Les nouvelles entreprises devront spécifier un secteur
*/

-- Ajouter le champ business_sector à la table companies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'business_sector'
  ) THEN
    ALTER TABLE companies ADD COLUMN business_sector text;
  END IF;
END $$;

-- Ajouter la contrainte pour valider les secteurs d'activité
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'companies_business_sector_check' AND table_name = 'companies'
  ) THEN
    ALTER TABLE companies ADD CONSTRAINT companies_business_sector_check 
      CHECK (business_sector IN (
        'distribution',
        'agroalimentaire',
        'telecom_numerique',
        'pharmacie_sante',
        'btp',
        'transport_logistique',
        'services'
      ));
  END IF;
END $$;

-- Créer un index pour améliorer les performances des requêtes par secteur
CREATE INDEX IF NOT EXISTS idx_companies_business_sector ON companies(business_sector);
