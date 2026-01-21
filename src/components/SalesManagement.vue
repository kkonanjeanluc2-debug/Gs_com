<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Gestion des Ventes</h2>
        <p class="text-sm text-gray-500 mt-1">Enregistrez et consultez l'historique des ventes</p>
      </div>
      <button
        @click="showForm = true"
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
      <div class="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <h3 class="text-xl font-bold mb-4">Nouvelle Vente</h3>

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
            <div class="flex justify-between items-center mb-4">
              <h4 class="font-semibold text-base">Produits</h4>
              <button
                type="button"
                @click="addProduct"
                class="px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium"
              >
                + Ajouter
              </button>
            </div>

            <div v-for="(item, index) in formData.items" :key="index" class="mb-6 p-3 border border-gray-200 rounded-lg bg-gray-50">
              <div class="space-y-3">
                <div class="relative">
                  <label class="block text-sm font-medium text-gray-700 mb-1">Produit</label>
                  <input
                    v-model="productSearch[index]"
                    type="text"
                    placeholder="Rechercher un produit..."
                    class="w-full px-4 py-3 text-base border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    @focus="item.showDropdown = true"
                    @blur="hideDropdown(index)"
                  />
                  <div
                    v-if="item.showDropdown && getFilteredProducts(index).length > 0"
                    class="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-y-auto"
                  >
                    <button
                      v-for="product in getFilteredProducts(index)"
                      :key="product.id"
                      type="button"
                      @click="product.stock_quantity > 0 && selectProduct(index, product)"
                      :disabled="product.stock_quantity <= 0"
                      :class="[
                        'w-full text-left px-3 py-2 border-b border-gray-100 last:border-b-0',
                        product.stock_quantity <= 0
                          ? 'bg-gray-100 text-gray-400 cursor-not-allowed opacity-60'
                          : 'hover:bg-blue-50'
                      ]"
                    >
                      <div class="font-medium">
                        {{ product.name }}
                        <span v-if="product.stock_quantity <= 0" class="ml-2 text-xs text-red-600 font-bold">(RUPTURE DE STOCK)</span>
                      </div>
                      <div class="text-sm" :class="product.stock_quantity <= 0 ? 'text-red-500' : 'text-gray-600'">
                        {{ product.price }} F CFA - Stock: {{ product.stock_quantity }}
                      </div>
                    </button>
                  </div>
                  <div v-if="item.product_id" class="mt-2 px-3 py-2 bg-blue-50 text-blue-700 text-sm rounded border border-blue-200">
                    ✓ {{ products.find(p => p.id === item.product_id)?.name }}
                  </div>
                </div>

                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Quantité</label>
                    <input
                      v-model.number="item.quantity"
                      type="number"
                      min="1"
                      :max="item.product_id ? products.find(p => p.id === item.product_id)?.stock_quantity : undefined"
                      required
                      class="w-full px-4 py-3 text-base border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                      @input="updateItemTotal(index)"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Prix unitaire</label>
                    <input
                      v-model.number="item.unit_price"
                      type="number"
                      step="0.01"
                      min="0"
                      required
                      class="w-full px-4 py-3 text-base border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                      @input="updateItemTotal(index)"
                    />
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Remise (%)</label>
                  <input
                    v-model.number="item.discount_percentage"
                    type="number"
                    min="0"
                    max="100"
                    step="0.01"
                    class="w-full px-4 py-3 text-base border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    @input="updateItemTotal(index)"
                  />
                </div>

                <div class="text-right">
                  <span class="text-sm text-gray-600">Sous-total: </span>
                  <span class="font-semibold text-lg">{{ calculateItemSubtotal(item) }} F CFA</span>
                </div>

                <button
                  v-if="formData.items.length > 1"
                  type="button"
                  @click="removeProduct(index)"
                  class="w-full px-4 py-2 text-red-600 hover:bg-red-50 rounded-lg border border-red-200 font-medium"
                >
                  Retirer ce produit
                </button>
              </div>
            </div>

            <div class="mt-4 text-right space-y-1">
              <div><span class="text-gray-600">Total: </span><span class="font-semibold">{{ calculateTotal() }} F CFA</span></div>
              <div><span class="text-gray-600">Remise: </span><span class="font-semibold text-red-600">-{{ calculateTotalDiscount() }} F CFA</span></div>
              <div class="text-xl"><span class="text-gray-900 font-bold">Montant final: </span><span class="font-bold text-green-600">{{ calculateFinalAmount() }} F CFA</span></div>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Mode de paiement *</label>
            <select
              v-model="formData.payment_method"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Sélectionner un mode</option>
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

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Statut de paiement</label>
            <select
              v-model="formData.payment_status"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="paye">Payé</option>
              <option value="en_attente">En attente</option>
              <option value="partiellement_paye">Partiellement payé</option>
            </select>
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
              Enregistrer la vente
            </button>
          </div>
        </form>
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
import { ref, onMounted } from 'vue';
import { salesService, type Sale, type CreateSaleData } from '../services/sales.service';
import { clientsService, type Client } from '../services/clients.service';
import { productsService, type Product } from '../services/products.service';

