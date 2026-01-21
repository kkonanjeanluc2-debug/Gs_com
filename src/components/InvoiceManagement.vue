<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Gestion des Factures</h2>
        <p class="text-sm text-gray-500 mt-1">Créez et gérez vos factures</p>
      </div>
      <div class="flex gap-2">
        <button
          @click="showGenerateDialog = true"
          class="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors"
        >
          Générer depuis commande/vente
        </button>
        <button
          @click="showForm = true"
          class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
          Nouvelle Facture
        </button>
      </div>
    </div>

    <div class="bg-white rounded-lg shadow p-4">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Date début</label>
          <input
            v-model="filters.startDate"
            type="date"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadInvoices"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Date fin</label>
          <input
            v-model="filters.endDate"
            type="date"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadInvoices"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Client</label>
          <select
            v-model="filters.clientId"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadInvoices"
          >
            <option value="">Tous les clients</option>
            <option v-for="client in clients" :key="client.id" :value="client.id">
              {{ client.name }}
            </option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Statut</label>
          <select
            v-model="filters.status"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadInvoices"
          >
            <option value="">Tous les statuts</option>
            <option value="en_attente">En attente</option>
            <option value="payee">Payée</option>
            <option value="annulee">Annulée</option>
          </select>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Total factures</p>
            <p class="text-2xl font-bold text-gray-900">{{ stats.total_invoices }}</p>
          </div>
          <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">📄</span>
          </div>
        </div>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Montant total</p>
            <p class="text-2xl font-bold text-green-600">{{ stats.total_amount.toLocaleString('fr-FR') }} F</p>
          </div>
          <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">💰</span>
          </div>
        </div>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Factures payées</p>
            <p class="text-2xl font-bold text-emerald-600">{{ stats.paid_invoices }}</p>
          </div>
          <div class="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">✅</span>
          </div>
        </div>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">En attente</p>
            <p class="text-2xl font-bold text-orange-600">{{ stats.pending_invoices }}</p>
          </div>
          <div class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">⏳</span>
          </div>
        </div>
      </div>
    </div>

    <div v-if="showGenerateDialog" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-2xl w-full">
        <h3 class="text-xl font-bold mb-4">Générer une facture</h3>

        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Type de source</label>
            <select
              v-model="generateForm.source_type"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              @change="loadSourceData"
            >
              <option value="">Sélectionner...</option>
              <option value="order">Commande</option>
              <option value="sale">Vente</option>
            </select>
          </div>

          <div v-if="generateForm.source_type === 'order'">
            <label class="block text-sm font-medium text-gray-700 mb-1">Commande</label>
            <select
              v-model="generateForm.source_id"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Sélectionner une commande</option>
              <option v-for="order in orders" :key="order.id" :value="order.id">
                {{ order.order_number }} - {{ order.client?.name }} - {{ order.total_amount }} F CFA
              </option>
            </select>
          </div>

          <div v-if="generateForm.source_type === 'sale'">
            <label class="block text-sm font-medium text-gray-700 mb-1">Vente</label>
            <select
              v-model="generateForm.source_id"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Sélectionner une vente</option>
              <option v-for="sale in sales" :key="sale.id" :value="sale.id">
                {{ sale.sale_number }} - {{ sale.client?.name }} - {{ sale.final_amount }} F CFA
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Taxe (%)</label>
            <input
              v-model.number="generateForm.tax_percentage"
              type="number"
              min="0"
              max="100"
              step="0.01"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Date d'échéance</label>
            <input
              v-model="generateForm.due_date"
              type="date"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div v-if="generateError" class="bg-red-50 text-red-600 px-4 py-2 rounded-lg">
            {{ generateError }}
          </div>

          <div class="flex gap-2 justify-end">
            <button
              type="button"
              @click="closeGenerateDialog"
              class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
            >
              Annuler
            </button>
            <button
              type="button"
              @click="handleGenerateInvoice"
              :disabled="!generateForm.source_type || !generateForm.source_id || !generateForm.due_date"
              class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Générer la facture
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="showForm" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <h3 class="text-xl font-bold mb-4">Nouvelle Facture</h3>

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

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Taxe (%)</label>
              <input
                v-model.number="formData.tax_percentage"
                type="number"
                min="0"
                max="100"
                step="0.01"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Date d'échéance *</label>
              <input
                v-model="formData.due_date"
                type="date"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div class="border-t pt-4">
            <div class="flex justify-between items-center mb-4">
              <h4 class="font-semibold text-base">Articles</h4>
              <button
                type="button"
                @click="addItem"
                class="px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium"
              >
                + Ajouter
              </button>
            </div>

            <div v-for="(item, index) in formData.items" :key="index" class="mb-4 p-3 border border-gray-200 rounded-lg bg-gray-50">
              <div class="space-y-3">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Description *</label>
                  <input
                    v-model="item.description"
                    type="text"
                    required
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    placeholder="Description de l'article"
                  />
                </div>

                <div class="grid grid-cols-3 gap-3">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Quantité</label>
                    <input
                      v-model.number="item.quantity"
                      type="number"
                      min="1"
                      required
                      class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Prix unitaire</label>
                    <input
                      v-model.number="item.unit_price"
                      type="number"
                      min="0"
                      step="0.01"
                      required
                      class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Remise (%)</label>
                    <input
                      v-model.number="item.discount_percentage"
                      type="number"
                      min="0"
                      max="100"
                      step="0.01"
                      class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>

                <button
                  v-if="formData.items.length > 1"
                  type="button"
                  @click="removeItem(index)"
                  class="w-full px-4 py-2 text-red-600 hover:bg-red-50 rounded-lg border border-red-200 font-medium"
                >
                  Retirer cet article
                </button>
              </div>
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
              Créer la facture
            </button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="invoices.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">Aucune facture</p>
    </div>

    <div v-else class="bg-white rounded-lg shadow overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">N° Facture</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Client</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Montant</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Échéance</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
            <th class="px-4 md:px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-for="invoice in invoices" :key="invoice.id">
            <td class="px-4 md:px-6 py-4 whitespace-nowrap font-medium text-sm">
              {{ invoice.invoice_number }}
              <div v-if="invoice.order_id" class="text-xs text-gray-500">Commande: {{ invoice.order?.order_number }}</div>
              <div v-if="invoice.sale_id" class="text-xs text-gray-500">Vente: {{ invoice.sale?.sale_number }}</div>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900">{{ invoice.client?.name }}</div>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap font-semibold text-sm">
              {{ invoice.final_amount }} F CFA
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <select
                :value="invoice.status"
                @change="updateStatus(invoice.id!, ($event.target as HTMLSelectElement).value as any)"
                class="text-xs px-2 py-1 rounded-full border-0 focus:ring-2 focus:ring-blue-500"
                :class="getStatusClass(invoice.status)"
              >
                <option value="en_attente">En attente</option>
                <option value="payee">Payée</option>
                <option value="annulee">Annulée</option>
              </select>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap text-sm text-gray-500">
              {{ new Date(invoice.due_date).toLocaleDateString('fr-FR') }}
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap text-xs md:text-sm text-gray-500">
              {{ new Date(invoice.created_at!).toLocaleDateString('fr-FR') }}
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <div class="flex items-center justify-end gap-2">
                <button
                  @click="viewInvoice(invoice)"
                  class="text-green-600 hover:text-green-900 p-1"
                  title="Voir"
                >
                  👁️
                </button>
                <button
                  @click="printInvoice(invoice)"
                  class="text-blue-600 hover:text-blue-900 p-1"
                  title="Imprimer/PDF"
                >
                  🖨️
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="selectedInvoice" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-start mb-4">
          <h3 class="text-xl font-bold">Facture {{ selectedInvoice.invoice_number }}</h3>
          <button @click="selectedInvoice = null" class="text-gray-500 hover:text-gray-700 text-2xl">×</button>
        </div>

        <div id="invoice-preview">
          <div class="grid grid-cols-2 gap-6 mb-6">
            <div>
              <h4 class="font-semibold mb-2">Client</h4>
              <p class="text-sm">{{ selectedInvoice.client?.name }}</p>
              <p v-if="selectedInvoice.client?.email" class="text-sm text-gray-600">{{ selectedInvoice.client.email }}</p>
              <p v-if="selectedInvoice.client?.phone" class="text-sm text-gray-600">{{ selectedInvoice.client.phone }}</p>
            </div>
            <div>
              <h4 class="font-semibold mb-2">Informations</h4>
              <p class="text-sm">Date: {{ new Date(selectedInvoice.created_at!).toLocaleDateString('fr-FR') }}</p>
              <p class="text-sm">Échéance: {{ new Date(selectedInvoice.due_date).toLocaleDateString('fr-FR') }}</p>
              <p class="text-sm">Statut: <span :class="getStatusClass(selectedInvoice.status)">{{ getStatusLabel(selectedInvoice.status) }}</span></p>
            </div>
          </div>

          <div class="mb-6">
            <h4 class="font-semibold mb-2">Articles</h4>
            <table class="min-w-full">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-4 py-2 text-left text-sm">Description</th>
                  <th class="px-4 py-2 text-center text-sm">Quantité</th>
                  <th class="px-4 py-2 text-right text-sm">Prix unitaire</th>
                  <th class="px-4 py-2 text-right text-sm">Remise</th>
                  <th class="px-4 py-2 text-right text-sm">Sous-total</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in selectedInvoice.invoice_items" :key="item.id" class="border-t">
                  <td class="px-4 py-2">{{ item.description }}</td>
                  <td class="px-4 py-2 text-center">{{ item.quantity }}</td>
                  <td class="px-4 py-2 text-right">{{ item.unit_price }} F CFA</td>
                  <td class="px-4 py-2 text-right">{{ item.discount_percentage }}%</td>
                  <td class="px-4 py-2 text-right font-semibold">{{ item.subtotal }} F CFA</td>
                </tr>
              </tbody>
              <tfoot class="border-t-2">
                <tr>
                  <td colspan="4" class="px-4 py-2 text-right">Total:</td>
                  <td class="px-4 py-2 text-right font-semibold">{{ selectedInvoice.total_amount }} F CFA</td>
                </tr>
                <tr v-if="selectedInvoice.tax_amount > 0">
                  <td colspan="4" class="px-4 py-2 text-right">Taxe:</td>
                  <td class="px-4 py-2 text-right">{{ selectedInvoice.tax_amount }} F CFA</td>
                </tr>
                <tr class="font-bold text-lg">
                  <td colspan="4" class="px-4 py-2 text-right">MONTANT FINAL:</td>
                  <td class="px-4 py-2 text-right text-green-600">{{ selectedInvoice.final_amount }} F CFA</td>
                </tr>
              </tfoot>
            </table>
          </div>

          <div v-if="selectedInvoice.notes" class="mb-6">
            <h4 class="font-semibold mb-2">Notes</h4>
            <p class="text-sm text-gray-600">{{ selectedInvoice.notes }}</p>
          </div>
        </div>

        <div class="flex gap-2 justify-end">
          <button
            @click="selectedInvoice = null"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Fermer
          </button>
          <button
            @click="printInvoice(selectedInvoice)"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Imprimer/PDF
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { invoicesService, type Invoice, type CreateInvoiceData } from '../services/invoices.service';
import { ordersService, type Order } from '../services/orders.service';
import { salesService, type Sale } from '../services/sales.service';
import { clientsService, type Client } from '../services/clients.service';
import { companyService, type CompanySettings } from '../services/company.service';

