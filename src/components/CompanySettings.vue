<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h2 class="text-2xl font-bold text-gray-900">Informations de l'entreprise</h2>
    </div>

    <div v-if="loading" class="text-center py-12">
      <p class="text-gray-500">Chargement...</p>
    </div>

    <div v-else class="bg-white rounded-lg shadow-md p-6">
      <form @submit.prevent="handleSubmit" class="space-y-6">
        <div class="flex flex-col items-center mb-6">
          <div class="relative">
            <div v-if="previewUrl || formData.logo_url" class="w-48 h-48 mb-4 rounded-lg overflow-hidden border-2 border-gray-200">
              <img
                :src="previewUrl || formData.logo_url"
                alt="Logo"
                class="w-full h-full object-contain"
              />
            </div>
            <div v-else class="w-48 h-48 mb-4 rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center bg-gray-50">
              <span class="text-gray-400 text-4xl">🏢</span>
            </div>
          </div>

          <div class="flex gap-2">
            <label class="cursor-pointer bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
              📁 Choisir un logo
              <input
                type="file"
                accept="image/*"
                @change="handleFileChange"
                class="hidden"
              />
            </label>
            <button
              v-if="formData.logo_url"
              type="button"
              @click="handleRemoveLogo"
              class="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
            >
              🗑️ Supprimer
            </button>
          </div>
        </div>

        <div v-if="subscriptionInfo" class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <h3 class="text-sm font-semibold text-blue-900 mb-3">Informations d'abonnement</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
            <div>
              <span class="text-blue-700 font-medium">Statut:</span>
              <span class="ml-2" :class="{
                'text-blue-800': subscriptionInfo.subscription_status === 'trial',
                'text-green-800': subscriptionInfo.subscription_status === 'active',
                'text-red-800': subscriptionInfo.subscription_status === 'expired',
                'text-gray-800': subscriptionInfo.subscription_status === 'suspended'
              }">
                {{ getStatusLabel(subscriptionInfo.subscription_status) }}
              </span>
            </div>
            <div v-if="subscriptionInfo.trial_end_date">
              <span class="text-blue-700 font-medium">Fin période d'essai:</span>
              <span class="ml-2 text-blue-900">{{ formatSubscriptionDate(subscriptionInfo.trial_end_date) }}</span>
            </div>
            <div v-if="subscriptionInfo.subscription_end_date">
              <span class="text-blue-700 font-medium">Fin d'abonnement:</span>
              <span class="ml-2 text-blue-900">{{ formatSubscriptionDate(subscriptionInfo.subscription_end_date) }}</span>
            </div>
            <div v-if="subscriptionInfo.blocked_reason" class="md:col-span-2">
              <span class="text-red-700 font-medium">Raison blocage:</span>
              <span class="ml-2 text-red-900">{{ subscriptionInfo.blocked_reason }}</span>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Nom de l'entreprise *
            </label>
            <input
              v-model="formData.name"
              type="text"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Mon Entreprise"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Email
            </label>
            <input
              v-model="formData.email"
              type="email"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="contact@entreprise.com"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Téléphone
            </label>
            <div class="flex gap-2">
              <input
                v-model="formData.phone"
                type="tel"
                class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="Numéro de téléphone"
              />
              <button
                v-if="formData.phone"
                type="button"
                @click="openWhatsApp"
                class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors flex items-center gap-2 whitespace-nowrap"
                title="Ouvrir WhatsApp"
              >
                <span>WhatsApp</span>
              </button>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Site web
            </label>
            <input
              v-model="formData.website"
              type="text"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="www.entreprise.com"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              N° SIRET / TVA
            </label>
            <input
              v-model="formData.tax_id"
              type="text"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="12345678901234"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              RCCM
            </label>
            <input
              v-model="formData.rccm"
              type="text"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="CD/KNG/RCCM/XX-X-XXXXX"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              NCC
            </label>
            <input
              v-model="formData.ncc"
              type="text"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="X-XXXXX-NXXXXXX"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Taux de commission (%)
            </label>
            <input
              v-model.number="formData.commission_rate"
              type="number"
              step="0.01"
              min="0"
              max="100"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="5.00"
            />
            <p class="text-xs text-gray-500 mt-1">Pourcentage de commission sur le CA des commerciaux</p>
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Adresse
          </label>
          <textarea
            v-model="formData.address"
            rows="3"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            placeholder="123 Rue de l'Entreprise&#10;75001 Paris&#10;France"
          ></textarea>
        </div>

        <div v-if="error" class="bg-red-50 text-red-600 px-4 py-2 rounded-lg">
          {{ error }}
        </div>

        <div v-if="success" class="bg-green-50 text-green-600 px-4 py-2 rounded-lg">
          Informations enregistrées avec succès
        </div>

        <div class="flex justify-end">
          <button
            type="submit"
            :disabled="saving"
            class="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-400"
          >
            {{ saving ? 'Enregistrement...' : 'Enregistrer' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { companyService, type CompanySettings } from '../services/company.service';
import { subscriptionService, type SubscriptionInfo } from '../services/subscription.service';
import { updateFavicon } from '../utils/favicon';

const loading = ref(true);
const saving = ref(false);
const error = ref('');
const success = ref(false);
const selectedFile = ref<File | null>(null);
const previewUrl = ref('');
const subscriptionInfo = ref<SubscriptionInfo | null>(null);

const formData = ref<CompanySettings>({
  name: '',
  email: '',
  phone: '',
  address: '',
  logo_url: '',
  website: '',
  tax_id: '',
  rccm: '',
  ncc: '',
  commission_rate: 5,
});

const loadSettings = async () => {
  try {
    loading.value = true;
    const settings = await companyService.getSettings();
    if (settings) {
      formData.value = { ...settings };

      const companyId = await companyService.getCurrentCompanyId();
      if (companyId) {
        subscriptionInfo.value = await subscriptionService.getSubscriptionInfo(companyId);
      }
    }
  } catch (err: any) {
    console.error('Error loading settings:', err);
    error.value = err.message || 'Erreur lors du chargement';
  } finally {
    loading.value = false;
  }
};

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    trial: 'Essai gratuit',
    active: 'Actif',
    expired: 'Expiré',
    suspended: 'Suspendu',
  };
  return labels[status] || status;
};

