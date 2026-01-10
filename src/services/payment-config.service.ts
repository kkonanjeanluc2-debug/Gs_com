import { supabase, getCurrentUserCompanyId } from './supabase';

export type PaymentProvider = 'wave' | 'orange_money' | 'mtn_money' | 'moov_money' | 'paydunya';

export interface PaymentConfiguration {
  id: string;
  company_id: string;
  provider: PaymentProvider;
  is_enabled: boolean;
  api_key?: string;
  api_secret?: string;
  merchant_id?: string;
  master_key?: string;
  webhook_url?: string;
  test_mode: boolean;
  config_data: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface PaymentConfigInput {
  provider: PaymentProvider;
  is_enabled: boolean;
  api_key?: string;
  api_secret?: string;
  merchant_id?: string;
  master_key?: string;
  test_mode: boolean;
  config_data?: Record<string, any>;
}

class PaymentConfigService {
  async getAllConfigurations(): Promise<PaymentConfiguration[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('payment_configurations')
      .select('*')
      .eq('company_id', company_id)
      .order('provider');

    if (error) throw error;
    return data || [];
  }

  async getConfiguration(provider: PaymentProvider): Promise<PaymentConfiguration | null> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('payment_configurations')
      .select('*')
      .eq('company_id', company_id)
      .eq('provider', provider)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  async getEnabledConfigurations(): Promise<PaymentConfiguration[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('payment_configurations')
      .select('*')
      .eq('company_id', company_id)
      .eq('is_enabled', true)
      .order('provider');

    if (error) throw error;
    return data || [];
  }

  async createOrUpdateConfiguration(input: PaymentConfigInput): Promise<PaymentConfiguration> {
    const company_id = await getCurrentUserCompanyId();

    const existing = await this.getConfiguration(input.provider);

    if (existing) {
      const { data, error } = await supabase
        .from('payment_configurations')
        .update({
          is_enabled: input.is_enabled,
          api_key: input.api_key,
          api_secret: input.api_secret,
          merchant_id: input.merchant_id,
          master_key: input.master_key,
          test_mode: input.test_mode,
          config_data: input.config_data || {},
          updated_at: new Date().toISOString()
        })
        .eq('id', existing.id)
        .select()
        .single();

      if (error) throw error;
      return data;
    } else {
      const { data, error } = await supabase
        .from('payment_configurations')
        .insert({
          company_id,
          provider: input.provider,
          is_enabled: input.is_enabled,
          api_key: input.api_key,
          api_secret: input.api_secret,
          merchant_id: input.merchant_id,
          master_key: input.master_key,
          test_mode: input.test_mode,
          config_data: input.config_data || {}
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    }
  }

  async deleteConfiguration(provider: PaymentProvider): Promise<void> {
    const company_id = await getCurrentUserCompanyId();

    const { error } = await supabase
      .from('payment_configurations')
      .delete()
      .eq('company_id', company_id)
      .eq('provider', provider);

    if (error) throw error;
  }

  getProviderLabel(provider: PaymentProvider): string {
    const labels: Record<PaymentProvider, string> = {
      'wave': 'Wave',
      'orange_money': 'Orange Money',
      'mtn_money': 'MTN Mobile Money',
      'moov_money': 'Moov Money',
      'paydunya': 'PayDunya'
    };
    return labels[provider];
  }

  getProviderDescription(provider: PaymentProvider): string {
    const descriptions: Record<PaymentProvider, string> = {
      'wave': 'Paiement mobile via Wave',
      'orange_money': 'Paiement mobile Orange Money',
      'mtn_money': 'Paiement mobile MTN Mobile Money',
      'moov_money': 'Paiement mobile Moov Money',
      'paydunya': 'Passerelle de paiement PayDunya (Mobile Money, Cartes bancaires)'
    };
    return descriptions[provider];
  }
}

export const paymentConfigService = new PaymentConfigService();
