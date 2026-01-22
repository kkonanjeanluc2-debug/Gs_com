import { supabase } from './supabase';

export interface CompanyFeature {
  feature_code: string;
  feature_name: string;
  feature_category: string;
  feature_description: string;
  is_included: boolean;
}

export const FEATURE_CODES = {
  SALES_MANAGEMENT: 'sales_management',
  CLIENT_MANAGEMENT: 'client_management',
  PRODUCT_CATALOG: 'product_catalog',
  BASIC_REPORTS: 'basic_reports',
  INVENTORY_TRACKING: 'inventory_tracking',
  COMMERCIAL_TRACKING: 'commercial_tracking',
  PURCHASE_MANAGEMENT: 'purchase_management',
  INVOICING: 'invoicing',
  PAYMENT_TRACKING: 'payment_tracking',
  ADVANCED_ANALYTICS: 'advanced_analytics',
  MULTI_USER: 'multi_user',
  API_ACCESS: 'api_access',
  MOBILE_APP: 'mobile_app',
  PRIORITY_SUPPORT: 'priority_support',
} as const;

class FeaturesService {
  private featuresCache: Map<string, CompanyFeature[]> = new Map();
  private cacheExpiry: Map<string, number> = new Map();
  private readonly CACHE_DURATION = 5 * 60 * 1000;

  async checkFeature(companyId: string, featureCode: string): Promise<boolean> {
    try {
      const { data, error } = await supabase.rpc('check_company_feature', {
        p_company_id: companyId,
        p_feature_code: featureCode,
      });

      if (error) {
        console.error('Error checking feature:', error);
        return false;
      }

      return data === true;
    } catch (error) {
      console.error('Error checking feature:', error);
      return false;
    }
  }

  async getCompanyFeatures(companyId: string, forceRefresh = false): Promise<CompanyFeature[]> {
    const now = Date.now();
    const cachedExpiry = this.cacheExpiry.get(companyId);

    if (!forceRefresh && cachedExpiry && now < cachedExpiry) {
      const cached = this.featuresCache.get(companyId);
      if (cached) {
        return cached;
      }
    }

    try {
      const { data, error } = await supabase.rpc('get_company_features', {
        p_company_id: companyId,
      });

      if (error) {
        console.error('Error fetching company features:', error);
        return [];
      }

      const features = data as CompanyFeature[];
      this.featuresCache.set(companyId, features);
      this.cacheExpiry.set(companyId, now + this.CACHE_DURATION);

      return features;
    } catch (error) {
      console.error('Error fetching company features:', error);
      return [];
    }
  }

  async hasFeatures(companyId: string, featureCodes: string[]): Promise<Record<string, boolean>> {
    const features = await this.getCompanyFeatures(companyId);
    const featureMap = new Set(features.map(f => f.feature_code));

    return featureCodes.reduce((acc, code) => {
      acc[code] = featureMap.has(code);
      return acc;
    }, {} as Record<string, boolean>);
  }

  clearCache(companyId?: string) {
    if (companyId) {
      this.featuresCache.delete(companyId);
      this.cacheExpiry.delete(companyId);
    } else {
      this.featuresCache.clear();
      this.cacheExpiry.clear();
    }
  }
}

export const featuresService = new FeaturesService();
