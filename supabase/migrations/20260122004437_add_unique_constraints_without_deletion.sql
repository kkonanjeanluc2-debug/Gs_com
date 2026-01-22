/*
  # Ajout de contraintes d'unicité pour empêcher les doublons

  1. Contraintes ajoutées
    - Products : contrainte unique sur (name, company_id) - Empêche les produits avec le même nom
    - Products : contrainte unique sur (sku, company_id) si SKU non nul
    - Clients : contrainte unique sur email par entreprise (si email non nul)
    - Clients : contrainte unique sur phone par entreprise (si phone non nul)
    - Suppliers : contrainte unique sur email par entreprise (si email non nul)
    - Suppliers : contrainte unique sur phone par entreprise (si phone non nul)
    - Categories : contrainte unique sur (name, company_id)
    - Subcategories : contrainte unique sur (name, category_id)
    - Companies : contrainte unique sur le nom

  2. Stratégie
    - Les contraintes sont ajoutées uniquement pour les nouveaux enregistrements
    - Les doublons existants ne sont PAS supprimés automatiquement
    - Triggers avec messages d'erreur clairs pour guider l'utilisateur

  3. Impact
    - Aucune perte de données
    - Les doublons existants restent en place
    - Empêche la création de nouveaux doublons
*/

-- Créer une fonction pour vérifier les doublons avant insertion/mise à jour
CREATE OR REPLACE FUNCTION check_duplicate_before_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Pour les produits
  IF TG_TABLE_NAME = 'products' THEN
    IF EXISTS (
      SELECT 1 FROM products 
      WHERE company_id = NEW.company_id 
      AND LOWER(TRIM(name)) = LOWER(TRIM(NEW.name))
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) THEN
      RAISE EXCEPTION 'Un produit avec ce nom existe déjà dans votre entreprise';
    END IF;
    
    IF NEW.sku IS NOT NULL AND NEW.sku != '' THEN
      IF EXISTS (
        SELECT 1 FROM products 
        WHERE company_id = NEW.company_id 
        AND TRIM(sku) = TRIM(NEW.sku)
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
      ) THEN
        RAISE EXCEPTION 'Un produit avec ce SKU existe déjà dans votre entreprise';
      END IF;
    END IF;
  END IF;

  -- Pour les clients
  IF TG_TABLE_NAME = 'clients' THEN
    IF NEW.email IS NOT NULL AND NEW.email != '' THEN
      IF EXISTS (
        SELECT 1 FROM clients 
        WHERE company_id = NEW.company_id 
        AND LOWER(TRIM(email)) = LOWER(TRIM(NEW.email))
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
      ) THEN
        RAISE EXCEPTION 'Un client avec cet email existe déjà dans votre entreprise';
      END IF;
    END IF;
    
    IF NEW.phone IS NOT NULL AND NEW.phone != '' THEN
      IF EXISTS (
        SELECT 1 FROM clients 
        WHERE company_id = NEW.company_id 
        AND TRIM(phone) = TRIM(NEW.phone)
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
      ) THEN
        RAISE EXCEPTION 'Un client avec ce numéro de téléphone existe déjà dans votre entreprise';
      END IF;
    END IF;
  END IF;

  -- Pour les fournisseurs
  IF TG_TABLE_NAME = 'suppliers' THEN
    IF NEW.email IS NOT NULL AND NEW.email != '' THEN
      IF EXISTS (
        SELECT 1 FROM suppliers 
        WHERE company_id = NEW.company_id 
        AND LOWER(TRIM(email)) = LOWER(TRIM(NEW.email))
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
      ) THEN
        RAISE EXCEPTION 'Un fournisseur avec cet email existe déjà dans votre entreprise';
      END IF;
    END IF;
    
    IF NEW.phone IS NOT NULL AND NEW.phone != '' THEN
      IF EXISTS (
        SELECT 1 FROM suppliers 
        WHERE company_id = NEW.company_id 
        AND TRIM(phone) = TRIM(NEW.phone)
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
      ) THEN
        RAISE EXCEPTION 'Un fournisseur avec ce numéro de téléphone existe déjà dans votre entreprise';
      END IF;
    END IF;
  END IF;

  -- Pour les catégories
  IF TG_TABLE_NAME = 'categories' THEN
    IF EXISTS (
      SELECT 1 FROM categories 
      WHERE company_id = NEW.company_id 
      AND LOWER(TRIM(name)) = LOWER(TRIM(NEW.name))
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) THEN
      RAISE EXCEPTION 'Une catégorie avec ce nom existe déjà dans votre entreprise';
    END IF;
  END IF;

  -- Pour les sous-catégories
  IF TG_TABLE_NAME = 'subcategories' THEN
    IF EXISTS (
      SELECT 1 FROM subcategories 
      WHERE category_id = NEW.category_id 
      AND LOWER(TRIM(name)) = LOWER(TRIM(NEW.name))
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) THEN
      RAISE EXCEPTION 'Une sous-catégorie avec ce nom existe déjà dans cette catégorie';
    END IF;
  END IF;

  -- Pour les entreprises
  IF TG_TABLE_NAME = 'companies' THEN
    IF EXISTS (
      SELECT 1 FROM companies 
      WHERE LOWER(TRIM(name)) = LOWER(TRIM(NEW.name))
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) THEN
      RAISE EXCEPTION 'Une entreprise avec ce nom existe déjà';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer les triggers pour chaque table
