<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h2 class="text-2xl font-bold text-gray-900">Gestion des Commerciaux</h2>
      <button
        @click="openCreateForm"
        class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
      >
        Nouveau Commercial
      </button>
    </div>

    <div v-if="showForm" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <h3 class="text-xl font-bold mb-4">
          {{ editingCommercial ? 'Modifier le Commercial' : 'Nouveau Commercial' }}
        </h3>

        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div class="flex items-center space-x-4 mb-4">
            <div class="relative">
              <img
                v-if="previewUrl || formData.photo_url"
                :src="previewUrl || formData.photo_url"
                alt="Photo"
                class="w-24 h-24 rounded-full object-cover border-2 border-gray-300"
              />
              <div
                v-else
                class="w-24 h-24 rounded-full bg-gray-200 flex items-center justify-center border-2 border-gray-300"
              >
                <span class="text-gray-400 text-3xl">👤</span>
              </div>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Photo du commercial</label>
              <input
                type="file"
                @change="handleFileSelect"
                accept="image/*"
                class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
              />
              <p class="text-xs text-gray-500 mt-1">JPG, PNG ou GIF (max. 5MB)</p>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Nom complet *</label>
            <input
              v-model="formData.full_name"
              type="text"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Jean Dupont"
            />
          </div>

          <div v-if="!editingCommercial">
            <label class="block text-sm font-medium text-gray-700 mb-1">Email *</label>
            <input
              v-model="formData.email"
              type="email"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="jean.dupont@example.com"
            />
          </div>

          <div v-if="!editingCommercial">
            <label class="block text-sm font-medium text-gray-700 mb-1">Mot de passe *</label>
            <input
              v-model="formData.password"
              type="password"
              required
              minlength="6"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Minimum 6 caractères"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Téléphone WhatsApp</label>
            <input
              v-model="formData.phone"
              type="tel"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="+225xxxxxxxxxx"
            />
            <p class="text-xs text-gray-500 mt-1">Format international (ex: +225xxxxxxxxxx)</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Zone d'affectation *</label>
            <select
              v-model="formData.zone_affectation"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">-- Sélectionner une commune --</option>
              <option v-for="commune in communesCoteIvoire" :key="commune" :value="commune">
                {{ commune }}
              </option>
            </select>
            <p class="text-xs text-gray-500 mt-1">Commune de Côte d'Ivoire où le commercial est affecté</p>
          </div>

          <div v-if="error" class="bg-red-50 text-red-600 px-4 py-2 rounded-lg">
            {{ error }}
          </div>

          <div v-if="uploadProgress > 0 && uploadProgress < 100" class="w-full bg-gray-200 rounded-full h-2">
            <div
              class="bg-blue-600 h-2 rounded-full transition-all duration-300"
              :style="{ width: uploadProgress + '%' }"
            ></div>
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
              :disabled="uploading"
              class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
            >
              {{ uploading ? 'Envoi...' : editingCommercial ? 'Mettre à jour' : 'Créer' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="selectedCommercial" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-start mb-4">
          <div class="flex items-center space-x-4">
            <img
              v-if="selectedCommercial.photo_url"
              :src="selectedCommercial.photo_url"
              alt="Photo"
              class="w-16 h-16 rounded-full object-cover border-2 border-gray-300"
            />
            <div
              v-else
              class="w-16 h-16 rounded-full bg-gray-200 flex items-center justify-center border-2 border-gray-300"
            >
              <span class="text-gray-400 text-2xl">👤</span>
            </div>
            <div>
              <h3 class="text-xl font-bold">{{ selectedCommercial.full_name }}</h3>
              <p class="text-sm text-gray-600">{{ selectedCommercial.email }}</p>
              <div v-if="selectedCommercial.phone" class="flex items-center gap-2 mt-1">
                <p class="text-sm text-gray-600">{{ selectedCommercial.phone }}</p>
                <button
                  @click="openWhatsApp(selectedCommercial.phone)"
                  class="px-3 py-1 bg-green-500 text-white rounded hover:bg-green-600 text-xs font-medium"
                  title="Contacter sur WhatsApp"
                >
                  WhatsApp
                </button>
              </div>
              <p v-if="selectedCommercial.zone_affectation" class="text-sm text-gray-600 mt-1">
                📍 {{ selectedCommercial.zone_affectation }}
              </p>
            </div>
          </div>
          <button @click="selectedCommercial = null" class="text-gray-500 hover:text-gray-700 text-2xl">×</button>
        </div>

        <div class="mt-6">
          <h4 class="font-semibold mb-3">Clients et Prospects assignés ({{ commercialClients.length }})</h4>

          <div v-if="commercialClients.length === 0" class="text-center py-8 bg-gray-50 rounded-lg">
            <p class="text-gray-500">Aucun client assigné</p>
          </div>

          <div v-else class="space-y-2">
            <div
              v-for="client in commercialClients"
              :key="client.id"
              class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
            >
              <div>
                <p class="font-medium">{{ client.name }}</p>
                <p class="text-sm text-gray-600">{{ client.email }}</p>
                <p v-if="client.phone" class="text-sm text-gray-600">{{ client.phone }}</p>
              </div>
              <div class="text-right">
                <span
                  class="inline-block px-3 py-1 rounded-full text-sm font-medium"
                  :class="client.type === 'client' ? 'bg-green-100 text-green-800' : 'bg-blue-100 text-blue-800'"
                >
                  {{ client.type === 'client' ? 'Client' : 'Prospect' }}
                </span>
                <p class="text-xs text-gray-500 mt-1">{{ client.status }}</p>
              </div>
            </div>
          </div>
        </div>

        <div class="flex gap-2 justify-end mt-6">
          <button
            @click="selectedCommercial = null"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>

    <div v-if="commercials.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">Aucun commercial</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="commercial in commercials"
        :key="commercial.id"
        class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
      >
        <div class="flex items-start justify-between mb-4">
          <div class="flex items-center space-x-3">
            <img
              v-if="commercial.photo_url"
              :src="commercial.photo_url"
              alt="Photo"
              class="w-12 h-12 rounded-full object-cover border-2 border-gray-300"
            />
            <div
              v-else
              class="w-12 h-12 rounded-full bg-gray-200 flex items-center justify-center border-2 border-gray-300"
            >
              <span class="text-gray-400 text-xl">👤</span>
            </div>
            <div>
              <h3 class="font-semibold text-gray-900">{{ commercial.full_name }}</h3>
              <p class="text-sm text-gray-500">Commercial</p>
            </div>
          </div>
        </div>

        <div class="space-y-2 mb-4">
          <div class="flex items-center text-sm text-gray-600">
            <span class="mr-2">📧</span>
            <span class="truncate">{{ commercial.email }}</span>
          </div>
          <div v-if="commercial.phone" class="flex items-center justify-between text-sm text-gray-600">
            <div class="flex items-center">
              <span class="mr-2">📱</span>
              <span>{{ commercial.phone }}</span>
            </div>
            <button
              @click="openWhatsApp(commercial.phone)"
              class="ml-2 px-2 py-1 bg-green-500 text-white rounded hover:bg-green-600 text-xs font-medium"
              title="Contacter sur WhatsApp"
            >
              WhatsApp
            </button>
          </div>
          <div v-if="commercial.zone_affectation" class="flex items-center text-sm text-gray-600">
            <span class="mr-2">📍</span>
            <span>{{ commercial.zone_affectation }}</span>
          </div>
        </div>

        <div class="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-4 mb-4">
          <div class="flex items-center justify-between mb-2">
            <span class="text-xs font-medium text-blue-600">CA ce mois</span>
            <span class="text-xs text-blue-500">💰</span>
          </div>
          <div class="text-2xl font-bold text-blue-900">
            {{ formatCurrency(getCommercialRevenue(commercial.id)?.monthly_revenue || 0) }} FCFA
          </div>
          <div class="text-xs text-blue-600 mt-1">
            {{ getCommercialRevenue(commercial.id)?.monthly_orders || 0 }} commandes
          </div>
        </div>

        <div class="flex gap-2 mt-4">
          <button
            @click="viewCommercialClients(commercial)"
            class="flex-1 px-3 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 text-sm font-medium"
          >
            Voir clients
          </button>
          <button
            @click="openEditForm(commercial)"
            class="px-3 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
            title="Modifier"
          >
            ✏️
          </button>
          <button
            v-if="canDelete"
            @click="deleteCommercialConfirm(commercial)"
            class="px-3 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100"
            title="Supprimer"
          >
            🗑️
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { commercialsService, type Commercial, type CreateCommercialData, type UpdateCommercialData } from '../services/commercials.service';
import { imageUploadService } from '../services/image-upload.service';
import { analyticsService, type CommercialMonthlyRevenue } from '../services/analytics.service';
import type { Profile } from '../services/supabase';
import { communesCoteIvoire } from '../data/communes-cote-ivoire';

const props = defineProps<{
  profile: Profile;
}>();

const commercials = ref<Commercial[]>([]);
const commercialsRevenue = ref<Map<string, CommercialMonthlyRevenue>>(new Map());
const showForm = ref(false);
const error = ref('');
const editingCommercial = ref<Commercial | null>(null);
const selectedCommercial = ref<Commercial | null>(null);
const commercialClients = ref<any[]>([]);
const selectedFile = ref<File | null>(null);
const previewUrl = ref('');
const uploading = ref(false);
const uploadProgress = ref(0);

const canDelete = computed(() => {
  return props.profile.role === 'admin';
});

const formData = ref<CreateCommercialData & UpdateCommercialData>({
  email: '',
  password: '',
  full_name: '',
  phone: '',
  photo_url: '',
  zone_affectation: '',
});

const loadCommercials = async () => {
  try {
    const [commercialsData, revenueData] = await Promise.all([
      commercialsService.getAllCommercials(),
      analyticsService.getCommercialsMonthlyRevenue(),
    ]);

    commercials.value = commercialsData;

    const revenueMap = new Map<string, CommercialMonthlyRevenue>();
    revenueData.forEach((rev) => {
      revenueMap.set(rev.id, rev);
    });
    commercialsRevenue.value = revenueMap;
  } catch (err) {
    console.error('Error loading commercials:', err);
  }
};

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'decimal',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
};

const getCommercialRevenue = (commercialId: string) => {
  return commercialsRevenue.value.get(commercialId);
};

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];

  if (file) {
    if (file.size > 5 * 1024 * 1024) {
      error.value = 'Le fichier est trop volumineux (max. 5MB)';
      return;
    }

    selectedFile.value = file;
    previewUrl.value = URL.createObjectURL(file);
  }
};