const formatSubscriptionDate = (dateStr: string) => {
  const date = new Date(dateStr);
  return date.toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

const handleFileChange = (event: Event) => {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];

  if (file) {
    if (file.size > 5 * 1024 * 1024) {
      error.value = 'Le fichier est trop volumineux (max 5MB)';
      return;
    }

    if (!file.type.startsWith('image/')) {
      error.value = 'Le fichier doit être une image';
      return;
    }

    selectedFile.value = file;
    previewUrl.value = URL.createObjectURL(file);
    error.value = '';
  }
};

const handleRemoveLogo = async () => {
  if (!confirm('Êtes-vous sûr de vouloir supprimer le logo ?')) return;

  try {
    if (formData.value.logo_url) {
      await companyService.deleteLogo(formData.value.logo_url);
    }
    formData.value.logo_url = '';
    previewUrl.value = '';
    selectedFile.value = null;

    await companyService.updateSettings({
      ...formData.value,
      logo_url: '',
    });

    await updateFavicon();
    success.value = true;
    setTimeout(() => success.value = false, 3000);
  } catch (err: any) {
    console.error('Error removing logo:', err);
    error.value = err.message || 'Erreur lors de la suppression du logo';
  }
};

const handleSubmit = async () => {
  error.value = '';
  success.value = false;
  saving.value = true;

  try {
    let logoUrl = formData.value.logo_url;

    if (selectedFile.value) {
      if (logoUrl) {
        await companyService.deleteLogo(logoUrl);
      }
      logoUrl = await companyService.uploadLogo(selectedFile.value);
    }

    await companyService.updateSettings({
      ...formData.value,
      logo_url: logoUrl,
    });

    await loadSettings();
    await updateFavicon();
    selectedFile.value = null;
    previewUrl.value = '';
    success.value = true;
    setTimeout(() => success.value = false, 3000);
  } catch (err: any) {
    console.error('Error saving settings:', err);
    error.value = err.message || 'Erreur lors de l\'enregistrement';
  } finally {
    saving.value = false;
  }
};

const openWhatsApp = () => {
  if (!formData.value.phone) {
    return;
  }

  const cleanPhone = formData.value.phone.replace(/\s+/g, '');
  const url = `https://wa.me/${cleanPhone}`;
  window.open(url, '_blank');
};

onMounted(() => {
  loadSettings();
});
</script>
