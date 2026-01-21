<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h2 class="text-2xl font-bold text-gray-900">Gestion des Commandes</h2>
      <button
        @click="openNewOrderForm"
        class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
      >
        Nouvelle Commande
      </button>
    </div>

    <div v-if="showForm" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-gray-100 rounded-lg w-full max-w-7xl h-[90vh] flex flex-col">
        <div class="bg-white px-6 py-4 rounded-t-lg border-b border-gray-200">
          <div class="flex justify-between items-center">
            <h3 class="text-xl font-bold text-gray-800">Nouvelle Commande</h3>
            <button @click="closeForm" class="text-gray-500 hover:text-gray-700 text-2xl">×</button>
          </div>
        </div>

        <div class="flex-1 overflow-hidden flex">
          <div class="w-2/5 bg-white p-6 overflow-y-auto border-r border-gray-200">
            <form @submit.prevent="handleSubmit" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Client</label>
                <select
                  v-model="formData.client_id"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Sélectionner un client</option>
                  <option v-for="client in clients" :key="client.id" :value="client.id">
                    {{ client.name }} {{ client.phone ? '/ ' + client.phone : '' }}
                  </option>
                </select>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Dépôt de stockage</label>
                <select
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                >
                  <option>DEPOT PRINCIPAL</option>
                </select>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Commentaire</label>
                <textarea
                  v-model="formData.notes"
                  rows="2"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  placeholder="Commentaire..."
                ></textarea>
              </div>

              <div class="border-t pt-4">
                <table class="w-full text-sm">
                  <thead>
                    <tr class="border-b">
                      <th class="text-left py-2 px-1">Nom d'article</th>
                      <th class="text-center py-2 px-1 w-16">Qté</th>
                      <th class="text-right py-2 px-1 w-20">PU TTC</th>
                      <th class="text-right py-2 px-1 w-20">Total</th>
                      <th class="w-8"></th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(item, index) in formData.items" :key="index" class="border-b">
                      <td class="py-2 px-1">
                        <div v-if="item.product_id" class="text-xs font-medium truncate">
                          {{ products.find(p => p.id === item.product_id)?.name }}
                        </div>
                        <div v-else class="text-xs text-gray-400">-</div>
                      </td>
                      <td class="py-2 px-1 text-center">
                        <input
                          v-model.number="item.quantity"
                          type="number"
                          min="1"
                          class="w-full px-1 py-1 text-center border border-gray-300 rounded text-xs"
                        />
                      </td>
                      <td class="py-2 px-1 text-right">
                        <input
                          v-model.number="item.unit_price"
                          type="number"
                          step="0.01"
                          :min="item.original_price || 0"
                          class="w-full px-1 py-1 text-right border border-gray-300 rounded text-xs"
                        />
                      </td>
                      <td class="py-2 px-1 text-right">
                        <span class="text-xs font-semibold">{{ calculateItemSubtotal(item).toLocaleString('fr-FR') }}</span>
                      </td>
                      <td class="py-2 px-1 text-center">
                        <button
                          v-if="formData.items.length > 1"
                          type="button"
                          @click="removeProduct(index)"
                          class="text-red-600 hover:text-red-800 text-xs"
                        >
                          ✕
                        </button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div class="space-y-2 border-t pt-4">
                <div class="bg-blue-600 text-white px-4 py-3 rounded flex justify-between items-center">
                  <span class="font-semibold">MONTANT TOTAL</span>
                  <span class="text-xl font-bold">{{ calculateTotal().toLocaleString('fr-FR') }}</span>
                </div>
              </div>

              <div v-if="error" class="bg-red-50 text-red-600 px-4 py-2 rounded-lg text-sm">
                {{ error }}
              </div>

              <div class="flex gap-2 justify-end pt-4">
                <button
                  type="button"
                  @click="closeForm"
                  class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Créer la commande
                </button>
              </div>
            </form>
          </div>

          <div class="w-3/5 bg-white p-6 overflow-y-auto">
            <div class="mb-4">
              <h4 class="text-lg font-bold text-gray-800 mb-3">Produits</h4>
              <input
                v-model="productSearchText"
                type="text"
                placeholder="Code barre ou désignation"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div class="grid grid-cols-3 gap-4">
              <div
                v-for="product in filteredProducts"
                :key="product.id"
                @click="addProductToOrder(product)"
                class="border border-gray-200 rounded-lg p-3 cursor-pointer hover:border-blue-500 hover:shadow-md transition-all"
                :class="{
                  'opacity-50 cursor-not-allowed': product.stock_quantity <= 0
                }"
              >
                <div class="aspect-square bg-gray-100 rounded-lg mb-2 flex items-center justify-center overflow-hidden">
                  <img
                    v-if="product.image_url"
                    :src="product.image_url"
                    :alt="product.name"
                    class="w-full h-full object-cover"
                  />
                  <span v-else class="text-4xl text-gray-400">📦</span>
                </div>
                <div class="text-center">
                  <p class="text-red-600 font-bold text-lg mb-1">
                    {{ product.price.toLocaleString('fr-FR') }}.0
                  </p>
                  <p class="text-xs text-gray-700 font-medium mb-2 truncate" :title="product.name">
                    {{ product.name }}
                  </p>
                  <div
                    v-if="product.stock_quantity > 0"
                    class="text-xs px-2 py-1 rounded"
                    :class="{
                      'bg-green-100 text-green-800': product.stock_quantity >= 10,
                      'bg-yellow-100 text-yellow-800': product.stock_quantity < 10 && product.stock_quantity > 0
                    }"
                  >
                    Disponible {{ product.stock_quantity.toFixed(2) }}
                  </div>
                  <div v-else class="text-xs px-2 py-1 rounded bg-red-100 text-red-800">
                    Rupture de stock
                  </div>
                </div>
              </div>
            </div>

            <div v-if="filteredProducts.length === 0" class="text-center py-12 text-gray-500">
              Aucun produit trouvé
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="orders.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">Aucune commande</p>
    </div>

    <div v-else class="bg-white rounded-lg shadow overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase whitespace-nowrap">N° Commande</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase whitespace-nowrap">Client</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase whitespace-nowrap">Commercial</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase whitespace-nowrap">Montant</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase whitespace-nowrap">Paiement</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase whitespace-nowrap">Statut</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase whitespace-nowrap">Date</th>
            <th class="px-4 md:px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase whitespace-nowrap">Actions</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-for="order in orders" :key="order.id">
            <td class="px-4 md:px-6 py-4 whitespace-nowrap font-medium text-sm">{{ order.order_number }}</td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900">{{ order.client?.name }}</div>
              <div v-if="order.client?.type" class="text-xs text-gray-500">{{ order.client.type === 'client' ? 'Client' : 'Prospect' }}</div>
            </td>
            <td class="px-4 md:px-6 py-4 text-sm whitespace-nowrap">{{ order.commercial?.full_name }}</td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap font-semibold text-sm">
              <div>{{ order.total_amount }} F CFA</div>
              <div v-if="order.total_paid && order.total_paid > 0" class="text-xs text-green-600">
                Payé: {{ order.total_paid }} F CFA
              </div>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <div class="flex flex-col gap-1">
                <span
                  v-if="order.payment_status"
                  :class="['text-xs px-2 py-1 rounded-full border inline-block text-center', getPaymentStatusColor(order.payment_status)]"
                >
                  {{ getPaymentStatusLabel(order.payment_status) }}
                </span>
                <button
                  v-if="order.payment_status !== 'totalement_paye'"
                  @click="openPaymentModal(order)"
                  class="px-2 py-1 bg-green-500 text-white rounded hover:bg-green-600 text-xs font-medium"
                >
                  💰 Paiement
                </button>
              </div>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <select
                :value="order.status"
                @change="updateStatus(order.id!, ($event.target as HTMLSelectElement).value as any)"
                class="text-xs md:text-sm px-2 py-1 rounded-full border-0 focus:ring-2 focus:ring-blue-500 w-full min-w-[120px]"
                :class="getStatusClass(order.status)"
              >
                <option value="pending">En attente</option>
                <option value="confirmed">Confirmée</option>
                <option value="delivered">Livrée</option>
                <option value="cancelled">Annulée</option>
              </select>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap text-xs md:text-sm text-gray-500">
              {{ new Date(order.created_at!).toLocaleDateString('fr-FR') }}
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <div class="flex items-center justify-end gap-2">
                <button
                  @click="printOrder(order)"
                  class="text-blue-600 hover:text-blue-900 p-1"
                  title="Imprimer"
                >
                  🖨️
                </button>
                <button
                  @click="viewOrderDetails(order)"
                  class="text-green-600 hover:text-green-900 p-1"
                  title="Détails"
                >
                  👁️
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="selectedOrder" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-start mb-4">
          <h3 class="text-xl font-bold">Détails de la commande {{ selectedOrder.order_number }}</h3>
          <button @click="selectedOrder = null" class="text-gray-500 hover:text-gray-700 text-2xl">×</button>
        </div>

        <div class="grid grid-cols-2 gap-6 mb-6">
          <div>
            <h4 class="font-semibold mb-2">Client</h4>
            <p class="text-sm">{{ selectedOrder.client?.name }}</p>
            <p v-if="selectedOrder.client?.type" class="text-sm text-gray-600">{{ selectedOrder.client.type === 'client' ? 'Client' : 'Prospect' }}</p>
            <p v-if="selectedOrder.client?.email" class="text-sm text-gray-600">{{ selectedOrder.client.email }}</p>
            <div v-if="selectedOrder.client?.phone" class="flex items-center gap-2 mt-1">
              <p class="text-sm text-gray-600">{{ selectedOrder.client.phone }}</p>
              <button
                @click="openWhatsApp(selectedOrder.client.phone)"
                class="px-2 py-1 bg-green-500 text-white rounded hover:bg-green-600 text-xs font-medium"
                title="Contacter sur WhatsApp"
              >
                WhatsApp
              </button>
            </div>
            <p v-if="selectedOrder.client?.address" class="text-sm text-gray-600">{{ selectedOrder.client.address }}</p>
          </div>
          <div>
            <h4 class="font-semibold mb-2">Commercial</h4>
            <p class="text-sm">{{ selectedOrder.commercial?.full_name }}</p>
            <p class="text-sm text-gray-600">{{ selectedOrder.commercial?.email }}</p>
            <p v-if="selectedOrder.commercial?.phone" class="text-sm text-gray-600">{{ selectedOrder.commercial.phone }}</p>
          </div>
        </div>

        <div class="mb-6">
          <h4 class="font-semibold mb-2">Articles</h4>
          <table class="min-w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-2 text-left text-sm">Produit</th>
                <th class="px-4 py-2 text-center text-sm">Quantité</th>
                <th class="px-4 py-2 text-right text-sm">Prix unitaire</th>
                <th class="px-4 py-2 text-right text-sm">Sous-total</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in selectedOrder.order_items" :key="item.id" class="border-t">
                <td class="px-4 py-2">{{ item.product?.name }}</td>
                <td class="px-4 py-2 text-center">{{ item.quantity }}</td>
                <td class="px-4 py-2 text-right">{{ item.unit_price }} F CFA</td>
                <td class="px-4 py-2 text-right font-semibold">{{ item.subtotal }} F CFA</td>
              </tr>
            </tbody>
            <tfoot class="border-t-2">
              <tr>
                <td colspan="3" class="px-4 py-2 text-right font-semibold">Total:</td>
                <td class="px-4 py-2 text-right font-bold text-lg">{{ selectedOrder.total_amount }} F CFA</td>
              </tr>
            </tfoot>
          </table>
        </div>

        <div v-if="selectedOrder.notes" class="mb-6">
          <h4 class="font-semibold mb-2">Notes</h4>
          <p class="text-sm text-gray-600">{{ selectedOrder.notes }}</p>
        </div>

        <div class="flex gap-2 justify-end">
          <button
            @click="selectedOrder = null"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Fermer
          </button>
          <button
            @click="printOrder(selectedOrder)"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Imprimer
          </button>
        </div>
      </div>
    </div>

    <AddPaymentModal
      v-if="showPaymentModal && selectedOrderForPayment"
      :order="selectedOrderForPayment"
      @close="closePaymentModal"
      @success="handlePaymentSuccess"
    />

    <PaymentReceipt
      v-if="showReceipt && selectedPaymentId"
      :payment-id="selectedPaymentId"
      @close="closeReceipt"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { ordersService, type Order, type CreateOrderData } from '../services/orders.service';
