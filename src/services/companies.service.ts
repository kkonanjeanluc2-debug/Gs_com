import { supabase } from './supabase';

export interface Company {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  address: string | null;
  logo_url: string | null;
  website: string | null;
  tax_id: string | null;
  rccm: string | null;
  ncc: string | null;
  business_sector?: string | null;
  status: 'active' | 'suspended' | 'inactive';
  subscription_plan: 'free' | 'basic' | 'premium';
  max_users: number;
  created_at: string;
  updated_at: string;
}

export interface RegisterCompanyData {
  companyName: string;
  companyEmail: string;
  companyPhone?: string;
  businessSector: string;
  adminEmail: string;
  adminPassword: string;
  adminName: string;
}

class CompaniesService {
  async registerCompany(data: RegisterCompanyData): Promise<void> {
    const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/register-company`;

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });

    const result = await response.json();

    if (!response.ok) {
      const error: any = new Error(result.error || 'Erreur lors de l\'inscription de l\'entreprise');
      error.details = result.details;
      error.code = result.code;
      throw error;
    }
  }

  async getCurrentCompany(): Promise<Company | null> {
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return null;
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', user.id)
      .maybeSingle();

    if (!profile?.company_id) {
      return null;
    }

    const { data: company, error } = await supabase
      .from('companies')
      .select('*')
      .eq('id', profile.company_id)
      .maybeSingle();

    if (error) {
      console.error('Error loading company:', error);
      throw error;
    }

    return company;
  }

  async updateCompany(companyId: string, data: Partial<Company>): Promise<void> {
    const { error } = await supabase
      .from('companies')
      .update({
        ...data,
        updated_at: new Date().toISOString(),
      })
      .eq('id', companyId);

    if (error) {
      console.error('Error updating company:', error);
      throw error;
    }
  }
}

export const companiesService = new CompaniesService();
