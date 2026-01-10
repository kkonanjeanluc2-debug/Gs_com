<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { paymentConfigService, PaymentProvider, PaymentConfiguration } from '../services/payment-config.service';
import Icon from './Icon.vue';

const configurations = ref<PaymentConfiguration[]>([]);
const loading = ref(true);
const saving = ref(false);
const editingProvider = ref<PaymentProvider | null>(null);

const formData = ref({
  is_enabled: false,
  api_key: '',
  api_secret: '',
  merchant_id: '',
  test_mode: true
});

const providers: PaymentProvider[] = ['wave', 'orange_money', 'mtn_money', 'moov_money', 'paydunya'];

onMounted(async () => {
  await loadConfigurations();
});

const loadConfigurations = async () => {
  try {
    loading.value = true;
    configurations.value = await paymentConfigService.getAllConfigurations();
  } catch (error) {
    console.error('Error loading configurations:', error);
    alert('Erreur lors du chargement des configurations');
  } finally {
    loading.value = false;
  }
};

const getConfig = (provider: PaymentProvider): PaymentConfiguration | undefined => {
  return configurations.value.find(c => c.provider === provider);
};

const openEditModal = (provider: PaymentProvider) => {
  const config = getConfig(provider);

  formData.value = {
    is_enabled: config?.is_enabled || false,
    api_key: config?.api_key || '',
    api_secret: config?.api_secret || '',
    merchant_id: config?.merchant_id || '',
    test_mode: config?.test_mode !== false
  };

  editingProvider.value = provider;
};

const closeEditModal = () => {
  editingProvider.value = null;
  formData.value = {
    is_enabled: false,
    api_key: '',
    api_secret: '',
    merchant_id: '',
    test_mode: true
  };
};

const saveConfiguration = async () => {
  if (!editingProvider.value) return;

  try {
    saving.value = true;

    await paymentConfigService.createOrUpdateConfiguration({
      provider: editingProvider.value,
      ...formData.value
    });

    alert('Configuration enregistrée avec succès');
    await loadConfigurations();
    closeEditModal();
  } catch (error) {
    console.error('Error saving configuration:', error);
    alert('Erreur lors de l\'enregistrement de la configuration');
  } finally {
    saving.value = false;
  }
};

const toggleProvider = async (provider: PaymentProvider) => {
  const config = getConfig(provider);

  if (!config) {
    openEditModal(provider);
    return;
  }

  try {
    await paymentConfigService.createOrUpdateConfiguration({
      provider,
      is_enabled: !config.is_enabled,
      api_key: config.api_key,
      api_secret: config.api_secret,
      merchant_id: config.merchant_id,
      test_mode: config.test_mode
    });

    await loadConfigurations();
  } catch (error) {
    console.error('Error toggling provider:', error);
    alert('Erreur lors de la modification');
  }
};

const getProviderIcon = (provider: PaymentProvider): string => {
  const icons: Record<PaymentProvider, string> = {
    'wave': 'credit-card',
    'orange_money': 'smartphone',
    'mtn_money': 'smartphone',
    'moov_money': 'smartphone',
    'paydunya': 'credit-card'
  };
  return icons[provider];
};

const getProviderColor = (provider: PaymentProvider): string => {
  const colors: Record<PaymentProvider, string> = {
    'wave': 'bg-blue-500',
    'orange_money': 'bg-orange-500',
    'mtn_money': 'bg-yellow-500',
    'moov_money': 'bg-green-500',
    'paydunya': 'bg-indigo-600'
  };
  return colors[provider];
};
</script>

