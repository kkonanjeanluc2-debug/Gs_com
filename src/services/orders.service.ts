import { supabase, getCurrentUserCompanyId } from './supabase';
import { offlineUpdate, offlineDelete, offlineQuery } from './offline-wrapper.service';

export interface OrderItem {
  id?: string;
  order_id?: string;
  product_id: string;
  quantity: number;
  unit_price: number;
  subtotal: number;
  product?: {
    name: string;
    sku: string;
  };
}

export interface Order {
  id?: string;
  order_number?: string;
  client_id: string;
  commercial_id: string;
  total_amount: number;
  total_paid?: number;
  payment_status?: 'non_paye' | 'partiellement_paye' | 'totalement_paye';
  status: 'pending' | 'confirmed' | 'delivered' | 'cancelled';
  notes?: string;
  created_at?: string;
  updated_at?: string;
  client?: {
    name: string;
    email?: string;
    phone?: string;
    address?: string;
    type?: string;
    entity_type?: string;
    company_name?: string;
  };
  commercial?: {
    full_name: string;
    email: string;
    phone?: string;
  };
  order_items?: OrderItem[];
  order_payments?: OrderPayment[];
}

export interface OrderPayment {
  id?: string;
  order_id: string;
  client_id: string;
  company_id: string;
  amount: number;
  payment_method: 'especes' | 'mobile_money' | 'virement' | 'cheque' | 'carte_bancaire' | 'wave' | 'orange_money' | 'mtn_money' | 'moov_money' | 'dexchange';
  payment_reference?: string;
  payment_date: string;
  notes?: string;
  created_by: string;
  receipt_number?: string;
  created_at?: string;
  updated_at?: string;
}

export interface CreateOrderData {
  client_id: string;
  items: {
    product_id: string;
    quantity: number;
    unit_price: number;
  }[];
  notes?: string;
}

export const ordersService = {
  async getOrders() {
    const companyId = await getCurrentUserCompanyId();

    return await offlineQuery<Order>(
      'orders',
      async () => {
        const { data, error } = await supabase
          .from('orders')
          .select(`
            *,
            client:clients(name, email, phone, address, type),
            commercial:profiles(full_name, email, phone),
            order_items(
              *,
              product:products(name, sku)
            )
          `)
          .eq('company_id', companyId)
          .order('created_at', { ascending: false });

        return { data, error };
      }
    );
  },

  async getOrderById(id: string) {
    const companyId = await getCurrentUserCompanyId();

    const orders = await offlineQuery<Order>(
      'orders',
      async () => {
        const { data, error } = await supabase
          .from('orders')
          .select(`
            *,
            client:clients(name, email, phone, address, type),
            commercial:profiles(full_name, email, phone),
            order_items(
              *,
              product:products(name, sku)
            )
          `)
          .eq('id', id)
          .eq('company_id', companyId);

        return { data, error };
      }
    );

    return orders.length > 0 ? orders[0] : null;
  },

  async createOrder(orderData: CreateOrderData) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const company_id = await getCurrentUserCompanyId();

    const productIds = orderData.items.map(item => item.product_id);
    const { data: products, error: productsError } = await supabase
      .from('products')
      .select('id, name, sku, stock_quantity')
      .in('id', productIds)
      .eq('company_id', company_id);

    if (productsError) throw productsError;

    const stockErrors: string[] = [];
    for (const item of orderData.items) {
      const product = products?.find(p => p.id === item.product_id);
      if (!product) {
        stockErrors.push(`Produit introuvable`);
        continue;
      }

      if (product.stock_quantity <= 0) {
        stockErrors.push(`${product.name} (${product.sku}): stock épuisé`);
      } else if (product.stock_quantity < item.quantity) {
        stockErrors.push(`${product.name} (${product.sku}): stock insuffisant (disponible: ${product.stock_quantity})`);
      }
    }

    if (stockErrors.length > 0) {
      throw new Error(`Impossible de créer la commande:\n${stockErrors.join('\n')}`);
    }

    const total_amount = orderData.items.reduce(
      (sum, item) => sum + item.quantity * item.unit_price,
      0
    );

    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        client_id: orderData.client_id,
        commercial_id: user.id,
        total_amount,
        status: 'pending',
        notes: orderData.notes,
        company_id,
      })
      .select()
      .single();

    if (orderError) throw orderError;

    const orderItems = orderData.items.map(item => ({
      order_id: order.id,
      product_id: item.product_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      subtotal: item.quantity * item.unit_price,
      company_id,
    }));

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(orderItems);

    if (itemsError) throw itemsError;

    return await this.getOrderById(order.id);
  },

  async updateOrderStatus(orderId: string, status: Order['status']) {
    await offlineUpdate<any>(
      'orders',
      orderId,
      { status },
      async () => {
        const { error } = await supabase
          .from('orders')
          .update({ status })
          .eq('id', orderId);
        return { data: null, error };
      }
    );
  },

  async deleteOrder(orderId: string) {
    await offlineDelete(
      'orders',
      orderId,
      async () => {
        const { error } = await supabase
          .from('orders')
          .delete()
          .eq('id', orderId);
        return { error };
      }
    );
  },
};