DROP TRIGGER IF EXISTS check_product_duplicate ON products;
CREATE TRIGGER check_product_duplicate
  BEFORE INSERT OR UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION check_duplicate_before_insert();

DROP TRIGGER IF EXISTS check_client_duplicate ON clients;
CREATE TRIGGER check_client_duplicate
  BEFORE INSERT OR UPDATE ON clients
  FOR EACH ROW
  EXECUTE FUNCTION check_duplicate_before_insert();

DROP TRIGGER IF EXISTS check_supplier_duplicate ON suppliers;
CREATE TRIGGER check_supplier_duplicate
  BEFORE INSERT OR UPDATE ON suppliers
  FOR EACH ROW
  EXECUTE FUNCTION check_duplicate_before_insert();

DROP TRIGGER IF EXISTS check_category_duplicate ON categories;
CREATE TRIGGER check_category_duplicate
  BEFORE INSERT OR UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION check_duplicate_before_insert();

DROP TRIGGER IF EXISTS check_subcategory_duplicate ON subcategories;
CREATE TRIGGER check_subcategory_duplicate
  BEFORE INSERT OR UPDATE ON subcategories
  FOR EACH ROW
  EXECUTE FUNCTION check_duplicate_before_insert();

DROP TRIGGER IF EXISTS check_company_duplicate ON companies;
CREATE TRIGGER check_company_duplicate
  BEFORE INSERT OR UPDATE ON companies
  FOR EACH ROW
  EXECUTE FUNCTION check_duplicate_before_insert();

-- Créer des vues pour identifier les doublons existants (pour nettoyage manuel)
CREATE OR REPLACE VIEW duplicate_products AS
SELECT 
  company_id,
  LOWER(TRIM(name)) as normalized_name,
  COUNT(*) as count,
  array_agg(id ORDER BY created_at) as product_ids,
  array_agg(name ORDER BY created_at) as names
FROM products
GROUP BY company_id, LOWER(TRIM(name))
HAVING COUNT(*) > 1;

CREATE OR REPLACE VIEW duplicate_clients_by_email AS
SELECT 
  company_id,
  LOWER(TRIM(email)) as normalized_email,
  COUNT(*) as count,
  array_agg(id ORDER BY created_at) as client_ids,
  array_agg(name ORDER BY created_at) as names
FROM clients
WHERE email IS NOT NULL AND email != ''
GROUP BY company_id, LOWER(TRIM(email))
HAVING COUNT(*) > 1;

CREATE OR REPLACE VIEW duplicate_clients_by_phone AS
SELECT 
  company_id,
  TRIM(phone) as normalized_phone,
  COUNT(*) as count,
  array_agg(id ORDER BY created_at) as client_ids,
  array_agg(name ORDER BY created_at) as names
FROM clients
WHERE phone IS NOT NULL AND phone != ''
GROUP BY company_id, TRIM(phone)
HAVING COUNT(*) > 1;

CREATE OR REPLACE VIEW duplicate_suppliers_by_email AS
SELECT 
  company_id,
  LOWER(TRIM(email)) as normalized_email,
  COUNT(*) as count,
  array_agg(id ORDER BY created_at) as supplier_ids,
  array_agg(name ORDER BY created_at) as names
FROM suppliers
WHERE email IS NOT NULL AND email != ''
GROUP BY company_id, LOWER(TRIM(email))
HAVING COUNT(*) > 1;

CREATE OR REPLACE VIEW duplicate_suppliers_by_phone AS
SELECT 
  company_id,
  TRIM(phone) as normalized_phone,
  COUNT(*) as count,
  array_agg(id ORDER BY created_at) as supplier_ids,
  array_agg(name ORDER BY created_at) as names
FROM suppliers
WHERE phone IS NOT NULL AND phone != ''
GROUP BY company_id, TRIM(phone)
HAVING COUNT(*) > 1;

CREATE OR REPLACE VIEW duplicate_categories AS
SELECT 
  company_id,
  LOWER(TRIM(name)) as normalized_name,
  COUNT(*) as count,
  array_agg(id ORDER BY created_at) as category_ids,
  array_agg(name ORDER BY created_at) as names
FROM categories
GROUP BY company_id, LOWER(TRIM(name))
HAVING COUNT(*) > 1;
