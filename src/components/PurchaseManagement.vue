<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { purchasesService, type Purchase, type CreatePurchaseData } from '../services/purchases.service';
import { suppliersService, type Supplier } from '../services/suppliers.service';
import { productsService, type Product } from '../services/products.service';
import { companiesService } from '../services/companies.service';
import Icon from './Icon.vue';

const purchases = ref<Purchase[]>([]);
const suppliers = ref<Supplier[]>([]);
const products = ref<Product[]>([]);
const loading = ref(false);
const showForm = ref(false);
const selectedPurchase = ref<Purchase | null>(null);
const filterStatus = ref<'all' | 'pending' | 'completed' | 'cancelled'>('all');

const formData = ref({
  supplier_id: '',
  purchase_date: new Date().toISOString().split('T')[0],
  notes: '',
  items: [] as { product_id: string; quantity: number; unit_price: number; showDropdown?: boolean }[],
});

const productSearch = ref<Record<number, string>>({});

const filteredPurchases = computed(() => {
  if (filterStatus.value === 'all') {
    return purchases.value;
  }
  return purchases.value.filter(p => p.status === filterStatus.value);
});

const totalAmount = computed(() => {
  return formData.value.items.reduce((sum, item) => {
    return sum + (item.quantity * item.unit_price);
  }, 0);
});

const getFilteredProducts = (index: number) => {
  const search = productSearch.value[index]?.toLowerCase() || '';
  if (!search) return products.value.slice(0, 10);

  return products.value.filter(p =>
    p.name.toLowerCase().includes(search) ||
    p.sku?.toLowerCase().includes(search)
  );
};

const selectProduct = (index: number, product: Product) => {
  formData.value.items[index].product_id = product.id;
  formData.value.items[index].unit_price = product.price;
  productSearch.value[index] = product.name;
  formData.value.items[index].showDropdown = false;
};

const hideDropdown = (index: number) => {
  setTimeout(() => {
    if (formData.value.items[index]) {
      formData.value.items[index].showDropdown = false;
    }
  }, 200);
};

const addProduct = () => {
  formData.value.items.push({
    product_id: '',
    quantity: 1,
    unit_price: 0,
    showDropdown: false,
  });
};

const removeProduct = (index: number) => {
  formData.value.items.splice(index, 1);
  delete productSearch.value[index];
};

const loadPurchases = async () => {
  try {
    loading.value = true;
    purchases.value = await purchasesService.getPurchases();
  } catch (error) {
    console.error('Error loading purchases:', error);
    alert('Erreur lors du chargement des achats');
  } finally {
    loading.value = false;
  }
};

const loadSuppliers = async () => {
  try {
    suppliers.value = await suppliersService.getSuppliers();
  } catch (error) {
    console.error('Error loading suppliers:', error);
  }
};

const loadProducts = async () => {
  try {
    products.value = await productsService.getAllProducts();
  } catch (error) {
    console.error('Error loading products:', error);
  }
};

const handleSubmit = async () => {
  try {
    if (!formData.value.supplier_id) {
      alert('Veuillez sélectionner un fournisseur');
      return;
    }

    if (formData.value.items.length === 0) {
      alert('Veuillez ajouter au moins un produit');
      return;
    }

    if (formData.value.items.some(item => !item.product_id || item.quantity <= 0 || item.unit_price < 0)) {
      alert('Veuillez remplir correctement tous les produits');
      return;
    }

    loading.value = true;

    const purchaseData: CreatePurchaseData = {
      supplier_id: formData.value.supplier_id,
      purchase_date: formData.value.purchase_date,
      notes: formData.value.notes,
      items: formData.value.items.map(item => ({
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
      })),
    };

    await purchasesService.createPurchase(purchaseData);
    await loadPurchases();
    closeForm();
  } catch (error) {
    console.error('Error creating purchase:', error);
    alert('Erreur lors de la création de l\'achat');
  } finally {
    loading.value = false;
  }
};

const completePurchase = async (purchase: Purchase) => {
  if (!confirm('Confirmer la réception de cet achat ? Le stock sera mis à jour automatiquement.')) {
    return;
  }

  try {
    loading.value = true;
    await purchasesService.completePurchase(purchase.id);
    await loadPurchases();
  } catch (error) {
    console.error('Error completing purchase:', error);
    alert('Erreur lors de la validation de l\'achat');
  } finally {
    loading.value = false;
  }
};