interface SaleItemForm {
  product_id: string;
  quantity: number;
  unit_price: number;
  discount_percentage: number;
  showDropdown?: boolean;
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
const productSearch = ref<string[]>([]);

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
  items: [{ product_id: '', quantity: 1, unit_price: 0, discount_percentage: 0, showDropdown: false }],
  payment_method: '',
  payment_status: 'paye',
  notes: '',
});

const getFilteredProducts = (index: number) => {
  const search = productSearch.value[index]?.toLowerCase() || '';
  if (!search) return products.value;

  return products.value.filter(p =>
    p.name.toLowerCase().includes(search) ||
    p.sku?.toLowerCase().includes(search)
  );
};

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

const addProduct = () => {
  formData.value.items.unshift({ product_id: '', quantity: 1, unit_price: 0, discount_percentage: 0, showDropdown: false });
  productSearch.value.unshift('');
};

const removeProduct = (index: number) => {
  formData.value.items.splice(index, 1);
  productSearch.value.splice(index, 1);
};

const selectProduct = (index: number, product: Product) => {
  const item = formData.value.items[index];
  item.product_id = product.id!;
  item.unit_price = product.price;
  item.showDropdown = false;
  productSearch.value[index] = product.name;
};

const hideDropdown = (index: number) => {
  setTimeout(() => {
    formData.value.items[index].showDropdown = false;
  }, 200);
};

const updateItemTotal = (_index: number) => {
};

const calculateItemSubtotal = (item: SaleItemForm) => {
  const total = item.quantity * item.unit_price;
  const discount = (total * item.discount_percentage) / 100;
  return (total - discount).toFixed(2);
};

const calculateTotal = () => {
  return formData.value.items
    .reduce((sum, item) => sum + (item.quantity * item.unit_price), 0)
    .toFixed(2);
};

const calculateTotalDiscount = () => {
  return formData.value.items
    .reduce((sum, item) => {
      const total = item.quantity * item.unit_price;
      const discount = (total * item.discount_percentage) / 100;
      return sum + discount;
    }, 0)
    .toFixed(2);
};

const calculateFinalAmount = () => {
  return formData.value.items
    .reduce((sum, item) => {
      const total = item.quantity * item.unit_price;
      const discount = (total * item.discount_percentage) / 100;
      return sum + (total - discount);
    }, 0)
    .toFixed(2);
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
    client_id: '',
    items: [{ product_id: '', quantity: 1, unit_price: 0, discount_percentage: 0, showDropdown: false }],
    payment_method: '',
    payment_status: 'paye',
    notes: '',
  };
  productSearch.value = [''];
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
  productSearch.value = [''];
});
</script>