interface InvoiceItemForm {
  product_id?: string;
  description: string;
  quantity: number;
  unit_price: number;
  discount_percentage: number;
}

interface InvoiceFormData {
  client_id: string;
  items: InvoiceItemForm[];
  tax_percentage: number;
  due_date: string;
  notes?: string;
}

const invoices = ref<Invoice[]>([]);
const clients = ref<Client[]>([]);
const orders = ref<Order[]>([]);
const sales = ref<Sale[]>([]);
const companySettings = ref<CompanySettings | null>(null);
const showForm = ref(false);
const showGenerateDialog = ref(false);
const error = ref('');
const generateError = ref('');
const selectedInvoice = ref<Invoice | null>(null);

const stats = ref({
  total_invoices: 0,
  total_amount: 0,
  paid_invoices: 0,
  pending_invoices: 0,
  cancelled_invoices: 0,
});

const filters = ref({
  startDate: '',
  endDate: '',
  clientId: '',
  status: '',
});

const formData = ref<InvoiceFormData>({
  client_id: '',
  items: [{ description: '', quantity: 1, unit_price: 0, discount_percentage: 0 }],
  tax_percentage: 0,
  due_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
  notes: '',
});

const generateForm = ref({
  source_type: '',
  source_id: '',
  tax_percentage: 0,
  due_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
});