const cancelPurchase = async (purchase: Purchase) => {
  if (!confirm('Annuler cet achat ?')) {
    return;
  }

  try {
    loading.value = true;
    await purchasesService.cancelPurchase(purchase.id);
    await loadPurchases();
  } catch (error) {
    console.error('Error cancelling purchase:', error);
    alert('Erreur lors de l\'annulation de l\'achat');
  } finally {
    loading.value = false;
  }
};

const deletePurchase = async (purchase: Purchase) => {
  if (!confirm(`Supprimer définitivement l'achat ${purchase.purchase_number} ?`)) {
    return;
  }

  try {
    loading.value = true;
    await purchasesService.deletePurchase(purchase.id);
    await loadPurchases();
  } catch (error) {
    console.error('Error deleting purchase:', error);
    alert('Erreur lors de la suppression de l\'achat');
  } finally {
    loading.value = false;
  }
};

const viewPurchase = async (purchase: Purchase) => {
  try {
    loading.value = true;
    selectedPurchase.value = await purchasesService.getPurchase(purchase.id);
  } catch (error) {
    console.error('Error loading purchase details:', error);
    alert('Erreur lors du chargement des détails');
  } finally {
    loading.value = false;
  }
};

const printPurchase = async (purchase: Purchase) => {
  try {
    const fullPurchase = await purchasesService.getPurchase(purchase.id);
    const company = await companiesService.getCurrentCompany();

    const printWindow = window.open('', '_blank');
    if (!printWindow) return;

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Bon d'achat ${fullPurchase.purchase_number}</title>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { font-family: Arial, sans-serif; padding: 40px; line-height: 1.6; }
          .header { display: flex; justify-content: space-between; align-items: start; margin-bottom: 40px; border-bottom: 3px solid #2563eb; padding-bottom: 20px; }
          .company-info h1 { color: #2563eb; font-size: 28px; margin-bottom: 10px; }
          .company-info p { color: #64748b; font-size: 14px; }
          .document-info { text-align: right; }
          .document-info h2 { color: #1e293b; font-size: 24px; margin-bottom: 10px; }
          .document-info p { color: #475569; font-size: 14px; }
          .parties { display: flex; justify-content: space-between; margin-bottom: 40px; }
          .party { flex: 1; padding: 20px; background: #f8fafc; border-radius: 8px; }
          .party h3 { color: #1e293b; font-size: 16px; margin-bottom: 10px; border-bottom: 2px solid #e2e8f0; padding-bottom: 8px; }
          .party p { color: #475569; font-size: 14px; margin: 5px 0; }
          .status-badge { display: inline-block; padding: 6px 16px; border-radius: 20px; font-weight: 600; font-size: 14px; }
          .status-pending { background: #fef9c3; color: #854d0e; }
          .status-completed { background: #dcfce7; color: #166534; }
          .status-cancelled { background: #fee2e2; color: #991b1b; }
          table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
          thead { background: #2563eb; color: white; }
          th { padding: 12px; text-align: left; font-weight: 600; }
          td { padding: 12px; border-bottom: 1px solid #e2e8f0; }
          tbody tr:hover { background: #f8fafc; }
          .text-right { text-align: right; }
          .totals { margin-top: 20px; }
          .totals table { width: auto; margin-left: auto; }
          .totals td { border: none; padding: 8px 20px; }
          .totals .total-row { font-size: 18px; font-weight: bold; color: #2563eb; background: #eff6ff; }
          .notes { margin-top: 30px; padding: 20px; background: #f8fafc; border-left: 4px solid #2563eb; border-radius: 4px; }
          .notes h4 { color: #1e293b; margin-bottom: 10px; }
          .notes p { color: #475569; }
          .footer { margin-top: 60px; padding-top: 20px; border-top: 1px solid #e2e8f0; text-align: center; color: #94a3b8; font-size: 12px; }
          @media print { body { padding: 20px; } .no-print { display: none; } }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="company-info">
            <h1>${company?.name || ''}</h1>
            ${company?.address ? `<p>${company.address}</p>` : ''}
            ${company?.phone ? `<p>Tél: ${company.phone}</p>` : ''}
            ${company?.email ? `<p>Email: ${company.email}</p>` : ''}
          </div>
          <div class="document-info">
            <h2>BON D'ACHAT</h2>
            <p><strong>N°:</strong> ${fullPurchase.purchase_number}</p>
            <p><strong>Date:</strong> ${new Date(fullPurchase.purchase_date).toLocaleDateString('fr-FR')}</p>
            <p>
              <span class="status-badge status-${fullPurchase.status}">
                ${fullPurchase.status === 'completed' ? 'Reçu' : fullPurchase.status === 'pending' ? 'En attente' : 'Annulé'}
              </span>
            </p>
          </div>
        </div>

        <div class="parties">
          <div class="party" style="margin-right: 20px;">
            <h3>Fournisseur</h3>
            <p><strong>${fullPurchase.supplier?.name}</strong></p>
            ${fullPurchase.supplier?.email ? `<p>Email: ${fullPurchase.supplier.email}</p>` : ''}
            ${fullPurchase.supplier?.phone ? `<p>Tél: ${fullPurchase.supplier.phone}</p>` : ''}
            ${fullPurchase.supplier?.address ? `<p>${fullPurchase.supplier.address}</p>` : ''}
            ${fullPurchase.supplier?.city ? `<p>${fullPurchase.supplier.city}, ${fullPurchase.supplier.country}</p>` : ''}
          </div>
          <div class="party">
            <h3>Acheteur</h3>
            <p><strong>${company?.name || ''}</strong></p>
            ${company?.address ? `<p>${company.address}</p>` : ''}
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th style="width: 50%">Désignation</th>
              <th class="text-right">Quantité</th>
              <th class="text-right">Prix unitaire</th>
              <th class="text-right">Montant</th>
            </tr>
          </thead>
          <tbody>
            ${fullPurchase.items?.map(item => `
              <tr>
                <td>
                  <strong>${item.product?.name}</strong>
                </td>
                <td class="text-right">${item.quantity}</td>
                <td class="text-right">${item.unit_price.toLocaleString('fr-FR')} FCFA</td>
                <td class="text-right"><strong>${item.total_price.toLocaleString('fr-FR')} FCFA</strong></td>
              </tr>
            `).join('')}
          </tbody>
        </table>

        <div class="totals">
          <table>
            <tr class="total-row">
              <td><strong>TOTAL</strong></td>
              <td class="text-right"><strong>${fullPurchase.total_amount.toLocaleString('fr-FR')} FCFA</strong></td>
            </tr>
          </table>
        </div>

        ${fullPurchase.notes ? `
          <div class="notes">
            <h4>Notes</h4>
            <p>${fullPurchase.notes}</p>
          </div>
        ` : ''}

        <div class="footer">
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
  } catch (error) {
    console.error('Error printing purchase:', error);
    alert('Erreur lors de l\'impression');
  }
};

const closeForm = () => {
  showForm.value = false;
  formData.value = {
    supplier_id: '',
    purchase_date: new Date().toISOString().split('T')[0],
    notes: '',
    items: [],
  };
  productSearch.value = {};
};

const closeDetails = () => {
  selectedPurchase.value = null;
};

const getStatusColor = (status: string) => {
  switch (status) {
    case 'completed': return 'bg-green-100 text-green-800';
    case 'cancelled': return 'bg-red-100 text-red-800';
    default: return 'bg-yellow-100 text-yellow-800';
  }
};

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'completed': return 'Reçu';
    case 'cancelled': return 'Annulé';
    default: return 'En attente';
  }
};

onMounted(() => {
  loadPurchases();
  loadSuppliers();
  loadProducts();
});
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">Gestion des Achats</h2>
        <p class="text-gray-600 mt-1">Gérez vos achats auprès des fournisseurs</p>
      </div>
      <button
        @click="showForm = true; addProduct();"
        class="btn-primary inline-flex items-center gap-2"
      >
        <Icon name="plus" class="w-5 h-5" />
        <span>Nouvel achat</span>
      </button>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
      <div class="flex gap-2">
        <button
          @click="filterStatus = 'all'"
          :class="[
            'px-4 py-2 rounded-lg font-medium transition-all',
            filterStatus === 'all'
              ? 'bg-blue-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
        >
          Tous ({{ purchases.length }})
        </button>
        <button
          @click="filterStatus = 'pending'"
          :class="[
            'px-4 py-2 rounded-lg font-medium transition-all',
            filterStatus === 'pending'
              ? 'bg-yellow-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
        >
          En attente ({{ purchases.filter(p => p.status === 'pending').length }})
        </button>
        <button
          @click="filterStatus = 'completed'"
          :class="[
            'px-4 py-2 rounded-lg font-medium transition-all',
            filterStatus === 'completed'
              ? 'bg-green-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
        >
          Reçus ({{ purchases.filter(p => p.status === 'completed').length }})
        </button>
        <button
          @click="filterStatus = 'cancelled'"
          :class="[
            'px-4 py-2 rounded-lg font-medium transition-all',
            filterStatus === 'cancelled'
              ? 'bg-red-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
        >
          Annulés ({{ purchases.filter(p => p.status === 'cancelled').length }})
        </button>
      </div>
    </div>

    <div v-if="loading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="filteredPurchases.length === 0" class="text-center py-12 bg-white rounded-xl shadow-sm border border-gray-200">
      <Icon name="box" class="w-16 h-16 text-gray-300 mx-auto mb-4" />
      <p class="text-gray-500">Aucun achat trouvé</p>
    </div>

    <div v-else class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">N° Achat</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fournisseur</th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Montant</th>
              <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Statut</th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-for="purchase in filteredPurchases" :key="purchase.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-gray-900">{{ purchase.purchase_number }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm text-gray-500">{{ new Date(purchase.purchase_date).toLocaleDateString('fr-FR') }}</div>
              </td>
              <td class="px-6 py-4">
                <div class="text-sm font-medium text-gray-900">{{ purchase.supplier?.name }}</div>
                <div v-if="purchase.supplier?.city" class="text-sm text-gray-500">{{ purchase.supplier.city }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right">
                <div class="text-sm font-bold text-gray-900">{{ purchase.total_amount.toLocaleString('fr-FR') }} F</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-center">
                <span :class="['px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full', getStatusColor(purchase.status)]">
                  {{ getStatusLabel(purchase.status) }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <div class="flex items-center justify-end gap-2">
                  <button
                    @click="viewPurchase(purchase)"
                    class="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                    title="Voir détails"
                  >
                    <Icon name="eye" class="w-5 h-5" />
                  </button>
                  <button
                    @click="printPurchase(purchase)"
                    class="p-2 text-gray-600 hover:bg-gray-50 rounded-lg transition-colors"
                    title="Imprimer"
                  >
                    <Icon name="print" class="w-5 h-5" />
                  </button>
                  <button
                    v-if="purchase.status === 'pending'"
                    @click="completePurchase(purchase)"
                    class="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                    title="Valider réception"
                  >
                    <Icon name="check" class="w-5 h-5" />
                  </button>
                  <button
                    v-if="purchase.status === 'pending'"
                    @click="cancelPurchase(purchase)"
                    class="p-2 text-orange-600 hover:bg-orange-50 rounded-lg transition-colors"
                    title="Annuler"
                  >
                    <Icon name="close" class="w-5 h-5" />
                  </button>
                  <button
                    @click="deletePurchase(purchase)"
                    class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    title="Supprimer"
                  >
                    <Icon name="trash" class="w-5 h-5" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div
      v-if="showForm"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      @click.self="closeForm"
    >
      <div class="bg-white rounded-xl shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <h3 class="text-xl font-bold text-gray-800">Nouvel Achat</h3>
          <button
            @click="closeForm"
            class="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <Icon name="close" class="w-5 h-5" />
          </button>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Fournisseur *
              </label>
              <select
                v-model="formData.supplier_id"
                required
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">Sélectionner un fournisseur</option>
                <option v-for="supplier in suppliers" :key="supplier.id" :value="supplier.id">
                  {{ supplier.name }}
                </option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Date d'achat *
              </label>
              <input
                v-model="formData.purchase_date"
                type="date"
                required
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Notes
            </label>
            <textarea
              v-model="formData.notes"
              rows="2"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
              placeholder="Notes supplémentaires..."
            ></textarea>
          </div>

          <div class="border-t pt-4">
            <div class="flex justify-between items-center mb-4">
              <h4 class="font-semibold text-base">Produits</h4>
              <button
                type="button"
                @click="addProduct"
                class="px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium"
              >
                + Ajouter un produit
              </button>
            </div>

            <div v-for="(item, index) in formData.items" :key="index" class="mb-4 p-4 border border-gray-200 rounded-lg bg-gray-50">
              <div class="flex items-start gap-3">
                <div class="flex-1 space-y-3">
                  <div class="relative">
                    <label class="block text-sm font-medium text-gray-700 mb-1">Produit</label>
                    <input
                      v-model="productSearch[index]"
                      type="text"
                      placeholder="Rechercher un produit..."
                      class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
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
                        @click="selectProduct(index, product)"
                        class="w-full text-left px-3 py-2 hover:bg-blue-50 border-b border-gray-100 last:border-b-0"
                      >
                        <div class="font-medium">{{ product.name }}</div>
                        <div class="text-sm text-gray-600">{{ product.price }} F CFA</div>
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
                        required
                        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
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
                        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                  </div>

                  <div class="text-sm text-gray-600">
                    Total: <span class="font-bold text-gray-900">{{ (item.quantity * item.unit_price).toLocaleString('fr-FR') }} FCFA</span>
                  </div>
                </div>

                <button
                  type="button"
                  @click="removeProduct(index)"
                  class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                >
                  <Icon name="trash" class="w-5 h-5" />
                </button>
              </div>
            </div>
          </div>

          <div class="bg-blue-50 p-4 rounded-lg border border-blue-200">
            <div class="flex justify-between items-center">
              <span class="text-lg font-semibold text-gray-800">Total</span>
              <span class="text-2xl font-bold text-blue-600">{{ totalAmount.toLocaleString('fr-FR') }} FCFA</span>
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-4">
            <button
              type="button"
              @click="closeForm"
              class="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
            >
              Annuler
            </button>
            <button
              type="submit"
              :disabled="loading"
              class="btn-primary"
            >
              {{ loading ? 'Enregistrement...' : 'Enregistrer l\'achat' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <div
      v-if="selectedPurchase"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      @click.self="closeDetails"
    >
      <div class="bg-white rounded-xl shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <h3 class="text-xl font-bold text-gray-800">Détails de l'achat</h3>
          <button
            @click="closeDetails"
            class="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <Icon name="close" class="w-5 h-5" />
          </button>
        </div>

        <div class="p-6 space-y-6">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <p class="text-sm text-gray-500">Numéro d'achat</p>
              <p class="text-lg font-bold text-gray-900">{{ selectedPurchase.purchase_number }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Date</p>
              <p class="text-lg font-semibold text-gray-900">{{ new Date(selectedPurchase.purchase_date).toLocaleDateString('fr-FR') }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Fournisseur</p>
              <p class="text-lg font-semibold text-gray-900">{{ selectedPurchase.supplier?.name }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Statut</p>
              <span :class="['px-3 py-1 inline-flex text-sm font-semibold rounded-full', getStatusColor(selectedPurchase.status)]">
                {{ getStatusLabel(selectedPurchase.status) }}
              </span>
            </div>
          </div>

          <div v-if="selectedPurchase.notes" class="bg-gray-50 p-4 rounded-lg border border-gray-200">
            <p class="text-sm font-medium text-gray-700 mb-2">Notes</p>
            <p class="text-sm text-gray-600">{{ selectedPurchase.notes }}</p>
          </div>

          <div>
            <h4 class="font-semibold text-lg mb-3">Articles</h4>
            <div class="overflow-x-auto">
              <table class="w-full">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-2 text-left text-sm font-medium text-gray-500">Produit</th>
                    <th class="px-4 py-2 text-right text-sm font-medium text-gray-500">Quantité</th>
                    <th class="px-4 py-2 text-right text-sm font-medium text-gray-500">Prix unitaire</th>
                    <th class="px-4 py-2 text-right text-sm font-medium text-gray-500">Total</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                  <tr v-for="item in selectedPurchase.items" :key="item.id">
                    <td class="px-4 py-3 text-sm text-gray-900">{{ item.product?.name }}</td>
                    <td class="px-4 py-3 text-sm text-gray-900 text-right">{{ item.quantity }}</td>
                    <td class="px-4 py-3 text-sm text-gray-900 text-right">{{ item.unit_price.toLocaleString('fr-FR') }} F</td>
                    <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ item.total_price.toLocaleString('fr-FR') }} F</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div class="bg-blue-50 p-4 rounded-lg border border-blue-200">
            <div class="flex justify-between items-center">
              <span class="text-lg font-semibold text-gray-800">TOTAL</span>
              <span class="text-2xl font-bold text-blue-600">{{ selectedPurchase.total_amount.toLocaleString('fr-FR') }} FCFA</span>
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-4 border-t">
            <button
              @click="printPurchase(selectedPurchase)"
              class="btn-secondary inline-flex items-center gap-2"
            >
              <Icon name="print" class="w-5 h-5" />
              <span>Imprimer</span>
            </button>
            <button
              v-if="selectedPurchase.status === 'pending'"
              @click="completePurchase(selectedPurchase); closeDetails();"
              class="btn-primary inline-flex items-center gap-2"
            >
              <Icon name="check" class="w-5 h-5" />
              <span>Valider réception</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
