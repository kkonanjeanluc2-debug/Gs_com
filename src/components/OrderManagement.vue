<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h2 class="text-2xl font-bold text-gray-900">Gestion des Commandes</h2>
      <button
        @click="showForm = true"
        class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
      >
        Nouvelle Commande
      </button>
    </div>

    <div v-if="showForm" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <h3 class="text-xl font-bold mb-4">Nouvelle Commande</h3>

        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Client *</label>
            <select
              v-model="formData.client_id"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Sélectionner un client</option>
              <option v-for="client in clients" :key="client.id" :value="client.id">
                {{ client.name }}
              </option>
            </select>
          </div>

          <div class="border-t pt-4">
            <div class="flex justify-between items-center mb-3">
              <h4 class="font-semibold">Produits</h4>
              <button
                type="button"
                @click="addProduct"
                class="text-blue-600 hover:text-blue-700 text-sm font-medium"
              >
                + Ajouter un produit
              </button>
            </div>

            <div v-for="(item, index) in formData.items" :key="index" class="flex gap-2 mb-2">
              <select
                v-model="item.product_id"
                @change="updatePrice(index)"
                required
                class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Sélectionner un produit</option>
                <option v-for="product in products" :key="product.id" :value="product.id">
                  {{ product.name }} - {{ product.price }} F CFA
                </option>
              </select>

              <input
                v-model.number="item.quantity"
                type="number"
                min="1"
                required
                placeholder="Qté"
                class="w-24 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />

              <input
                v-model.number="item.unit_price"
                type="number"
                step="0.01"
                min="0"
                required
                placeholder="Prix"
                class="w-32 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />

              <button
                type="button"
                @click="removeProduct(index)"
                class="px-3 py-2 text-red-600 hover:bg-red-50 rounded-lg"
              >
                ✕
              </button>
            </div>

            <div class="mt-4 text-right">
              <span class="text-lg font-semibold">Total: {{ calculateTotal() }} F CFA</span>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Notes</label>
            <textarea
              v-model="formData.notes"
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Notes supplémentaires..."
            ></textarea>
          </div>

          <div v-if="error" class="bg-red-50 text-red-600 px-4 py-2 rounded-lg">
            {{ error }}
          </div>

          <div class="flex gap-2 justify-end">
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
            <td class="px-4 md:px-6 py-4 whitespace-nowrap font-semibold text-sm">{{ order.total_amount }} F CFA</td>
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
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { ordersService, type Order, type CreateOrderData } from '../services/orders.service';
import { clientsService, type Client } from '../services/clients.service';
import { productsService, type Product } from '../services/products.service';
import { companyService, type CompanySettings } from '../services/company.service';

const orders = ref<Order[]>([]);
const clients = ref<Client[]>([]);
const products = ref<Product[]>([]);
const companySettings = ref<CompanySettings | null>(null);
const showForm = ref(false);
const error = ref('');
const selectedOrder = ref<Order | null>(null);

const formData = ref<CreateOrderData>({
  client_id: '',
  items: [{ product_id: '', quantity: 1, unit_price: 0 }],
  notes: '',
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
    clients.value = await clientsService.getAllClients();
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

const addProduct = () => {
  formData.value.items.push({ product_id: '', quantity: 1, unit_price: 0 });
};

const removeProduct = (index: number) => {
  formData.value.items.splice(index, 1);
};

const updatePrice = (index: number) => {
  const item = formData.value.items[index];
  const product = products.value.find((p: Product) => p.id === item.product_id);
  if (product) {
    item.unit_price = product.price;
  }
};

const calculateTotal = () => {
  return formData.value.items
    .reduce((sum, item) => sum + (item.quantity * item.unit_price), 0)
    .toFixed(2);
};

const handleSubmit = async () => {
  error.value = '';

  if (formData.value.items.length === 0) {
    error.value = 'Ajoutez au moins un produit';
    return;
  }

  try {
    await ordersService.createOrder(formData.value);
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
    client_id: '',
    items: [{ product_id: '', quantity: 1, unit_price: 0 }],
    notes: '',
  };
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
      <title>Commande ${order.order_number}</title>
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
          <h1>Commande ${order.order_number}</h1>
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
  setTimeout(() => {
    printWindow.print();
  }, 250);
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

onMounted(() => {
  loadOrders();
  loadClients();
  loadProducts();
  loadCompanySettings();
});
</script>
