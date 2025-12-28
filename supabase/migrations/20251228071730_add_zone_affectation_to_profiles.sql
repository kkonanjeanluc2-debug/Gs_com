/*
  # Ajout de la Zone d'Affectation pour les Commerciaux

  1. Modifications
    - Ajout de la colonne `zone_affectation` dans la table `profiles`
    - Cette colonne permet d'affecter une commune de Côte d'Ivoire à un commercial

  2. Détails
    - Type: TEXT (pour stocker le nom de la commune)
    - Nullable: Oui (seulement requis pour les commerciaux)
*/

-- Ajouter la colonne zone_affectation à la table profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS zone_affectation TEXT;

-- Créer un index pour accélérer les recherches par zone
CREATE INDEX IF NOT EXISTS idx_profiles_zone_affectation 
  ON profiles(zone_affectation) 
  WHERE zone_affectation IS NOT NULL;