const uploadPhoto = async (): Promise<string | null> => {
  if (!selectedFile.value) return formData.value.photo_url || null;

  try {
    uploading.value = true;
    uploadProgress.value = 0;

    const progressInterval = setInterval(() => {
      if (uploadProgress.value < 90) {
        uploadProgress.value += 10;
      }
    }, 100);

    const url = await imageUploadService.uploadImage(selectedFile.value, 'commercial-photos');

    clearInterval(progressInterval);
    uploadProgress.value = 100;

    return url;
  } catch (err) {
    console.error('Error uploading photo:', err);
    throw new Error('Erreur lors du téléchargement de la photo');
  } finally {
    uploading.value = false;
    setTimeout(() => {
      uploadProgress.value = 0;
    }, 1000);
  }
};

const handleSubmit = async () => {
  error.value = '';

  try {
    const photoUrl = await uploadPhoto();

    if (editingCommercial.value) {
      await commercialsService.updateCommercial(editingCommercial.value.id, {
        full_name: formData.value.full_name,
        phone: formData.value.phone,
        photo_url: photoUrl || undefined,
        zone_affectation: formData.value.zone_affectation || undefined,
      });
      alert('Commercial mis à jour avec succès');
    } else {
      if (!formData.value.email || !formData.value.password) {
        error.value = 'Email et mot de passe sont requis';
        return;
      }

      await commercialsService.createCommercial({
        email: formData.value.email,
        password: formData.value.password,
        full_name: formData.value.full_name,
        phone: formData.value.phone,
        photo_url: photoUrl || undefined,
        zone_affectation: formData.value.zone_affectation || undefined,
      });
      alert('Commercial créé avec succès');
    }

    await loadCommercials();
    closeForm();
  } catch (err: any) {
    console.error('Error saving commercial:', err);
    error.value = err.message || 'Erreur lors de l\'enregistrement';
  }
};

