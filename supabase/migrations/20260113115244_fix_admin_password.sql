/*
  # Correction du mot de passe administrateur

  1. Suppression de l'ancien utilisateur admin
  2. Re-création avec les bonnes méthodes Supabase
  
  Note: Le mot de passe sera: Admin123!
*/

-- Supprimer l'ancien profil
DELETE FROM public.profiles WHERE email = 'admin@lagrace.ci';

-- Supprimer l'ancien utilisateur de auth.users
DELETE FROM auth.users WHERE email = 'admin@lagrace.ci';
