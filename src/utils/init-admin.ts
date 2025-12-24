import { supabase } from '../services/supabase';

export async function initializeAdmin() {
  try {
    const { data: profiles, error: checkError } = await supabase
      .from('profiles')
      .select('id')
      .eq('role', 'admin')
      .maybeSingle();

    if (checkError) {
      console.error('Erreur lors de la vérification admin:', checkError);
      return;
    }

    if (!profiles) {
      console.log('Aucun admin trouvé. Créez un compte avec les identifiants suivants:');
      console.log('Email: admin@entreprise.ci');
      console.log('Mot de passe: Admin123!');
      console.log('\nPuis exécutez cette requête SQL dans le Dashboard Supabase:');
      console.log('-- Après création du compte, copiez son UUID et exécutez:');
      console.log("INSERT INTO profiles (id, email, full_name, role)");
      console.log("VALUES ('UUID_DU_COMPTE', 'admin@entreprise.ci', 'Administrateur', 'admin');");
    }
  } catch (error) {
    console.error('Erreur initialisation admin:', error);
  }
}
