<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Gestion des Ventes</h2>
        <p class="text-sm text-gray-500 mt-1">Enregistrez et consultez l'historique des ventes</p>
      </div>
      <button
        @click="openNewSaleForm"
        class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
      >
        Nouvelle Vente
      </button>
    </div>

    <div class="bg-white rounded-lg shadow p-4">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Date début</label>
          <input
            v-model="filters.startDate"
            type="date"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadSales"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Date fin</label>
          <input
            v-model="filters.endDate"
            type="date"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadSales"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Client</label>
          <select
            v-model="filters.clientId"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadSales"
          >
            <option value="">Tous les clients</option>
            <option v-for="client in clients" :key="client.id" :value="client.id">
              {{ client.name }}
            </option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Produit</label>
          <select
            v-model="filters.productId"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadSales"
          >
            <option value="">Tous les produits</option>
            <option v-for="product in products" :key="product.id" :value="product.id">
              {{ product.name }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Total des ventes</p>
            <p class="text-2xl font-bold text-gray-900">{{ stats.total_sales }}</p>
          </div>
          <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">📊</span>
          </div>
        </div>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Chiffre d'affaires</p>
            <p class="text-2xl font-bold text-green-600">{{ stats.total_revenue.toLocaleString('fr-FR') }} F</p>
          </div>
          <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">💰</span>
          </div>
        </div>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Ventes payées</p>
            <p class="text-2xl font-bold text-gray-900">{{ stats.paid_sales }}</p>
          </div>
          <div class="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">✅</span>
          </div>
        </div>
      </div>
    </div>

    <div v-if="showForm" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-gray-100 rounded-lg w-full max-w-7xl h-[90vh] flex flex-col">
        <div class="bg-white px-6 py-4 rounded-t-lg border-b border-gray-200">
          <div class="flex justify-between items-center">
            <h3 class="text-xl font-bold text-gray-800">Nouvelle Vente</h3>
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
                      <th class="text-center py-2 px-1 w-16">T remise</th>
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
                      <td class="py-2 px-1 text-center">
                        <input
                          v-model.number="item.discount_percentage"
                          type="number"
                          min="0"
                          max="100"
                          class="w-full px-1 py-1 text-center border border-gray-300 rounded text-xs"
                        />
                      </td>
                      <td class="py-2 px-1 text-right">
                        <span class="text-xs">{{ item.unit_price.toLocaleString('fr-FR') }}</span>
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
                <div class="bg-green-600 text-white px-4 py-3 rounded flex justify-between items-center">
                  <span class="font-semibold">MONTANT DE LA FACTURE</span>
                  <span class="text-xl font-bold">{{ calculateFinalAmount().toLocaleString('fr-FR') }}</span>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Mode de paiement</label>
                  <select
                    v-model="formData.payment_method"
                    required
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Sélectionner</option>
                    <option value="especes">Espèces</option>
                    <option value="mobile_money">Mobile Money</option>
                    <option value="virement">Virement</option>
                    <option value="cheque">Chèque</option>
                    <option value="carte_bancaire">Carte bancaire</option>
                    <option value="wave">Wave</option>
                    <option value="orange_money">Orange Money</option>
                    <option value="mtn_money">MTN Money</option>
                    <option value="moov_money">Moov Money</option>
                  </select>
                </div>

                <div v-if="formData.payment_method === 'especes'" class="space-y-2">
                  <div class="bg-gray-200 px-4 py-2 rounded flex justify-between items-center">
                    <span class="text-sm font-medium">ESPECE CLIENT</span>
                    <input
                      v-model.number="cashReceived"
                      type="number"
                      min="0"
                      step="0.01"
                      class="w-32 px-2 py-1 border border-gray-300 rounded text-right"
                    />
                  </div>

                  <div class="bg-amber-600 text-white px-4 py-2 rounded flex justify-between items-center">
                    <span class="text-sm font-medium">MONNAIE CLIENT</span>
                    <span class="text-lg font-bold">{{ calculateChange().toLocaleString('fr-FR') }}</span>
                  </div>
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
                  Enregistrer la vente
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
                @click="addProductToSale(product)"
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

    <div v-if="sales.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">Aucune vente enregistrée</p>
    </div>

    <div v-else class="bg-white rounded-lg shadow overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">N° Vente</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Client</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Commercial</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Montant</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Paiement</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
            <th class="px-4 md:px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-for="sale in sales" :key="sale.id">
            <td class="px-4 md:px-6 py-4 whitespace-nowrap font-medium text-sm">{{ sale.sale_number }}</td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900">{{ sale.client?.name }}</div>
            </td>
            <td class="px-4 md:px-6 py-4 text-sm whitespace-nowrap">{{ sale.commercial?.full_name }}</td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <div class="text-sm">{{ sale.total_amount }} F CFA</div>
              <div v-if="sale.discount_amount > 0" class="text-xs text-red-600">-{{ sale.discount_amount }} F</div>
              <div class="text-sm font-semibold text-green-600">{{ sale.final_amount }} F CFA</div>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <span
                :class="['text-xs px-2 py-1 rounded-full', getPaymentStatusColor(sale.payment_status)]"
              >
                {{ getPaymentStatusLabel(sale.payment_status) }}
              </span>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap text-xs md:text-sm text-gray-500">
              {{ new Date(sale.created_at!).toLocaleDateString('fr-FR') }}
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <div class="flex items-center justify-end gap-2">
                <button
                  @click="viewSaleDetails(sale)"
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

    <div v-if="selectedSale" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-start mb-4">
          <h3 class="text-xl font-bold">Détails de la vente {{ selectedSale.sale_number }}</h3>
          <button @click="selectedSale = null" class="text-gray-500 hover:text-gray-700 text-2xl">×</button>
        </div>

        <div class="grid grid-cols-2 gap-6 mb-6">
          <div>
            <h4 class="font-semibold mb-2">Client</h4>
            <p class="text-sm">{{ selectedSale.client?.name }}</p>
            <p v-if="selectedSale.client?.email" class="text-sm text-gray-600">{{ selectedSale.client.email }}</p>
            <p v-if="selectedSale.client?.phone" class="text-sm text-gray-600">{{ selectedSale.client.phone }}</p>
          </div>
          <div>
            <h4 class="font-semibold mb-2">Commercial</h4>
            <p class="text-sm">{{ selectedSale.commercial?.full_name }}</p>
            <p class="text-sm text-gray-600">{{ selectedSale.commercial?.email }}</p>
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
                <th class="px-4 py-2 text-right text-sm">Remise</th>
                <th class="px-4 py-2 text-right text-sm">Sous-total</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in selectedSale.sale_items" :key="item.id" class="border-t">
                <td class="px-4 py-2">{{ item.product?.name }}</td>
                <td class="px-4 py-2 text-center">{{ item.quantity }}</td>
                <td class="px-4 py-2 text-right">{{ item.unit_price }} F CFA</td>
                <td class="px-4 py-2 text-right">{{ item.discount_percentage }}%</td>
                <td class="px-4 py-2 text-right font-semibold">{{ item.subtotal }} F CFA</td>
              </tr>
            </tbody>
            <tfoot class="border-t-2">
              <tr>
                <td colspan="4" class="px-4 py-2 text-right font-semibold">Total:</td>
                <td class="px-4 py-2 text-right font-bold text-lg">{{ selectedSale.final_amount }} F CFA</td>
              </tr>
            </tfoot>
          </table>
        </div>

        <div class="flex gap-2 justify-end">
          <button
            @click="selectedSale = null"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { salesService, type Sale, type CreateSaleData } from '../services/sales.service';
import { clientsService, type Client } from '../services/clients.service';
import { productsService, type Product } from '../services/products.service';

interface SaleItemForm {
  product_id: string;
  quantity: number;
  unit_price: number;
  discount_percentage: number;
}

interface SaleFormData {
  client_id: string;
  items: SaleItemForm[];
  payment_method: 'especes' | 'mobile_money' | 'virement' | 'cheque' | 'carte_bancaire' | 'wave' | 'orange_money' | 'mtn_money' | 'moov_money' | '';
  payment_status: 'paye' | 'en_attente' | 'partiellement_paye';
  notes?: string;
}

const sales = ref<Sale[]>([]);
const clients = ref<Client[]>([]);
const products = ref<Product[]>([]);
const showForm = ref(false);
const error = ref('');
const selectedSale = ref<Sale | null>(null);
const productSearchText = ref('');
const cashReceived = ref(0);
const counterClient = ref<Client | null>(null);

const stats = ref({
  total_sales: 0,
  total_revenue: 0,
  paid_sales: 0,
  pending_sales: 0,
});

const filters = ref({
  startDate: '',
  endDate: '',
  clientId: '',
  productId: '',
});

const formData = ref<SaleFormData>({
  client_id: '',
  items: [],
  payment_method: 'especes',
  payment_status: 'paye',
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

const loadSales = async () => {
  try {
    const filterParams: any = {};
    if (filters.value.startDate) filterParams.startDate = filters.value.startDate;
    if (filters.value.endDate) filterParams.endDate = filters.value.endDate;
    if (filters.value.clientId) filterParams.clientId = filters.value.clientId;
    if (filters.value.productId) filterParams.productId = filters.value.productId;

    sales.value = await salesService.getSales(filterParams);
    await loadStats();
  } catch (err) {
    console.error('Error loading sales:', err);
  }
};

const loadStats = async () => {
  try {
    const statsData = await salesService.getSalesStats(filters.value.startDate, filters.value.endDate);
    stats.value = statsData;
  } catch (err) {
    console.error('Error loading stats:', err);
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

const openNewSaleForm = () => {
  showForm.value = true;
  if (counterClient.value) {
    formData.value.client_id = counterClient.value.id!;
  }
};

const addProductToSale = (product: Product) => {
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
      discount_percentage: 0,
    });
  }

  error.value = '';
};

const removeProduct = (index: number) => {
  formData.value.items.splice(index, 1);
};

const calculateItemSubtotal = (item: SaleItemForm) => {
  const total = item.quantity * item.unit_price;
  const discount = (total * item.discount_percentage) / 100;
  return total - discount;
};

const calculateFinalAmount = () => {
  return formData.value.items
    .reduce((sum, item) => {
      const total = item.quantity * item.unit_price;
      const discount = (total * item.discount_percentage) / 100;
      return sum + (total - discount);
    }, 0);
};

const calculateChange = () => {
  const total = calculateFinalAmount();
  return Math.max(0, cashReceived.value - total);
};

const handleSubmit = async () => {
  error.value = '';

  if (formData.value.items.length === 0) {
    error.value = 'Ajoutez au moins un produit';
    return;
  }

  if (!formData.value.payment_method) {
    error.value = 'Sélectionnez un mode de paiement';
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
  }

  try {
    const saleData: CreateSaleData = {
      client_id: formData.value.client_id,
      items: formData.value.items.map(item => ({
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
        discount_percentage: item.discount_percentage,
      })),
      payment_method: formData.value.payment_method as any,
      payment_status: formData.value.payment_status,
      notes: formData.value.notes,
    };

    await salesService.createSale(saleData);
    await loadSales();
    await loadProducts();
    closeForm();
    alert('Vente enregistrée avec succès');
  } catch (err: any) {
    console.error('Error creating sale:', err);
    error.value = err.message || 'Erreur lors de l\'enregistrement de la vente';
  }
};

const closeForm = () => {
  showForm.value = false;
  formData.value = {
    client_id: counterClient.value?.id || '',
    items: [],
    payment_method: 'especes',
    payment_status: 'paye',
    notes: '',
  };
  productSearchText.value = '';
  cashReceived.value = 0;
  error.value = '';
};

const viewSaleDetails = (sale: Sale) => {
  selectedSale.value = sale;
};

const getPaymentStatusColor = (status: string) => {
  switch (status) {
    case 'paye':
      return 'bg-green-100 text-green-800';
    case 'partiellement_paye':
      return 'bg-yellow-100 text-yellow-800';
    case 'en_attente':
      return 'bg-red-100 text-red-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
};

const getPaymentStatusLabel = (status: string) => {
  switch (status) {
    case 'paye':
      return 'Payé';
    case 'partiellement_paye':
      return 'Partiellement payé';
    case 'en_attente':
      return 'En attente';
    default:
      return status;
  }
};

onMounted(() => {
  loadSales();
  loadClients();
  loadProducts();
});
</script>
