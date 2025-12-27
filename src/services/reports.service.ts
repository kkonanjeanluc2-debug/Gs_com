import { supabase, type ReportDB, getCurrentUserCompanyId } from './supabase';

export class ReportsService {
  async createReport(report: Omit<ReportDB, 'id' | 'created_at' | 'updated_at'>) {
    const company_id = await getCurrentUserCompanyId();
    const { data, error } = await supabase
      .from('reports')
      .insert({ ...report, company_id })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateReport(id: string, updates: Partial<ReportDB>) {
    const { data, error } = await supabase
      .from('reports')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async deleteReport(id: string) {
    const { error } = await supabase
      .from('reports')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  async getReport(id: string) {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('reports')
      .select('*')
      .eq('id', id)
      .eq('company_id', companyId)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  async getAllReports() {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('reports')
      .select(`
        *,
        commercial:profiles(full_name, email, phone)
      `)
      .eq('company_id', companyId)
      .order('date', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async getMyReports(userId: string) {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('reports')
      .select(`
        *,
        commercial:profiles(full_name, email, phone)
      `)
      .eq('user_id', userId)
      .eq('company_id', companyId)
      .order('date', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async getReportsByDateRange(startDate: string, endDate: string) {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('reports')
      .select(`
        *,
        commercial:profiles(full_name, email, phone)
      `)
      .eq('company_id', companyId)
      .gte('date', startDate)
      .lte('date', endDate)
      .order('date', { ascending: false });

    if (error) throw error;
    return data || [];
  }
}

export const reportsService = new ReportsService();
