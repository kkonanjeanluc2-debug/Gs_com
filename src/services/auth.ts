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

      if (profile && profile.role !== 'super_admin' && profile.company_id) {
        const { data: company } = await supabase
          .from('companies')
          .select('is_approved, subscription_status, trial_end_date, subscription_end_date, blocked_reason')
          .eq('id', profile.company_id)
          .maybeSingle();

        if (company) {
          if (!company.is_approved) {
            await supabase.auth.signOut();
            throw new Error('Votre entreprise est en attente d\'approbation. Veuillez contacter l\'administrateur.');
          }

          const now = new Date();
          let isBlocked = false;
          let blockMessage = '';

          if (company.subscription_status === 'trial') {
            if (company.trial_end_date && new Date(company.trial_end_date) < now) {
              isBlocked = true;
              blockMessage = 'Votre période d\'essai a expiré. Veuillez contacter l\'administrateur pour activer votre abonnement.';
            }
          } else if (company.subscription_status === 'active') {
            if (company.subscription_end_date && new Date(company.subscription_end_date) < now) {
              isBlocked = true;
              blockMessage = 'Votre abonnement a expiré. Veuillez contacter l\'administrateur pour le renouveler.';
            }
          } else if (company.subscription_status === 'expired') {
            isBlocked = true;
            blockMessage = company.blocked_reason || 'Votre accès a expiré. Veuillez contacter l\'administrateur.';
          } else if (company.subscription_status === 'suspended') {
            isBlocked = true;
            blockMessage = company.blocked_reason || 'Votre compte a été suspendu. Veuillez contacter l\'administrateur.';
          }

          if (isBlocked) {
            await supabase.auth.signOut();
            throw new Error(blockMessage);
          }
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

  async resetPassword(email: string) {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/#/reset-password`,
    });
    if (error) throw error;
  }

  async updatePassword(newPassword: string) {
    const { error } = await supabase.auth.updateUser({
      password: newPassword,
    });
    if (error) throw error;
  }
}

export const authService = new AuthService();
