/*
  # Système de vérification des fonctionnalités par abonnement

  1. Nouvelles fonctions
    - `check_company_feature(company_id, feature_code)` : Vérifie si une entreprise a accès à une fonctionnalité
    - `get_company_features(company_id)` : Récupère toutes les fonctionnalités disponibles pour une entreprise
    
  2. Logique
    - Vérifie le plan actuel de l'entreprise
    - Retourne les fonctionnalités incluses dans ce plan
    - Gère les périodes d'essai (accès complet pendant l'essai)
    
  3. Sécurité
    - Les fonctions sont accessibles aux utilisateurs authentifiés
    - Vérification du statut d'abonnement
*/

-- Fonction pour vérifier si une entreprise a accès à une fonctionnalité
CREATE OR REPLACE FUNCTION check_company_feature(
  p_company_id UUID,
  p_feature_code TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_has_access BOOLEAN := false;
  v_subscription_status TEXT;
BEGIN
  -- Récupérer le statut d'abonnement
  SELECT subscription_status INTO v_subscription_status
  FROM companies
  WHERE id = p_company_id;

  -- Pendant la période d'essai, accès à toutes les fonctionnalités
  IF v_subscription_status = 'trial' THEN
    RETURN true;
  END IF;

  -- Pour les abonnements actifs, vérifier le plan
  IF v_subscription_status = 'active' THEN
    SELECT EXISTS(
      SELECT 1
      FROM companies c
      JOIN subscription_plans sp ON c.current_plan_id = sp.id
      CROSS JOIN LATERAL jsonb_array_elements(sp.features) AS feature
      WHERE c.id = p_company_id
        AND feature->>'code' = p_feature_code
        AND (feature->>'is_included')::boolean = true
    ) INTO v_has_access;
    
    RETURN v_has_access;
  END IF;

  -- Pour tous les autres statuts (expired, suspended, cancelled), pas d'accès
  RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour récupérer toutes les fonctionnalités d'une entreprise
CREATE OR REPLACE FUNCTION get_company_features(p_company_id UUID)
RETURNS TABLE(
  feature_code TEXT,
  feature_name TEXT,
  feature_category TEXT,
  feature_description TEXT,
  is_included BOOLEAN
) AS $$
DECLARE
  v_subscription_status TEXT;
BEGIN
  -- Récupérer le statut d'abonnement
  SELECT subscription_status INTO v_subscription_status
  FROM companies
  WHERE id = p_company_id;

  -- Pendant la période d'essai, retourner toutes les fonctionnalités
  IF v_subscription_status = 'trial' THEN
    RETURN QUERY
    SELECT 
      f.code,
      f.name,
      f.category,
      f.description,
      true AS is_included
    FROM subscription_features f;
    RETURN;
  END IF;

  -- Pour les abonnements actifs, retourner les fonctionnalités du plan
  IF v_subscription_status = 'active' THEN
    RETURN QUERY
    SELECT 
      (feature->>'code')::TEXT,
      (feature->>'name')::TEXT,
      (feature->>'category')::TEXT,
      (feature->>'description')::TEXT,
      (feature->>'is_included')::boolean
    FROM companies c
    JOIN subscription_plans sp ON c.current_plan_id = sp.id
    CROSS JOIN LATERAL jsonb_array_elements(sp.features) AS feature
    WHERE c.id = p_company_id
      AND (feature->>'is_included')::boolean = true;
    RETURN;
  END IF;

  -- Pour tous les autres statuts, pas de fonctionnalités
  RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;