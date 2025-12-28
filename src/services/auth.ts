import { supabase, type Profile } from './supabase';

export class AuthService {
  async signUp(email: string, password: string, fullName: string, role: 'admin' | 'superviseur' | 'commercial') {
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          role: role,
        },
      },
    });

    if (authError) throw authError;

    return authData;
  }

  async signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;

    if (data.user) {
      const { data: profile } = await supabase
        .from('profiles')
        .select('company_id, role')
        .eq('id', data.user.id)
        .maybeSingle();

      if (profile && profile.role !== 'super_admin') {
        const { data: company } = await supabase
          .from('companies')
          .select('approved')
          .eq('id', profile.company_id)
          .maybeSingle();

        if (company && !company.approved) {
          await supabase.auth.signOut();
          throw new Error('Votre entreprise est en attente d\'approbation. Veuillez contacter l\'administrateur.');
        }
      }
    }

    return data;
  }

  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  }

  async getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error) throw error;
    return user;
  }

  async getCurrentProfile(): Promise<Profile | null> {
    const user = await this.getCurrentUser();
    if (!user) return null;

    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  onAuthStateChange(callback: (session: any) => void) {
    return supabase.auth.onAuthStateChange((_event, session) => {
      callback(session);
    });
  }
}

export const authService = new AuthService();
