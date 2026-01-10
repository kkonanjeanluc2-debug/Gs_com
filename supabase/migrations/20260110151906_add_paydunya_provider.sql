/*
  # Ajout du Provider PayDunya

  1. Modifications
    - Ajout de 'paydunya' à la liste des providers autorisés dans payment_configurations
    - Mise à jour de la contrainte CHECK pour accepter PayDunya

  2. Sécurité
    - Aucune modification des politiques RLS existantes
    - Les mêmes règles d'accès s'appliquent à PayDunya
*/

-- Supprimer l'ancienne contrainte
ALTER TABLE payment_configurations
DROP CONSTRAINT IF EXISTS payment_configurations_provider_check;

-- Ajouter la nouvelle contrainte avec PayDunya inclus
ALTER TABLE payment_configurations
ADD CONSTRAINT payment_configurations_provider_check
CHECK (provider IN ('wave', 'orange_money', 'mtn_money', 'moov_money', 'cinetpay', 'paydunya'));
