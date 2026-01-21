import { supabase } from './supabase';

export interface SubscriptionInfo {
  company_id: string;
  trial_days: number;
  trial_end_date: string | null;
  subscription_status: 'trial' | 'active' | 'expired' | 'suspended';
  subscription_end_date: string | null;
  blocked_reason: string | null;
}

export interface Feature {
  id: string;
  code: string;
  name: string;
  description: string;
  category: 'core' | 'advanced' | 'premium' | 'enterprise';
  is_active: boolean;
  display_order: number;
  created_at: string;
  updated_at: string;
}

export interface SubscriptionPlan {
  id: string;
  name: string;
  duration_days: number;
  price: number;
  description: string;
  is_active: boolean;
  features: Feature[];
  created_at: string;
}

export interface PlanFeature {
  id: string;
  plan_id: string;
  feature_id: string;
  is_included: boolean;
  created_at: string;
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

  async getAllFeatures(): Promise<Feature[]> {
    const { data, error } = await supabase
      .from('features')
      .select('*')
      .order('display_order', { ascending: true });

    if (error) throw error;
    return data || [];
  }

  async createFeature(feature: Omit<Feature, 'id' | 'created_at' | 'updated_at'>): Promise<Feature> {
    const { data, error } = await supabase
      .from('features')
      .insert(feature)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateFeature(featureId: string, updates: Partial<Feature>): Promise<Feature> {
    const { data, error } = await supabase
      .from('features')
      .update(updates)
      .eq('id', featureId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async deleteFeature(featureId: string): Promise<void> {
    const { error } = await supabase
      .from('features')
      .delete()
      .eq('id', featureId);

    if (error) throw error;
  }

  async getAllSubscriptionPlans(): Promise<SubscriptionPlan[]> {
    const { data, error } = await supabase
      .from('subscription_plans')
      .select('*')
      .order('price', { ascending: true });

    if (error) throw error;
    return data || [];
  }

  async createSubscriptionPlan(plan: Omit<SubscriptionPlan, 'id' | 'created_at' | 'features'>): Promise<SubscriptionPlan> {
    const { data, error } = await supabase
      .from('subscription_plans')
      .insert(plan)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateSubscriptionPlan(planId: string, updates: Partial<SubscriptionPlan>): Promise<SubscriptionPlan> {
    const { data, error } = await supabase
      .from('subscription_plans')
      .update(updates)
      .eq('id', planId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async deleteSubscriptionPlan(planId: string): Promise<void> {
    const { error } = await supabase
      .from('subscription_plans')
      .delete()
      .eq('id', planId);

    if (error) throw error;
  }

  async getPlanFeatures(planId: string): Promise<PlanFeature[]> {
    const { data, error } = await supabase
      .from('subscription_plan_features')
      .select('*')
      .eq('plan_id', planId);

    if (error) throw error;
    return data || [];
  }

  async updatePlanFeatures(planId: string, featureIds: string[]): Promise<void> {
    const { error: deleteError } = await supabase
      .from('subscription_plan_features')
      .delete()
      .eq('plan_id', planId);

    if (deleteError) throw deleteError;

    if (featureIds.length > 0) {
      const planFeatures = featureIds.map(featureId => ({
        plan_id: planId,
        feature_id: featureId,
        is_included: true,
      }));

      const { error: insertError } = await supabase
        .from('subscription_plan_features')
        .insert(planFeatures);

      if (insertError) throw insertError;
    }
  }

  async checkCompanyHasFeature(companyId: string, featureCode: string): Promise<boolean> {
    const { data, error } = await supabase.rpc('company_has_feature', {
      company_uuid: companyId,
      feature_code_param: featureCode,
    });

    if (error) throw error;
    return data || false;
  }
}

export const subscriptionService = new SubscriptionService();
