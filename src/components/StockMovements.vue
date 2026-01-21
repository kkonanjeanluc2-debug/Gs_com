<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Mouvements de Stock</h2>
        <p class="text-sm text-gray-500 mt-1">Suivi des entrées, sorties et ajustements</p>
      </div>
      <button
        @click="showAddMovement = true"
        class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
      >
        Ajouter un mouvement
      </button>
    </div>

    <div v-if="lowStockProducts.length > 0" class="bg-red-50 border border-red-200 rounded-lg p-4">
      <div class="flex items-start gap-3">
        <div class="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center flex-shrink-0">
          <span class="text-2xl">⚠️</span>
        </div>
        <div class="flex-1">
          <h3 class="font-semibold text-red-900 mb-2">Alertes de stock faible</h3>
          <div class="space-y-1">
            <div v-for="product in lowStockProducts" :key="product.id" class="text-sm text-red-800">
              <strong>{{ product.name }}</strong> ({{ product.sku }}) - Stock: <strong>{{ product.stock_quantity }}</strong>
              <span v-if="product.min_stock > 0"> / Min: {{ product.min_stock }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-lg shadow p-4">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Produit</label>
          <select
            v-model="filters.productId"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadMovements"
          >
            <option value="">Tous les produits</option>
            <option v-for="product in products" :key="product.id" :value="product.id">
              {{ product.name }} ({{ product.sku }})
            </option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Type</label>
          <select
            v-model="filters.type"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadMovements"
          >
            <option value="">Tous les types</option>
            <option value="entree">Entrée</option>
            <option value="sortie">Sortie</option>
            <option value="ajustement">Ajustement</option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Date</label>
          <input
            v-model="filters.date"
            type="date"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadMovements"
          />
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Entrées</p>
            <p class="text-2xl font-bold text-green-600">{{ stats.total_entries }}</p>
          </div>
          <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">📥</span>
          </div>
        </div>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Sorties</p>
            <p class="text-2xl font-bold text-red-600">{{ stats.total_exits }}</p>
          </div>
          <div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">📤</span>
          </div>
        </div>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Ajustements</p>
            <p class="text-2xl font-bold text-blue-600">{{ stats.total_adjustments }}</p>
          </div>
          <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">⚙️</span>
          </div>
        </div>
      </div>
    </div>

    <div v-if="showAddMovement" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-2xl w-full">
        <h3 class="text-xl font-bold mb-4">Ajouter un mouvement de stock</h3>

        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Produit *</label>
            <select
              v-model="formData.product_id"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Sélectionner un produit</option>
              <option v-for="product in products" :key="product.id" :value="product.id">
                {{ product.name }} ({{ product.sku }}) - Stock actuel: {{ product.stock_quantity }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Type de mouvement *</label>
            <select
              v-model="formData.type"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Sélectionner un type</option>
              <option value="entree">Entrée (ajout au stock)</option>
              <option value="sortie">Sortie (retrait du stock)</option>
              <option value="ajustement">Ajustement (définir une nouvelle quantité)</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ formData.type === 'ajustement' ? 'Nouvelle quantité *' : 'Quantité *' }}
            </label>
            <input
              v-model.number="formData.quantity"
              type="number"
              min="0"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
            <p v-if="formData.product_id && formData.type && formData.quantity" class="text-sm text-gray-600 mt-1">
              {{ getStockPreview() }}
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Raison</label>
            <textarea
              v-model="formData.reason"
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Motif du mouvement..."
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
              Enregistrer
            </button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="movements.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">Aucun mouvement de stock</p>
    </div>

    <div v-else class="bg-white rounded-lg shadow overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Produit</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Quantité</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Raison</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Utilisateur</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-for="movement in movements" :key="movement.id">
            <td class="px-4 md:px-6 py-4 whitespace-nowrap text-sm text-gray-500">
              {{ new Date(movement.created_at!).toLocaleDateString('fr-FR') }}
              <div class="text-xs text-gray-400">{{ new Date(movement.created_at!).toLocaleTimeString('fr-FR') }}</div>
            </td>
            <td class="px-4 md:px-6 py-4">
              <div class="text-sm font-medium text-gray-900">{{ getProductName(movement.product_id) }}</div>
              <div class="text-xs text-gray-500">{{ getProductSku(movement.product_id) }}</div>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <span
                :class="['text-xs px-2 py-1 rounded-full', getTypeColor(movement.type)]"
              >
                {{ getTypeLabel(movement.type) }}
              </span>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <span
                :class="['font-semibold', getTypeTextColor(movement.type)]"
              >
                {{ formatQuantity(movement.type, movement.quantity) }}
              </span>
            </td>
            <td class="px-4 md:px-6 py-4 text-sm text-gray-600">
              {{ movement.reason || '-' }}
            </td>
            <td class="px-4 md:px-6 py-4 text-sm text-gray-600 whitespace-nowrap">
              {{ getUserName(movement.user_id) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { productsService, type Product } from '../services/products.service';
import { supabase, getCurrentUserCompanyId } from '../services/supabase';

interface StockMovement {
  id?: string;
  product_id: string;
  user_id: string;
  type: 'entree' | 'sortie' | 'ajustement';
  quantity: number;
  reason?: string;
  created_at?: string;
}

interface Profile {
  id: string;
  full_name: string;
}

const movements = ref<StockMovement[]>([]);
const products = ref<Product[]>([]);
const lowStockProducts = ref<Product[]>([]);
const profiles = ref<Profile[]>([]);
const showAddMovement = ref(false);
const error = ref('');

const stats = ref({
  total_entries: 0,
  total_exits: 0,
  total_adjustments: 0,
});

const filters = ref({
  productId: '',
  type: '',
  date: '',
});

const formData = ref({
  product_id: '',
  type: '',
  quantity: 0,
  reason: '',
});

const loadMovements = async () => {
  try {
    let allMovements = await productsService.getStockMovements(filters.value.productId || undefined);

    if (filters.value.type) {
      allMovements = allMovements.filter(m => m.type === filters.value.type);
    }

    if (filters.value.date) {
      allMovements = allMovements.filter(m => {
        const movementDate = new Date(m.created_at!).toISOString().split('T')[0];
        return movementDate === filters.value.date;
      });
    }

    movements.value = allMovements;
    calculateStats(allMovements);
  } catch (err) {
    console.error('Error loading movements:', err);
  }
};

const calculateStats = (movementsData: any[]) => {
  stats.value = {
    total_entries: movementsData.filter(m => m.type === 'entree').length,
    total_exits: movementsData.filter(m => m.type === 'sortie').length,
    total_adjustments: movementsData.filter(m => m.type === 'ajustement').length,
  };
};

const loadProducts = async () => {
  try {
    products.value = await productsService.getAllProducts();
  } catch (err) {
    console.error('Error loading products:', err);
  }
};

const loadLowStockProducts = async () => {
  try {
    const allProducts = await productsService.getAllProducts();
    lowStockProducts.value = allProducts.filter(p => {
      if (p.min_stock > 0) {
        return p.stock_quantity <= p.min_stock;
      } else {
        return p.stock_quantity <= 10;
      }
    });
  } catch (err) {
    console.error('Error loading low stock products:', err);
  }
};

const loadProfiles = async () => {
  try {
    const companyId = await getCurrentUserCompanyId();
    const { data, error } = await supabase
      .from('profiles')
      .select('id, full_name')
      .eq('company_id', companyId);

    if (error) throw error;
    profiles.value = data || [];
  } catch (err) {
    console.error('Error loading profiles:', err);
  }
};

const handleSubmit = async () => {
  error.value = '';

  if (!formData.value.product_id || !formData.value.type || formData.value.quantity < 0) {
    error.value = 'Veuillez remplir tous les champs obligatoires';
    return;
  }

  const product = products.value.find(p => p.id === formData.value.product_id);
  if (!product) {
    error.value = 'Produit introuvable';
    return;
  }

  if (formData.value.type === 'sortie' && formData.value.quantity > product.stock_quantity) {
    error.value = `Quantité insuffisante en stock (disponible: ${product.stock_quantity})`;
    return;
  }

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    await productsService.addStockMovement(
      formData.value.product_id,
      user.id,
      formData.value.type as any,
      formData.value.quantity,
      formData.value.reason
    );

    await loadMovements();
    await loadProducts();
    await loadLowStockProducts();
    closeForm();
    alert('Mouvement enregistré avec succès');
  } catch (err: any) {
    console.error('Error creating movement:', err);
    error.value = err.message || 'Erreur lors de l\'enregistrement du mouvement';
  }
};

const closeForm = () => {
  showAddMovement.value = false;
  formData.value = {
    product_id: '',
    type: '',
    quantity: 0,
    reason: '',
  };
  error.value = '';
};

const getStockPreview = () => {
  const product = products.value.find(p => p.id === formData.value.product_id);
  if (!product) return '';

  let newStock = product.stock_quantity;
  if (formData.value.type === 'entree') {
    newStock += formData.value.quantity;
  } else if (formData.value.type === 'sortie') {
    newStock -= formData.value.quantity;
  } else if (formData.value.type === 'ajustement') {
    newStock = formData.value.quantity;
  }

  return `Stock actuel: ${product.stock_quantity} → Nouveau stock: ${newStock}`;
};

const getProductName = (productId: string) => {
  return products.value.find(p => p.id === productId)?.name || 'Produit inconnu';
};

const getProductSku = (productId: string) => {
  return products.value.find(p => p.id === productId)?.sku || '';
};

const getUserName = (userId: string) => {
  return profiles.value.find(p => p.id === userId)?.full_name || 'Utilisateur inconnu';
};

const getTypeColor = (type: string) => {
  switch (type) {
    case 'entree':
      return 'bg-green-100 text-green-800';
    case 'sortie':
      return 'bg-red-100 text-red-800';
    case 'ajustement':
      return 'bg-blue-100 text-blue-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
};

const getTypeTextColor = (type: string) => {
  switch (type) {
    case 'entree':
      return 'text-green-600';
    case 'sortie':
      return 'text-red-600';
    case 'ajustement':
      return 'text-blue-600';
    default:
      return 'text-gray-600';
  }
};

const getTypeLabel = (type: string) => {
  switch (type) {
    case 'entree':
      return 'Entrée';
    case 'sortie':
      return 'Sortie';
    case 'ajustement':
      return 'Ajustement';
    default:
      return type;
  }
};

const formatQuantity = (type: string, quantity: number) => {
  if (type === 'entree') {
    return `+${quantity}`;
  } else if (type === 'sortie') {
    return `-${quantity}`;
  } else {
    return quantity.toString();
  }
};

onMounted(() => {
  loadMovements();
  loadProducts();
  loadLowStockProducts();
  loadProfiles();
});
</script>
