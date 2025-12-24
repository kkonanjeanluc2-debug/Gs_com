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

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Nom de l'entreprise *
            </label>
            <input
              v-model="formData.company_name"
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
            <input
              v-model="formData.phone"
              type="tel"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="+33 1 23 45 67 89"
            />
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

const loading = ref(true);
const saving = ref(false);
const error = ref('');
const success = ref(false);
const selectedFile = ref<File | null>(null);
const previewUrl = ref('');

const formData = ref<CompanySettings>({
  company_name: '',
  email: '',
  phone: '',
  address: '',
  logo_url: '',
  website: '',
  tax_id: '',
  rccm: '',
  ncc: '',
});

const loadSettings = async () => {
  try {
    loading.value = true;
    const settings = await companyService.getSettings();
    if (settings) {
      formData.value = { ...settings };
    }
  } catch (err: any) {
    console.error('Error loading settings:', err);
    error.value = err.message || 'Erreur lors du chargement';
  } finally {
    loading.value = false;
  }
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

onMounted(() => {
  loadSettings();
});
</script>