<template>
  <div class="bg-white rounded-lg shadow-md p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">Moyens de Paiement</h2>
        <p class="text-gray-600 mt-1">Configurez les méthodes de paiement disponibles pour vos clients</p>
      </div>
    </div>

    <div v-if="loading" class="text-center py-8">
      <p class="text-gray-600">Chargement...</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="provider in providers"
        :key="provider"
        class="border rounded-lg p-4 hover:shadow-md transition-shadow"
      >
        <div class="flex items-start justify-between">
          <div class="flex items-start gap-3 flex-1">
            <div :class="['w-12 h-12 rounded-lg flex items-center justify-center text-white', getProviderColor(provider)]">
              <Icon :name="getProviderIcon(provider)" class="w-6 h-6" />
            </div>

            <div class="flex-1">
              <h3 class="font-semibold text-gray-800">
                {{ paymentConfigService.getProviderLabel(provider) }}
              </h3>
              <p class="text-sm text-gray-600 mt-1">
                {{ paymentConfigService.getProviderDescription(provider) }}
              </p>

              <div v-if="getConfig(provider)" class="mt-2 space-y-1">
                <p class="text-xs text-gray-500">
                  <span class="font-medium">Mode:</span>
                  {{ getConfig(provider)?.test_mode ? 'Test' : 'Production' }}
                </p>
                <p v-if="getConfig(provider)?.merchant_id" class="text-xs text-gray-500">
                  <span class="font-medium">Merchant ID:</span>
                  {{ getConfig(provider)?.merchant_id }}
                </p>
              </div>
            </div>
          </div>

          <div class="flex flex-col gap-2 ml-4">
            <button
              @click="toggleProvider(provider)"
              :class="[
                'relative inline-flex h-6 w-11 items-center rounded-full transition-colors',
                getConfig(provider)?.is_enabled ? 'bg-green-500' : 'bg-gray-300'
              ]"
            >
              <span
                :class="[
                  'inline-block h-4 w-4 transform rounded-full bg-white transition-transform',
                  getConfig(provider)?.is_enabled ? 'translate-x-6' : 'translate-x-1'
                ]"
              />
            </button>

            <button
              @click="openEditModal(provider)"
              class="text-blue-600 hover:text-blue-800 text-sm font-medium"
            >
              {{ getConfig(provider) ? 'Modifier' : 'Configurer' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="editingProvider" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex justify-between items-center">
          <h3 class="text-xl font-bold text-gray-800">
            Configurer {{ paymentConfigService.getProviderLabel(editingProvider) }}
          </h3>
          <button
            @click="closeEditModal"
            class="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <Icon name="x" class="w-6 h-6" />
          </button>
        </div>

        <div class="p-6 space-y-4">
          <div class="flex items-center gap-3 p-4 bg-blue-50 rounded-lg">
            <Icon name="info" class="w-5 h-5 text-blue-600" />
            <p class="text-sm text-blue-800">
              Obtenez vos clés API depuis le tableau de bord {{ paymentConfigService.getProviderLabel(editingProvider) }}
            </p>
          </div>

          <div>
            <label class="flex items-center gap-2">
              <input
                v-model="formData.is_enabled"
                type="checkbox"
                class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span class="text-sm font-medium text-gray-700">Activer ce moyen de paiement</span>
            </label>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Clé API *
            </label>
            <input
              v-model="formData.api_key"
              type="text"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Entrez votre clé API"
              required
            />
          </div>

          <div v-if="editingProvider !== 'wave'">
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Clé Secrète
            </label>
            <input
              v-model="formData.api_secret"
              type="password"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Entrez votre clé secrète"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Merchant ID
            </label>
            <input
              v-model="formData.merchant_id"
              type="text"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Entrez votre Merchant ID"
            />
          </div>

          <div>
            <label class="flex items-center gap-2">
              <input
                v-model="formData.test_mode"
                type="checkbox"
                class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span class="text-sm font-medium text-gray-700">Mode test (Sandbox)</span>
            </label>
            <p class="text-xs text-gray-500 mt-1 ml-6">
              Activez pour tester sans effectuer de vrais paiements
            </p>
          </div>
        </div>

        <div class="sticky bottom-0 bg-gray-50 px-6 py-4 flex justify-end gap-3 border-t border-gray-200">
          <button
            @click="closeEditModal"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-100"
          >
            Annuler
          </button>
          <button
            @click="saveConfiguration"
            :disabled="saving || !formData.api_key"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ saving ? 'Enregistrement...' : 'Enregistrer' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
