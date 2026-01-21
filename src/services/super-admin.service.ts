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

export interface SuperAdminStats {
  total_companies: number;
  active_companies: number;
  pending_companies: number;
  total_subscriptions: number;
  active_subscriptions: number;
  total_revenue: number;
  monthly_revenue: number;
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

  async getSuperAdminStats(): Promise<SuperAdminStats> {
    const { data: companies, error: companiesError } = await supabase
      .from('companies')
      .select('id, approved');

    if (companiesError) throw companiesError;

    const { data: subscriptions, error: subscriptionsError } = await supabase
      .from('subscriptions')
      .select('id, status, amount, start_date, end_date');

    if (subscriptionsError) throw subscriptionsError;

    const totalCompanies = companies?.length || 0;
    const activeCompanies = companies?.filter(c => c.approved).length || 0;
    const pendingCompanies = companies?.filter(c => !c.approved).length || 0;

    const totalSubscriptions = subscriptions?.length || 0;
    const activeSubscriptions = subscriptions?.filter(s => {
      if (s.status !== 'active') return false;
      const endDate = s.end_date ? new Date(s.end_date) : null;
      return !endDate || endDate > new Date();
    }).length || 0;

    const totalRevenue = subscriptions?.reduce((sum, s) => sum + (s.amount || 0), 0) || 0;

    const currentMonth = new Date();
    currentMonth.setDate(1);
    currentMonth.setHours(0, 0, 0, 0);

    const monthlyRevenue = subscriptions?.filter(s => {
      const startDate = new Date(s.start_date);
      return startDate >= currentMonth;
    }).reduce((sum, s) => sum + (s.amount || 0), 0) || 0;

    return {
      total_companies: totalCompanies,
      active_companies: activeCompanies,
      pending_companies: pendingCompanies,
      total_subscriptions: totalSubscriptions,
      active_subscriptions: activeSubscriptions,
      total_revenue: totalRevenue,
      monthly_revenue: monthlyRevenue,
    };
  }
}

export const superAdminService = new SuperAdminService();