import { clientsService, type Client } from '../services/clients.service';
import { productsService, type Product } from '../services/products.service';
import { companyService, type CompanySettings } from '../services/company.service';
import { orderPaymentsService } from '../services/order-payments.service';
import AddPaymentModal from './AddPaymentModal.vue';
import PaymentReceipt from './PaymentReceipt.vue';

interface OrderItemForm {
  product_id: string;
  quantity: number;
  unit_price: number;
  original_price: number;
}

interface OrderFormData {
  client_id: string;
  items: OrderItemForm[];
  notes?: string;
}

const orders = ref<Order[]>([]);
const clients = ref<Client[]>([]);
const products = ref<Product[]>([]);
const companySettings = ref<CompanySettings | null>(null);
const showForm = ref(false);
const error = ref('');
const selectedOrder = ref<Order | null>(null);
const productSearchText = ref('');
const showPaymentModal = ref(false);
const selectedOrderForPayment = ref<Order | null>(null);
const showReceipt = ref(false);
const selectedPaymentId = ref<string | null>(null);
const counterClient = ref<Client | null>(null);

const formData = ref<OrderFormData>({
  client_id: '',
  items: [],
  notes: '',
});

const filteredProducts = computed(() => {
  const search = productSearchText.value.toLowerCase();
  if (!search) return products.value;

  return products.value.filter(p =>
    p.name.toLowerCase().includes(search) ||
    p.sku?.toLowerCase().includes(search)
  );
});

