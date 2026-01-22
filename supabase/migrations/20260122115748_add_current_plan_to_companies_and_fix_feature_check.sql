/*
  # Ajout du plan actuel aux entreprises et correction de la vérification des fonctionnalités

  1. Modifications
    - Ajout du champ current_plan_id dans la table companies
    - Mise à jour de la fonction company_has_feature pour utiliser le plan depuis companies
    - Permet de vérifier correctement les fonctionnalités disponibles selon le plan
    
  2. Sécurité
    - Maintien des vérifications RLS existantes
    - La fonction vérifie le statut d'abonnement avant d'autoriser l'accès aux fonctionnalités
*/

ALTER TABLE companies ADD COLUMN IF NOT EXISTS current_plan_id uuid REFERENCES subscription_plans(id);

CREATE OR REPLACE FUNCTION company_has_feature(company_uuid uuid, feature_code_param text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  has_access boolean := false;
  company_status text;
  company_sub_end_date timestamptz;
  plan_uuid uuid;
BEGIN
  SELECT subscription_status, subscription_end_date, current_plan_id
  INTO company_status, company_sub_end_date, plan_uuid
  FROM companies
  WHERE id = company_uuid;

  IF company_status IN ('trial', 'active') THEN
    IF company_sub_end_date IS NULL OR company_sub_end_date > NOW() THEN
      IF plan_uuid IS NOT NULL THEN
        SELECT EXISTS (
          SELECT 1
          FROM subscription_plan_features spf
          JOIN features f ON f.id = spf.feature_id
          WHERE spf.plan_id = plan_uuid
          AND f.code = feature_code_param
          AND spf.is_included = true
          AND f.is_active = true
        ) INTO has_access;
      ELSE
        has_access := true;
      END IF;
    END IF;
  END IF;

  RETURN has_access;
END;
$$;

GRANT EXECUTE ON FUNCTION company_has_feature(uuid, text) TO authenticated;