/*
  # Seed Subcategories for BUREAUTIQUES and SCOLAIRES

  1. New Subcategories
    
    ## BUREAUTIQUES
    - Papeterie - Papiers, enveloppes, blocs-notes
    - Fournitures de bureau - Agrafeuses, perforateurs, trombones
    - Classement et archivage - Classeurs, chemises, boîtes d'archivage
    - Équipements de bureau - Calculatrices, destructeurs, laminateurs
    - Informatique et technologie - Clés USB, câbles, accessoires informatiques
    
    ## SCOLAIRES
    - Cahiers et carnets - Cahiers grands formats, petits formats, carnets
    - Stylos et crayons - Stylos, crayons à papier, feutres, surligneurs
    - Matériel de géométrie - Règles, équerres, compas, rapporteurs
    - Arts plastiques - Peinture, pinceaux, papiers colorés, ciseaux
    - Sacs et trousses - Cartables, sacs à dos, trousses
    - Manuels scolaires - Livres scolaires, guides pédagogiques
  
  2. Notes
    - Creates subcategories for both categories
    - Each subcategory is linked to its parent category
*/

-- Insert subcategories for BUREAUTIQUES
INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Papeterie',
  'Papiers, enveloppes, blocs-notes'
FROM categories WHERE name = 'BUREAUTIQUES'
ON CONFLICT (category_id, name) DO NOTHING;

INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Fournitures de bureau',
  'Agrafeuses, perforateurs, trombones, élastiques'
FROM categories WHERE name = 'BUREAUTIQUES'
ON CONFLICT (category_id, name) DO NOTHING;

INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Classement et archivage',
  'Classeurs, chemises, boîtes d''archivage, intercalaires'
FROM categories WHERE name = 'BUREAUTIQUES'
ON CONFLICT (category_id, name) DO NOTHING;

INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Équipements de bureau',
  'Calculatrices, destructeurs, laminateurs, relieuses'
FROM categories WHERE name = 'BUREAUTIQUES'
ON CONFLICT (category_id, name) DO NOTHING;

INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Informatique et technologie',
  'Clés USB, câbles, souris, claviers, accessoires informatiques'
FROM categories WHERE name = 'BUREAUTIQUES'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert subcategories for SCOLAIRES
INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Cahiers et carnets',
  'Cahiers grands formats, petits formats, carnets'
FROM categories WHERE name = 'SCOLAIRES'
ON CONFLICT (category_id, name) DO NOTHING;

INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Stylos et crayons',
  'Stylos, crayons à papier, feutres, surligneurs, marqueurs'
FROM categories WHERE name = 'SCOLAIRES'
ON CONFLICT (category_id, name) DO NOTHING;

INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Matériel de géométrie',
  'Règles, équerres, compas, rapporteurs, gabarits'
FROM categories WHERE name = 'SCOLAIRES'
ON CONFLICT (category_id, name) DO NOTHING;

INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Arts plastiques',
  'Peinture, pinceaux, papiers colorés, ciseaux, colle'
FROM categories WHERE name = 'SCOLAIRES'
ON CONFLICT (category_id, name) DO NOTHING;

INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Sacs et trousses',
  'Cartables, sacs à dos, trousses, pochettes'
FROM categories WHERE name = 'SCOLAIRES'
ON CONFLICT (category_id, name) DO NOTHING;

INSERT INTO subcategories (category_id, name, description)
SELECT 
  id,
  'Manuels scolaires',
  'Livres scolaires, guides pédagogiques, dictionnaires'
FROM categories WHERE name = 'SCOLAIRES'
ON CONFLICT (category_id, name) DO NOTHING;