const loadOrders = async () => {
  try {
    orders.value = await ordersService.getOrders();
  } catch (err) {
    console.error('Error loading orders:', err);
  }
};

const loadClients = async () => {
  try {
    const allClients = await clientsService.getAllClients();
    clients.value = allClients;
    counterClient.value = allClients.find(c => c.name === 'Client comptoir') || null;
  } catch (err) {
    console.error('Error loading clients:', err);
  }
};

const loadProducts = async () => {
  try {
    products.value = await productsService.getAllProducts();
  } catch (err) {
    console.error('Error loading products:', err);
  }
};

const loadCompanySettings = async () => {
  try {
    companySettings.value = await companyService.getSettings();
  } catch (err) {
    console.error('Error loading company settings:', err);
  }
};

const openNewOrderForm = () => {
  showForm.value = true;
  if (counterClient.value) {
    formData.value.client_id = counterClient.value.id!;
  }
};

const addProductToOrder = (product: Product) => {
  if (product.stock_quantity <= 0) {
    error.value = `${product.name} est en rupture de stock`;
    return;
  }

  const existingItemIndex = formData.value.items.findIndex(item => item.product_id === product.id);

  if (existingItemIndex >= 0) {
    const item = formData.value.items[existingItemIndex];
    if (item.quantity < product.stock_quantity) {
      item.quantity++;
    } else {
      error.value = `Stock insuffisant pour ${product.name}`;
      setTimeout(() => error.value = '', 3000);
    }
  } else {
    formData.value.items.push({
      product_id: product.id!,
      quantity: 1,
      unit_price: product.price,
      original_price: product.price,
    });
  }

  error.value = '';
};