const loadInvoices = async () => {
  try {
    const filterParams: any = {};
    if (filters.value.startDate) filterParams.startDate = filters.value.startDate;
    if (filters.value.endDate) filterParams.endDate = filters.value.endDate;
    if (filters.value.clientId) filterParams.clientId = filters.value.clientId;
    if (filters.value.status) filterParams.status = filters.value.status;

    invoices.value = await invoicesService.getInvoices(filterParams);
    await loadStats();
  } catch (err) {
    console.error('Error loading invoices:', err);
  }
};

const loadStats = async () => {
  try {
    const statsData = await invoicesService.getInvoiceStats(filters.value.startDate, filters.value.endDate);
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

const loadSourceData = async () => {
  generateForm.value.source_id = '';
  generateError.value = '';

  if (generateForm.value.source_type === 'order') {
    try {
      orders.value = await ordersService.getOrders();
    } catch (err) {
      console.error('Error loading orders:', err);
    }
  } else if (generateForm.value.source_type === 'sale') {
    try {
      sales.value = await salesService.getSales();
    } catch (err) {
      console.error('Error loading sales:', err);
    }
  }
};

const loadCompanySettings = async () => {
  try {
    companySettings.value = await companyService.getSettings();
  } catch (err) {
    console.error('Error loading company settings:', err);
  }
};

const addItem = () => {
  formData.value.items.push({ description: '', quantity: 1, unit_price: 0, discount_percentage: 0 });
};

const removeItem = (index: number) => {
  formData.value.items.splice(index, 1);
};

const handleSubmit = async () => {
  error.value = '';

  if (formData.value.items.length === 0) {
    error.value = 'Ajoutez au moins un article';
    return;
  }

  try {
    const invoiceData: CreateInvoiceData = {
      client_id: formData.value.client_id,
      items: formData.value.items.map(item => ({
        description: item.description,
        quantity: item.quantity,
        unit_price: item.unit_price,
        discount_percentage: item.discount_percentage,
      })),
      tax_percentage: formData.value.tax_percentage,
      due_date: formData.value.due_date,
      notes: formData.value.notes,
    };

    await invoicesService.createInvoice(invoiceData);
    await loadInvoices();
    closeForm();
    alert('Facture créée avec succès');
  } catch (err: any) {
    console.error('Error creating invoice:', err);
    error.value = err.message || 'Erreur lors de la création de la facture';
  }
};

const handleGenerateInvoice = async () => {
  generateError.value = '';

  try {
    if (generateForm.value.source_type === 'order') {
      await invoicesService.createInvoiceFromOrder(
        generateForm.value.source_id,
        generateForm.value.tax_percentage,
        generateForm.value.due_date
      );
    } else if (generateForm.value.source_type === 'sale') {
      await invoicesService.createInvoiceFromSale(
        generateForm.value.source_id,
        generateForm.value.tax_percentage,
        generateForm.value.due_date
      );
    }

    await loadInvoices();
    closeGenerateDialog();
    alert('Facture générée avec succès');
  } catch (err: any) {
    console.error('Error generating invoice:', err);
    generateError.value = err.message || 'Erreur lors de la génération de la facture';
  }
};

const closeForm = () => {
  showForm.value = false;
  formData.value = {
    client_id: '',
    items: [{ description: '', quantity: 1, unit_price: 0, discount_percentage: 0 }],
    tax_percentage: 0,
    due_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    notes: '',
  };
  error.value = '';
};

const closeGenerateDialog = () => {
  showGenerateDialog.value = false;
  generateForm.value = {
    source_type: '',
    source_id: '',
    tax_percentage: 0,
    due_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
  };
  generateError.value = '';
};

const updateStatus = async (invoiceId: string, status: Invoice['status']) => {
  try {
    const payment_date = status === 'payee' ? new Date().toISOString().split('T')[0] : undefined;
    await invoicesService.updateInvoiceStatus(invoiceId, status, payment_date);
    await loadInvoices();
  } catch (err) {
    console.error('Error updating status:', err);
    alert('Erreur lors de la mise à jour du statut');
  }
};

const viewInvoice = (invoice: Invoice) => {
  selectedInvoice.value = invoice;
};

const printInvoice = (invoice: Invoice) => {
  const printWindow = window.open('', '_blank');
  if (!printWindow) return;

  const company = companySettings.value;

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Facture ${invoice.invoice_number}</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          max-width: 800px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
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
        h1 { color: #1e40af; margin: 0; font-size: 28px; }
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
        .status { display: inline-block; padding: 5px 10px; border-radius: 5px; font-size: 12px; font-weight: bold; }
        .status-payee { background-color: #d1fae5; color: #065f46; }
        .status-en_attente { background-color: #fee2e2; color: #991b1b; }
        .status-annulee { background-color: #f3f4f6; color: #374151; }
        @media print {
          body { padding: 0; }
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div>
          <h1>FACTURE</h1>
          <p style="margin: 5px 0; font-size: 16px; font-weight: bold;">${invoice.invoice_number}</p>
          <p style="margin: 5px 0;">Date: ${new Date(invoice.created_at!).toLocaleDateString('fr-FR')}</p>
          <p style="margin: 5px 0;">Échéance: ${new Date(invoice.due_date).toLocaleDateString('fr-FR')}</p>
          <span class="status status-${invoice.status}">${getStatusLabel(invoice.status)}</span>
        </div>
        ${company ? `
          <div class="company-info">
            ${company.logo_url ? `<img src="${company.logo_url}" alt="Logo" class="company-logo" />` : ''}
            <div style="font-weight: bold; font-size: 16px; color: #1e40af; margin-bottom: 5px;">${company.name}</div>
            ${company.address ? `<p style="margin: 3px 0; font-size: 12px;">${company.address.replace(/\n/g, '<br>')}</p>` : ''}
          </div>
        ` : ''}
      </div>

      <div class="info-section">
        <div class="info-block">
          <h3>FACTURÉ À</h3>
          <p><strong>${invoice.client?.name}</strong></p>
          ${invoice.client?.email ? `<p>${invoice.client.email}</p>` : ''}
          ${invoice.client?.phone ? `<p>${invoice.client.phone}</p>` : ''}
          ${invoice.client?.address ? `<p>${invoice.client.address}</p>` : ''}
        </div>
        <div class="info-block">
          <h3>COMMERCIAL</h3>
          <p><strong>${invoice.commercial?.full_name}</strong></p>
          <p>${invoice.commercial?.email}</p>
          ${invoice.commercial?.phone ? `<p>${invoice.commercial.phone}</p>` : ''}
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th>Description</th>
            <th class="text-center">Quantité</th>
            <th class="text-right">Prix unitaire</th>
            <th class="text-right">Remise</th>
            <th class="text-right">Sous-total</th>
          </tr>
        </thead>
        <tbody>
          ${invoice.invoice_items?.map(item => `
            <tr>
              <td>${item.description}</td>
              <td class="text-center">${item.quantity}</td>
              <td class="text-right">${item.unit_price} F CFA</td>
              <td class="text-right">${item.discount_percentage}%</td>
              <td class="text-right">${item.subtotal} F CFA</td>
            </tr>
          `).join('')}
        </tbody>
        <tfoot>
          <tr>
            <td colspan="4" class="text-right">Total:</td>
            <td class="text-right"><strong>${invoice.total_amount} F CFA</strong></td>
          </tr>
          ${invoice.tax_amount > 0 ? `
            <tr>
              <td colspan="4" class="text-right">Taxe:</td>
              <td class="text-right">${invoice.tax_amount} F CFA</td>
            </tr>
          ` : ''}
          <tr class="total-row">
            <td colspan="4" class="text-right">MONTANT FINAL:</td>
            <td class="text-right">${invoice.final_amount} F CFA</td>
          </tr>
        </tfoot>
      </table>

      ${invoice.notes ? `
        <div class="notes">
          <h3 style="margin-top: 0; font-size: 14px;">Notes</h3>
          <p style="margin: 0;">${invoice.notes}</p>
        </div>
      ` : ''}

      <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #e5e7eb; text-align: center; font-size: 11px; color: #6b7280;">
        ${company ? `
          <div style="display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; margin-bottom: 10px;">
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
};

const getStatusClass = (status: string) => {
  const classes = {
    en_attente: 'bg-yellow-100 text-yellow-800',
    payee: 'bg-green-100 text-green-800',
    annulee: 'bg-gray-100 text-gray-800',
  };
  return classes[status as keyof typeof classes] || '';
};

const getStatusLabel = (status: string) => {
  const labels = {
    en_attente: 'En attente',
    payee: 'Payée',
    annulee: 'Annulée',
  };
  return labels[status as keyof typeof labels] || status;
};

onMounted(() => {
  loadInvoices();
  loadClients();
  loadCompanySettings();
});
</script>
