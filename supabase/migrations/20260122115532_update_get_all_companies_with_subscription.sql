/*
  # Mise à jour de la fonction get_all_companies pour inclure le statut d'abonnement

  1. Modifications
    - Suppression de l'ancienne fonction
    - Ajout du champ subscription_status dans le retour de la fonction
    - Ajout du champ subscription_end_date dans le retour de la fonction
    - Permet au super admin de voir les informations d'abonnement de chaque entreprise
    
  2. Sécurité
    - La fonction vérifie toujours que seul un super_admin peut l'exécuter
*/

DROP FUNCTION IF EXISTS get_all_companies();

CREATE OR REPLACE FUNCTION get_all_companies()
RETURNS TABLE (
  id uuid,
  name text,
  email text,
  phone text,
  address text,
  logo_url text,
  approved boolean,
  approved_at timestamptz,
  created_at timestamptz,
  user_count bigint,
  subscription_status text,
  subscription_end_date timestamptz
) AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Accès refusé: super admin uniquement';
  END IF;

  RETURN QUERY
  SELECT 
    c.id,
    c.name,
    c.email,
    c.phone,
    c.address,
    c.logo_url,
    c.is_approved as approved,
    c.is_approved_at as approved_at,
    c.created_at,
    COUNT(p.id) as user_count,
    c.subscription_status,
    c.subscription_end_date
  FROM companies c
  LEFT JOIN profiles p ON p.company_id = c.id
  GROUP BY c.id, c.name, c.email, c.phone, c.address, c.logo_url, 
           c.is_approved, c.is_approved_at, c.created_at, 
           c.subscription_status, c.subscription_end_date
  ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;