import { supabase } from './supabase';

export interface SubscriptionInfo {
  company_id: string;
  trial_days: number;
  trial_end_date: string | null;
  subscription_status: 'trial' | 'active' | 'expired' | 'suspended';
  subscription_end_date: string | null;
  blocked_reason: string | null;
}

export class SubscriptionService {
  async grantTrial(companyId: string, trialDays: number) {
    const trialEndDate = new Date();
    trialEndDate.setDate(trialEndDate.getDate() + trialDays);

    const { error } = await supabase
      .from('companies')
      .update({
        trial_days: trialDays,
        trial_end_date: trialEndDate.toISOString(),
        subscription_status: 'trial',
        blocked_reason: null,
      })
      .eq('id', companyId);

    if (error) throw error;
  }

  async activateSubscription(companyId: string, durationDays: number) {
    const subscriptionEndDate = new Date();
    subscriptionEndDate.setDate(subscriptionEndDate.getDate() + durationDays);

    const { error } = await supabase
      .from('companies')
      .update({
        subscription_status: 'active',
        subscription_end_date: subscriptionEndDate.toISOString(),
        blocked_reason: null,
      })
      .eq('id', companyId);

    if (error) throw error;
  }

  async extendSubscription(companyId: string, additionalDays: number) {
    const { data: company, error: fetchError } = await supabase
      .from('companies')
      .select('subscription_end_date, subscription_status')
      .eq('id', companyId)
      .maybeSingle();

    if (fetchError) throw fetchError;

    let newEndDate: Date;

    if (company?.subscription_end_date && new Date(company.subscription_end_date) > new Date()) {
      newEndDate = new Date(company.subscription_end_date);
    } else {
      newEndDate = new Date();
    }

    newEndDate.setDate(newEndDate.getDate() + additionalDays);

    const { error } = await supabase
      .from('companies')
      .update({
        subscription_status: 'active',
        subscription_end_date: newEndDate.toISOString(),
        blocked_reason: null,
      })
      .eq('id', companyId);

    if (error) throw error;
  }

  async suspendCompany(companyId: string, reason: string) {
    const { error } = await supabase
      .from('companies')
      .update({
        subscription_status: 'suspended',
        blocked_reason: reason,
      })
      .eq('id', companyId);

    if (error) throw error;
  }

  async reactivateCompany(companyId: string) {
    const { data: company, error: fetchError } = await supabase
      .from('companies')
      .select('trial_end_date, subscription_end_date')
      .eq('id', companyId)
      .maybeSingle();

    if (fetchError) throw fetchError;

    let newStatus: 'trial' | 'active' | 'expired' = 'expired';

    if (company?.trial_end_date && new Date(company.trial_end_date) > new Date()) {
      newStatus = 'trial';
    } else if (company?.subscription_end_date && new Date(company.subscription_end_date) > new Date()) {
      newStatus = 'active';
    }

    const { error } = await supabase
      .from('companies')
      .update({
        subscription_status: newStatus,
        blocked_reason: null,
      })
      .eq('id', companyId);

    if (error) throw error;
  }

  async getSubscriptionInfo(companyId: string): Promise<SubscriptionInfo | null> {
    const { data, error } = await supabase
      .from('companies')
      .select('id, trial_days, trial_end_date, subscription_status, subscription_end_date, blocked_reason')
      .eq('id', companyId)
      .maybeSingle();

    if (error) throw error;

    return data ? {
      company_id: data.id,
      trial_days: data.trial_days,
      trial_end_date: data.trial_end_date,
      subscription_status: data.subscription_status,
      subscription_end_date: data.subscription_end_date,
      blocked_reason: data.blocked_reason,
    } : null;
  }

  async updateExpiredCompanies() {
    const { error } = await supabase.rpc('update_expired_companies');
    if (error) throw error;
  }

  async getAllCompaniesSubscriptionStatus() {
    const { data, error } = await supabase
      .from('companies')
      .select(`
        id,
        name,
        trial_days,
        trial_end_date,
        subscription_status,
        subscription_end_date,
        blocked_reason,
        is_approved
      `)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  }
}

export const subscriptionService = new SubscriptionService();
