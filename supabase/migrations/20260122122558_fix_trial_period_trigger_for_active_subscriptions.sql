/*
  # Correction du trigger de période d'essai pour les abonnements actifs

  1. Modifications
    - Mise à jour de la fonction set_company_trial_period() pour ne pas modifier
      les valeurs trial_days et trial_end_date quand le statut est 'active'
    - Permet de gérer correctement la transition de la période d'essai vers un abonnement payant
    
  2. Sécurité
    - Maintien des vérifications existantes
    - Le trigger continue de fonctionner normalement pour les nouvelles entreprises
*/

CREATE OR REPLACE FUNCTION set_company_trial_period()
RETURNS TRIGGER AS $$
BEGIN
  -- Ne pas modifier les valeurs pour les abonnements actifs, expirés ou suspendus
  IF NEW.subscription_status IN ('active', 'expired', 'suspended') THEN
    RETURN NEW;
  END IF;

  -- Définir automatiquement 30 jours d'essai pour les nouvelles entreprises
  IF NEW.trial_days IS NULL OR NEW.trial_days = 0 THEN
    NEW.trial_days := 30;
  END IF;

  -- Calculer la date de fin d'essai si elle n'est pas définie
  IF NEW.trial_end_date IS NULL AND NEW.is_approved = true THEN
    NEW.trial_end_date := NOW() + (NEW.trial_days || ' days')::INTERVAL;
  END IF;

  -- S'assurer que le statut est trial pour les nouvelles entreprises
  IF NEW.subscription_status IS NULL THEN
    NEW.subscription_status := 'trial';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;