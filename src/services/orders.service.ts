import { supabase, getCurrentUserCompanyId } from './supabase';

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
  };
  commercial?: {
    full_name: string;
    email: string;
    phone?: string;
  };
  order_items?: OrderItem[];
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
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as Order[];
  },

  async getOrderById(id: string) {
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
      .maybeSingle();

    if (error) throw error;
    return data as Order | null;
  },

  async createOrder(orderData: CreateOrderData) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const company_id = await getCurrentUserCompanyId();

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
    const { error } = await supabase
      .from('orders')
      .update({ status })
      .eq('id', orderId);

    if (error) throw error;
  },

  async deleteOrder(orderId: string) {
    const { error } = await supabase
      .from('orders')
      .delete()
      .eq('id', orderId);

    if (error) throw error;
  },
};
