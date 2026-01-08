import { supabase, getCurrentUserCompanyId } from './supabase';

export interface CompanySettings {
  id?: string;
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  logo_url?: string;
  website?: string;
  tax_id?: string;
  rccm?: string;
  ncc?: string;
  commission_rate?: number;
  created_at?: string;
  updated_at?: string;
}

export const companyService = {
  async getCurrentCompanyId(): Promise<string | null> {
    return await getCurrentUserCompanyId();
  },

  async getSettings(): Promise<CompanySettings | null> {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('id', companyId)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async getPublicSettings(): Promise<CompanySettings | null> {
    const { data, error } = await supabase
      .from('companies')
      .select('id, name, logo_url')
      .eq('is_approved', true)
      .limit(1)
      .maybeSingle();

    if (error) {
      console.error('Error fetching public settings:', error);
      return null;
    }
    return data;
  },

  async updateSettings(settings: Partial<CompanySettings>): Promise<CompanySettings> {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('companies')
      .update({
        name: settings.name,
        email: settings.email,
        phone: settings.phone,
        address: settings.address,
        logo_url: settings.logo_url,
        website: settings.website,
        tax_id: settings.tax_id,
        rccm: settings.rccm,
        ncc: settings.ncc,
        commission_rate: settings.commission_rate,
        updated_at: new Date().toISOString(),
      })
      .eq('id', companyId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async uploadLogo(file: File): Promise<string> {
    const fileExt = file.name.split('.').pop();
    const fileName = `logo-${Date.now()}.${fileExt}`;
    const filePath = `${fileName}`;

    const { error: uploadError } = await supabase.storage
      .from('company-logos')
      .upload(filePath, file, { upsert: true });

    if (uploadError) throw uploadError;

    const { data } = supabase.storage
      .from('company-logos')
      .getPublicUrl(filePath);

    return data.publicUrl;
  },

  async deleteLogo(logoUrl: string): Promise<void> {
    const path = logoUrl.split('/company-logos/')[1];
    if (!path) return;

    const { error } = await supabase.storage
      .from('company-logos')
      .remove([path]);

    if (error) throw error;
  },
};
