import { supabase } from './supabase';

export interface CompanyWithStats {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  logo_url?: string;
  is_approved: boolean;
  is_approved_at?: string;
  created_at: string;
  user_count: number;
  subscription_status?: string;
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
      .select('id, is_approved, subscription_status');

    if (companiesError) throw companiesError;

    const { data: payments, error: paymentsError } = await supabase
      .from('payments')
      .select('id, status, amount, created_at, completed_at');

    if (paymentsError) throw paymentsError;

    const totalCompanies = companies?.length || 0;
    const activeCompanies = companies?.filter(c => c.is_approved).length || 0;
    const pendingCompanies = companies?.filter(c => !c.is_approved).length || 0;

    const totalSubscriptions = companies?.filter(c =>
      c.subscription_status === 'active' || c.subscription_status === 'trial'
    ).length || 0;

    const activeSubscriptions = companies?.filter(c =>
      c.subscription_status === 'active'
    ).length || 0;

    const completedPayments = payments?.filter(p => p.status === 'completed') || [];
    const totalRevenue = completedPayments.reduce((sum, p) => sum + (p.amount || 0), 0) || 0;

    const currentMonth = new Date();
    currentMonth.setDate(1);
    currentMonth.setHours(0, 0, 0, 0);

    const monthlyRevenue = completedPayments.filter(p => {
      const paymentDate = new Date(p.completed_at || p.created_at);
      return paymentDate >= currentMonth;
    }).reduce((sum, p) => sum + (p.amount || 0), 0) || 0;

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
