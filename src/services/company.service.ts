import { supabase } from './supabase';

export interface CompanySettings {
  id?: string;
  company_name: string;
  email?: string;
  phone?: string;
  address?: string;
  logo_url?: string;
  website?: string;
  tax_id?: string;
  rccm?: string;
  ncc?: string;
  created_at?: string;
  updated_at?: string;
}

export const companyService = {
  async getSettings(): Promise<CompanySettings | null> {
    const { data, error } = await supabase
      .from('company_settings')
      .select('*')
      .limit(1)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async updateSettings(settings: Partial<CompanySettings>): Promise<CompanySettings> {
    const current = await this.getSettings();

    if (!current) {
      const { data, error } = await supabase
        .from('company_settings')
        .insert({
          company_name: settings.company_name || 'Mon Entreprise',
          email: settings.email,
          phone: settings.phone,
          address: settings.address,
          logo_url: settings.logo_url,
          website: settings.website,
          tax_id: settings.tax_id,
          rccm: settings.rccm,
          ncc: settings.ncc,
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    }

    const { data, error } = await supabase
      .from('company_settings')
      .update({
        ...settings,
        updated_at: new Date().toISOString(),
      })
      .eq('id', current.id)
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