const removeProduct = (index: number) => {
  formData.value.items.splice(index, 1);
};

const calculateItemSubtotal = (item: OrderItemForm) => {
  return item.quantity * item.unit_price;
};

const calculateTotal = () => {
  return formData.value.items.reduce((sum, item) => sum + (item.quantity * item.unit_price), 0);
};

const handleSubmit = async () => {
  error.value = '';

  if (formData.value.items.length === 0) {
    error.value = 'Ajoutez au moins un produit';
    return;
  }

  for (const item of formData.value.items) {
    const product = products.value.find(p => p.id === item.product_id);

    if (!product) {
      error.value = 'Produit introuvable';
      return;
    }

    if (product.stock_quantity <= 0) {
      error.value = `${product.name} est en rupture de stock`;
      return;
    }

    if (item.quantity > product.stock_quantity) {
      error.value = `Quantité demandée (${item.quantity}) supérieure au stock disponible pour ${product.name} (${product.stock_quantity})`;
      return;
    }

    if (item.original_price && item.unit_price < item.original_price) {
      error.value = `Le prix ne peut pas être inférieur au prix catalogue (${item.original_price} F CFA)`;
      return;
    }
  }

  try {
    const orderData: CreateOrderData = {
      client_id: formData.value.client_id,
      items: formData.value.items.map(item => ({
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
      })),
      notes: formData.value.notes,
    };

    await ordersService.createOrder(orderData);
    await loadOrders();
    closeForm();
    alert('Commande créée avec succès');
  } catch (err: any) {
    console.error('Error creating order:', err);
    error.value = err.message || 'Erreur lors de la création de la commande';
  }
};