const openCreateForm = () => {
  editingCommercial.value = null;
  formData.value = {
    email: '',
    password: '',
    full_name: '',
    phone: '',
    photo_url: '',
    zone_affectation: '',
  };
  selectedFile.value = null;
  previewUrl.value = '';
  showForm.value = true;
};

const openEditForm = (commercial: Commercial) => {
  editingCommercial.value = commercial;
  formData.value = {
    email: commercial.email,
    password: '',
    full_name: commercial.full_name,
    phone: commercial.phone || '',
    photo_url: commercial.photo_url || '',
    zone_affectation: commercial.zone_affectation || '',
  };
  selectedFile.value = null;
  previewUrl.value = '';
  showForm.value = true;
};

const closeForm = () => {
  showForm.value = false;
  editingCommercial.value = null;
  formData.value = {
    email: '',
    password: '',
    full_name: '',
    phone: '',
    photo_url: '',
    zone_affectation: '',
  };
  selectedFile.value = null;
  previewUrl.value = '';
  error.value = '';
  uploadProgress.value = 0;
};

const deleteCommercialConfirm = async (commercial: Commercial) => {
  if (!confirm(`Voulez-vous vraiment supprimer ${commercial.full_name} ?`)) {
    return;
  }

  try {
    await commercialsService.deleteCommercial(commercial.id);
    alert('Commercial supprimé avec succès');
    await loadCommercials();
  } catch (err: any) {
    console.error('Error deleting commercial:', err);
    alert(err.message || 'Erreur lors de la suppression');
  }
};

const viewCommercialClients = async (commercial: Commercial) => {
  try {
    selectedCommercial.value = commercial;
    commercialClients.value = await commercialsService.getCommercialClients(commercial.id);
  } catch (err) {
    console.error('Error loading commercial clients:', err);
    alert('Erreur lors du chargement des clients');
  }
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
  loadCommercials();
});
</script>
