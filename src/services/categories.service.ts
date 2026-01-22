import { supabase, getCurrentUserCompanyId } from './supabase';
import { handleDatabaseError } from './error-handler.service';

export interface Category {
  id: string;
  name: string;
  description: string | null;
  created_at: string;
  updated_at: string;
}

export interface Subcategory {
  id: string;
  category_id: string;
  name: string;
  description: string | null;
  created_at: string;
  updated_at: string;
}

export class CategoriesService {
  async createCategory(category: { name: string; description?: string }) {
    try {
      const company_id = await getCurrentUserCompanyId();
      const { data, error } = await supabase
        .from('categories')
        .insert({ ...category, company_id })
        .select()
        .single();

      if (error) throw error;
      return data as Category;
    } catch (error) {
      handleDatabaseError(error);
    }
  }

  async updateCategory(id: string, updates: { name?: string; description?: string }) {
    try {
      const { data, error } = await supabase
        .from('categories')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data as Category;
    } catch (error) {
      handleDatabaseError(error);
    }
  }

  async deleteCategory(id: string) {
    const { error } = await supabase
      .from('categories')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  async getCategory(id: string) {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('id', id)
      .eq('company_id', companyId)
      .maybeSingle();

    if (error) throw error;
    return data as Category | null;
  }

  async getAllCategories() {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('company_id', companyId)
      .order('name', { ascending: true });

    if (error) throw error;
    return (data || []) as Category[];
  }

  async createSubcategory(subcategory: { category_id: string; name: string; description?: string }) {
    try {
      const company_id = await getCurrentUserCompanyId();
      const { data, error } = await supabase
        .from('subcategories')
        .insert({ ...subcategory, company_id })
        .select()
        .single();

      if (error) throw error;
      return data as Subcategory;
    } catch (error) {
      handleDatabaseError(error);
    }
  }

  async updateSubcategory(id: string, updates: { name?: string; description?: string; category_id?: string }) {
    try {
      const { data, error } = await supabase
        .from('subcategories')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data as Subcategory;
    } catch (error) {
      handleDatabaseError(error);
    }
  }

  async deleteSubcategory(id: string) {
    const { error } = await supabase
      .from('subcategories')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  async getSubcategory(id: string) {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('subcategories')
      .select('*')
      .eq('id', id)
      .eq('company_id', companyId)
      .maybeSingle();

    if (error) throw error;
    return data as Subcategory | null;
  }

  async getSubcategoriesByCategory(categoryId: string) {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('subcategories')
      .select('*')
      .eq('category_id', categoryId)
      .eq('company_id', companyId)
      .order('name', { ascending: true });

    if (error) throw error;
    return (data || []) as Subcategory[];
  }

  async getAllSubcategories() {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('subcategories')
      .select('*')
      .eq('company_id', companyId)
      .order('name', { ascending: true });

    if (error) throw error;
    return (data || []) as Subcategory[];
  }
}

export const categoriesService = new CategoriesService();
