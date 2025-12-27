import { supabase, type Product, getCurrentUserCompanyId } from './supabase';

export type { Product };

export class ProductsService {
  async createProduct(product: Omit<Product, 'id' | 'created_at' | 'updated_at'>) {
    const company_id = await getCurrentUserCompanyId();
    const { data, error } = await supabase
      .from('products')
      .insert({ ...product, company_id })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateProduct(id: string, updates: Partial<Product>) {
    const { data, error } = await supabase
      .from('products')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async deleteProduct(id: string) {
    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  async getProduct(id: string) {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .eq('company_id', companyId)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  async getAllProducts() {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('company_id', companyId)
      .order('name', { ascending: true });

    if (error) throw error;
    return data || [];
  }

  async getLowStockProducts() {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('company_id', companyId)
      .filter('stock_quantity', 'lte', 'min_stock')
      .order('stock_quantity', { ascending: true });

    if (error) throw error;
    return data || [];
  }

  async addStockMovement(
    productId: string,
    userId: string,
    type: 'entree' | 'sortie' | 'ajustement',
    quantity: number,
    reason?: string
  ) {
    const product = await this.getProduct(productId);
    if (!product) throw new Error('Product not found');

    let newQuantity = product.stock_quantity;
    if (type === 'entree') {
      newQuantity += quantity;
    } else if (type === 'sortie') {
      newQuantity -= quantity;
    } else {
      newQuantity = quantity;
    }

    const company_id = await getCurrentUserCompanyId();
    const { data: movement, error: movementError } = await supabase
      .from('stock_movements')
      .insert({
        product_id: productId,
        user_id: userId,
        type,
        quantity,
        reason,
        company_id,
      })
      .select()
      .single();

    if (movementError) throw movementError;

    await this.updateProduct(productId, { stock_quantity: newQuantity });

    return movement;
  }

  async getStockMovements(productId?: string) {
    const companyId = await getCurrentUserCompanyId();

    let query = supabase
      .from('stock_movements')
      .select('*')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false });

    if (productId) {
      query = query.eq('product_id', productId);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  }
}

export const productsService = new ProductsService();
