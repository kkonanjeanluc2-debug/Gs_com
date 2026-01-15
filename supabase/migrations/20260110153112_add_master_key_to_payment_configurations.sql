/*
  # Ajout du Champ Master Key

  1. Modifications
    - Ajout de la colonne 'master_key' à payment_configurations
    - Ce champ est spécialement pour PayDunya qui requiert une Master Key en plus des autres clés

  2. Notes
    - master_key est optionnel (NULL autorisé) pour compatibilité avec les autres providers
    - Pour PayDunya, master_key stocke la Master Key publique
*/

-- Ajouter la colonne master_key
ALTER TABLE payment_configurations
ADD COLUMN IF NOT EXISTS master_key text;

-- Commentaire pour documenter l'usage
COMMENT ON COLUMN payment_configurations.master_key IS 'Master Key publique (utilisée principalement par Dexchange)';
