<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { suppliersService, type Supplier } from '../services/suppliers.service';
import Icon from './Icon.vue';

const suppliers = ref<Supplier[]>([]);
const loading = ref(false);
const showModal = ref(false);
const editingSupplier = ref<Supplier | null>(null);
const searchQuery = ref('');

const formData = ref({
  name: '',
  email: '',
  phone: '',
  address: '',
  city: '',
  country: 'Côte d\'Ivoire',
  notes: '',
});

const filteredSuppliers = ref<Supplier[]>([]);

const loadSuppliers = async () => {
  try {
    loading.value = true;
    suppliers.value = await suppliersService.getSuppliers();
    filterSuppliers();
  } catch (error) {
    console.error('Error loading suppliers:', error);
    alert('Erreur lors du chargement des fournisseurs');
  } finally {
    loading.value = false;
  }
};

const filterSuppliers = () => {
  const query = searchQuery.value.toLowerCase();
  filteredSuppliers.value = suppliers.value.filter(supplier =>
    supplier.name.toLowerCase().includes(query) ||
    supplier.email?.toLowerCase().includes(query) ||
    supplier.phone?.includes(query) ||
    supplier.city?.toLowerCase().includes(query)
  );
};

const openModal = (supplier?: Supplier) => {
  if (supplier) {
    editingSupplier.value = supplier;
    formData.value = {
      name: supplier.name,
      email: supplier.email || '',
      phone: supplier.phone || '',
      address: supplier.address || '',
      city: supplier.city || '',
      country: supplier.country || 'Côte d\'Ivoire',
      notes: supplier.notes || '',
    };
  } else {
    editingSupplier.value = null;
    formData.value = {
      name: '',
      email: '',
      phone: '',
      address: '',
      city: '',
      country: 'Côte d\'Ivoire',
      notes: '',
    };
  }
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  editingSupplier.value = null;
};

const saveSupplier = async () => {
  try {
    if (!formData.value.name.trim()) {
      alert('Veuillez renseigner le nom du fournisseur');
      return;
    }

    loading.value = true;

    if (editingSupplier.value) {
      await suppliersService.updateSupplier(editingSupplier.value.id, formData.value);
    } else {
      await suppliersService.createSupplier(formData.value);
    }

    await loadSuppliers();
    closeModal();
  } catch (error) {
    console.error('Error saving supplier:', error);
    alert('Erreur lors de la sauvegarde du fournisseur');
  } finally {
    loading.value = false;
  }
};

const deleteSupplier = async (supplier: Supplier) => {
  if (!confirm(`Êtes-vous sûr de vouloir supprimer le fournisseur "${supplier.name}" ?`)) {
    return;
  }

  try {
    loading.value = true;
    await suppliersService.deleteSupplier(supplier.id);
    await loadSuppliers();
  } catch (error) {
    console.error('Error deleting supplier:', error);
    alert('Erreur lors de la suppression du fournisseur');
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  loadSuppliers();
});
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">Gestion des Fournisseurs</h2>
        <p class="text-gray-600 mt-1">Gérez vos fournisseurs et leurs informations</p>
      </div>
      <button
        @click="openModal()"
        class="btn-primary inline-flex items-center gap-2"
      >
        <Icon name="plus" class="w-5 h-5" />
        <span>Nouveau fournisseur</span>
      </button>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
      <div class="flex items-center gap-3">
        <div class="flex-1 relative">
          <Icon name="search" class="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            v-model="searchQuery"
            @input="filterSuppliers"
            type="text"
            placeholder="Rechercher par nom, email, téléphone ou ville..."
            class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>
      </div>
    </div>

    <div v-if="loading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="filteredSuppliers.length === 0" class="text-center py-12 bg-white rounded-xl shadow-sm border border-gray-200">
      <Icon name="box" class="w-16 h-16 text-gray-300 mx-auto mb-4" />
      <p class="text-gray-500">
        {{ searchQuery ? 'Aucun fournisseur trouvé' : 'Aucun fournisseur enregistré' }}
      </p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="supplier in filteredSuppliers"
        :key="supplier.id"
        class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
      >
        <div class="flex items-start justify-between mb-4">
          <div class="flex-1">
            <h3 class="text-lg font-bold text-gray-800 mb-1">{{ supplier.name }}</h3>
            <p v-if="supplier.city" class="text-sm text-gray-500">{{ supplier.city }}, {{ supplier.country }}</p>
          </div>
          <div class="flex gap-2">
            <button
              @click="openModal(supplier)"
              class="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
              title="Modifier"
            >
              <Icon name="edit" class="w-5 h-5" />
            </button>
            <button
              @click="deleteSupplier(supplier)"
              class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
              title="Supprimer"
            >
              <Icon name="trash" class="w-5 h-5" />
            </button>
          </div>
        </div>

        <div class="space-y-2">
          <div v-if="supplier.email" class="flex items-center gap-2 text-sm text-gray-600">
            <Icon name="mail" class="w-4 h-4 flex-shrink-0" />
            <span class="truncate">{{ supplier.email }}</span>
          </div>
          <div v-if="supplier.phone" class="flex items-center gap-2 text-sm text-gray-600">
            <Icon name="phone" class="w-4 h-4 flex-shrink-0" />
            <span>{{ supplier.phone }}</span>
          </div>
          <div v-if="supplier.address" class="flex items-start gap-2 text-sm text-gray-600">
            <Icon name="location" class="w-4 h-4 flex-shrink-0 mt-0.5" />
            <span class="line-clamp-2">{{ supplier.address }}</span>
          </div>
        </div>

        <div v-if="supplier.notes" class="mt-4 pt-4 border-t border-gray-200">
          <p class="text-sm text-gray-600 line-clamp-2">{{ supplier.notes }}</p>
        </div>
      </div>
    </div>

    <div
      v-if="showModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      @click.self="closeModal"
    >
      <div class="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <h3 class="text-xl font-bold text-gray-800">
            {{ editingSupplier ? 'Modifier le fournisseur' : 'Nouveau fournisseur' }}
          </h3>
          <button
            @click="closeModal"
            class="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <Icon name="close" class="w-5 h-5" />
          </button>
        </div>

        <div class="p-6 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Nom du fournisseur *
            </label>
            <input
              v-model="formData.name"
              type="text"
              required
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Ex: Société ABC"
            />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Email
              </label>
              <input
                v-model="formData.email"
                type="email"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="email@example.com"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Téléphone
              </label>
              <input
                v-model="formData.phone"
                type="tel"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Ex: 07 08 09 10 11"
              />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Adresse
            </label>
            <input
              v-model="formData.address"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Ex: Cocody Angré 8ème tranche"
            />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Ville
              </label>
              <input
                v-model="formData.city"
                type="text"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Ex: Abidjan"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Pays
              </label>
              <input
                v-model="formData.country"
                type="text"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Ex: Côte d'Ivoire"
              />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Notes
            </label>
            <textarea
              v-model="formData.notes"
              rows="3"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
              placeholder="Notes supplémentaires..."
            ></textarea>
          </div>
        </div>

        <div class="sticky bottom-0 bg-gray-50 px-6 py-4 flex justify-end gap-3 border-t border-gray-200">
          <button
            @click="closeModal"
            type="button"
            class="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
          >
            Annuler
          </button>
          <button
            @click="saveSupplier"
            :disabled="loading"
            class="btn-primary"
          >
            {{ loading ? 'Enregistrement...' : 'Enregistrer' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
