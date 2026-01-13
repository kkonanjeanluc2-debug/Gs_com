import { supabase } from './supabase';

export interface CompanyWithStats {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  logo_url?: string;
  approved: boolean;
  approved_at?: string;
  created_at: string;
  user_count: number;
}

export class SuperAdminService {
  async getAllCompanies(): Promise<CompanyWithStats[]> {
    const { data, error } = await supabase.rpc('get_all_companies');

    if (error) throw error;
    return data || [];
  }

  async approveCompany(companyId: string): Promise<void> {
    const { error } = await supabase.rpc('approve_company', {
      company_uuid: companyId
    });

    if (error) throw error;
  }

  async revokeCompanyApproval(companyId: string): Promise<void> {
    const { error } = await supabase.rpc('revoke_company_approval', {
      company_uuid: companyId
    });

    if (error) throw error;
  }

  async deleteCompany(companyId: string): Promise<void> {
    const { error } = await supabase.rpc('delete_company', {
      company_uuid: companyId
    });

    if (error) throw error;
  }

  async checkIsSuperAdmin(): Promise<boolean> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();

    return profile?.role === 'super_admin';
  }
}

export const superAdminService = new SuperAdminService();
