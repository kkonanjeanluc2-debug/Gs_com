import { supabase, type Product, getCurrentUserCompanyId } from './supabase';
import { offlineCreate, offlineUpdate, offlineDelete, offlineQuery } from './offline-wrapper.service';

export type { Product };

export class ProductsService {
  async createProduct(product: Omit<Product, 'id' | 'created_at' | 'updated_at'>) {
    const company_id = await getCurrentUserCompanyId();
    const productData = { ...product, company_id };

    return await offlineCreate<Product>(
      'products',
      productData as any,
      async () => {
        const { data, error } = await supabase
          .from('products')
          .insert(productData)
          .select()
          .single();
        return { data, error };
      }
    );
  }

  async updateProduct(id: string, updates: Partial<Product>) {
    const updateData = { ...updates, updated_at: new Date().toISOString() };

    await offlineUpdate<Product>(
      'products',
      id,
      updateData,
      async () => {
        const { data, error } = await supabase
          .from('products')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
        return { data, error };
      }
    );

    return this.getProduct(id);
  }

  async deleteProduct(id: string) {
    await offlineDelete(
      'products',
      id,
      async () => {
        const { error } = await supabase
          .from('products')
          .delete()
          .eq('id', id);
        return { error };
      }
    );
  }

  async getProduct(id: string) {
    const companyId = await getCurrentUserCompanyId();

    const products = await offlineQuery<Product>(
      'products',
      async () => {
        const { data, error } = await supabase
          .from('products')
          .select('*')
          .eq('id', id)
          .eq('company_id', companyId);
        return { data, error };
      }
    );

    return products.length > 0 ? products[0] : null;
  }

  async getProductBySku(sku: string) {
    const companyId = await getCurrentUserCompanyId();

    const products = await offlineQuery<Product>(
      'products',
      async () => {
        const { data, error } = await supabase
          .from('products')
          .select('*')
          .eq('sku', sku)
          .eq('company_id', companyId);
        return { data, error };
      }
    );

    return products.length > 0 ? products[0] : null;
  }

  async getAllProducts() {
    const companyId = await getCurrentUserCompanyId();

    return await offlineQuery<Product>(
      'products',
      async () => {
        const { data, error } = await supabase
          .from('products')
          .select('*')
          .eq('company_id', companyId)
          .order('name', { ascending: true });
        return { data, error };
      }
    );
  }

  async getLowStockProducts() {
    const companyId = await getCurrentUserCompanyId();

    return await offlineQuery<Product>(
      'products',
      async () => {
        const { data, error } = await supabase
          .from('products')
          .select('*')
          .eq('company_id', companyId)
          .filter('stock_quantity', 'lte', 'min_stock')
          .order('stock_quantity', { ascending: true });
        return { data, error };
      }
    );
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