const closeForm = () => {
  showForm.value = false;
  formData.value = {
    client_id: counterClient.value?.id || '',
    items: [],
    notes: '',
  };
  productSearchText.value = '';
  error.value = '';
};

const updateStatus = async (orderId: string, status: Order['status']) => {
  try {
    await ordersService.updateOrderStatus(orderId, status);
    await loadOrders();
  } catch (err) {
    console.error('Error updating status:', err);
    alert('Erreur lors de la mise à jour du statut');
  }
};

const viewOrderDetails = (order: Order) => {
  selectedOrder.value = order;
};

const printOrder = (order: Order) => {
  const printWindow = window.open('', '_blank');
  if (!printWindow) return;

  const company = companySettings.value;

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>${order.status === 'delivered' ? 'Bon de livraison' : 'Commande'} ${order.order_number}</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          max-width: 800px;
          margin: 0 auto;
          padding: 20px;
        }
        .top-section {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 30px;
          padding-bottom: 20px;
          border-bottom: 2px solid #1e40af;
        }
        .company-info {
          text-align: right;
          max-width: 300px;
        }
        .company-logo {
          max-width: 150px;
          max-height: 80px;
          margin-bottom: 10px;
        }
        .company-info p {
          margin: 3px 0;
          font-size: 12px;
          color: #374151;
        }
        .company-name {
          font-weight: bold;
          font-size: 16px;
          color: #1e40af;
          margin-bottom: 5px;
        }
        h1 { color: #1e40af; margin: 0; font-size: 28px; }
        .order-meta { margin-top: 5px; font-size: 13px; color: #6b7280; }
        .info-section { display: flex; justify-content: space-between; margin-bottom: 30px; }
        .info-block { flex: 1; }
        .info-block h3 { margin-top: 0; color: #374151; font-size: 14px; }
        .info-block p { margin: 5px 0; font-size: 13px; color: #6b7280; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th { background-color: #f3f4f6; padding: 10px; text-align: left; font-size: 12px; }
        td { padding: 10px; border-bottom: 1px solid #e5e7eb; font-size: 13px; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .total-row { font-weight: bold; font-size: 16px; background-color: #f9fafb; }
        .notes { margin-top: 20px; padding: 15px; background-color: #f9fafb; border-radius: 5px; }
        .notes h3 { margin-top: 0; font-size: 14px; }
        .footer {
          margin-top: 40px;
          padding-top: 20px;
          border-top: 1px solid #e5e7eb;
          text-align: center;
          font-size: 11px;
          color: #6b7280;
        }
        .footer-info {
          display: flex;
          justify-content: center;
          gap: 20px;
          flex-wrap: wrap;
          margin-bottom: 10px;
        }
        .footer-info span {
          white-space: nowrap;
        }
        @media print {
          body { padding: 0; }
        }
      </style>
    </head>
    <body>
      <div class="top-section">
        <div>
          <h1>${order.status === 'delivered' ? 'Facture de' : 'Commande'} ${order.order_number}</h1>
          <div class="order-meta">
            <p>Date: ${new Date(order.created_at!).toLocaleDateString('fr-FR')}</p>
            <p>Statut: ${getStatusLabel(order.status)}</p>
          </div>
        </div>
        ${company ? `
          <div class="company-info">
            ${company.logo_url ? `<img src="${company.logo_url}" alt="Logo" class="company-logo" />` : ''}
            <div class="company-name">${company.name}</div>
            ${company.address ? `<p>${company.address.replace(/\n/g, '<br>')}</p>` : ''}
          </div>
        ` : ''}
      </div>

      <div class="info-section">
        <div class="info-block">
          <h3>CLIENT</h3>
          <p><strong>${order.client?.name}</strong></p>
          ${order.client?.type ? `<p>${order.client.type === 'client' ? 'Client' : 'Prospect'}</p>` : ''}
          ${order.client?.email ? `<p>${order.client.email}</p>` : ''}
          ${order.client?.phone ? `<p>${order.client.phone}</p>` : ''}
          ${order.client?.address ? `<p>${order.client.address}</p>` : ''}
        </div>
        <div class="info-block">
          <h3>COMMERCIAL</h3>
          <p><strong>${order.commercial?.full_name}</strong></p>
          <p>${order.commercial?.email}</p>
          ${order.commercial?.phone ? `<p>${order.commercial.phone}</p>` : ''}
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th>Produit</th>
            <th class="text-center">Quantité</th>
            <th class="text-right">Prix unitaire</th>
            <th class="text-right">Sous-total</th>
          </tr>
        </thead>
        <tbody>
          ${order.order_items?.map(item => `
            <tr>
              <td>${item.product?.name}</td>
              <td class="text-center">${item.quantity}</td>
              <td class="text-right">${item.unit_price} F CFA</td>
              <td class="text-right">${item.subtotal} F CFA</td>
            </tr>
          `).join('')}
        </tbody>
        <tfoot>
          <tr class="total-row">
            <td colspan="3" class="text-right">TOTAL</td>
            <td class="text-right">${order.total_amount} F CFA</td>
          </tr>
        </tfoot>
      </table>

      ${order.notes ? `
        <div class="notes">
          <h3>Notes</h3>
          <p>${order.notes}</p>
        </div>
      ` : ''}

      <div class="footer">
        ${company ? `
          <div class="footer-info">
            ${company.phone ? `<span>Tél: ${company.phone}</span>` : ''}
            ${company.website ? `<span>Web: ${company.website}</span>` : ''}
            ${company.rccm ? `<span>RCCM: ${company.rccm}</span>` : ''}
            ${company.ncc ? `<span>NCC: ${company.ncc}</span>` : ''}
          </div>
        ` : ''}
        <p>Document généré le ${new Date().toLocaleDateString('fr-FR')} à ${new Date().toLocaleTimeString('fr-FR')}</p>
      </div>
    </body>
    </html>
  `;

  printWindow.document.write(html);
  printWindow.document.close();

  printWindow.onload = () => {
    setTimeout(() => {
      printWindow.print();
    }, 500);
  };

  setTimeout(() => {
    if (printWindow.document.readyState === 'complete') {
      printWindow.print();
    }
  }, 1000);
};

const getStatusClass = (status: string) => {
  const classes = {
    pending: 'bg-yellow-100 text-yellow-800',
    confirmed: 'bg-blue-100 text-blue-800',
    delivered: 'bg-green-100 text-green-800',
    cancelled: 'bg-red-100 text-red-800',
  };
  return classes[status as keyof typeof classes] || '';
};

const getStatusLabel = (status: string) => {
  const labels = {
    pending: 'En attente',
    confirmed: 'Confirmée',
    delivered: 'Livrée',
    cancelled: 'Annulée',
  };
  return labels[status as keyof typeof labels] || status;
};

const openWhatsApp = (phone: string) => {
  if (!phone) {
    alert('Aucun numéro de téléphone disponible');
    return;
  }

  const cleanPhone = phone.replace(/\s+/g, '');
  const url = `https://wa.me/${cleanPhone}`;
  window.open(url, '_blank');
};

const openPaymentModal = (order: Order) => {
  selectedOrderForPayment.value = order;
  showPaymentModal.value = true;
};

const closePaymentModal = () => {
  showPaymentModal.value = false;
  selectedOrderForPayment.value = null;
};

const handlePaymentSuccess = async (payment: any) => {
  closePaymentModal();
  await loadOrders();
  selectedPaymentId.value = payment.id;
  showReceipt.value = true;
};

const closeReceipt = () => {
  showReceipt.value = false;
  selectedPaymentId.value = null;
};

const getPaymentStatusColor = (status: string) => {
  switch (status) {
    case 'totalement_paye':
      return 'bg-green-100 text-green-800 border-green-200';
    case 'partiellement_paye':
      return 'bg-yellow-100 text-yellow-800 border-yellow-200';
    case 'non_paye':
      return 'bg-red-100 text-red-800 border-red-200';
    default:
      return 'bg-gray-100 text-gray-800 border-gray-200';
  }
};

const getPaymentStatusLabel = (status: string) => {
  return orderPaymentsService.getPaymentStatusLabel(status);
};

onMounted(() => {
  loadOrders();
  loadClients();
  loadProducts();
  loadCompanySettings();
});
</script>
