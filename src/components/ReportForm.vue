<script setup lang="ts">
import { ref, watch } from 'vue';
import type { Report } from '../services/storage';
import Icon from './Icon.vue';

const props = defineProps<{
  initialData?: Report;
  isOpen: boolean;
}>();

const emit = defineEmits<{
  save: [data: Omit<Report, 'id' | 'createdAt' | 'updatedAt'>];
  sendWhatsApp: [data: Omit<Report, 'id' | 'createdAt' | 'updatedAt'>];
  close: [];
}>();

const formData = ref<{
  date: string;
  prospects: number;
  nouveaux_prospects: number;
  comm_prospects: string;
  commandes: number;
  ca: number;
  comm_commandes: string;
  status: 'envoye' | 'brouillon' | 'archive';
}>({
  date: new Date().toISOString().split('T')[0],
  prospects: 0,
  nouveaux_prospects: 0,
  comm_prospects: '',
  commandes: 0,
  ca: 0,
  comm_commandes: '',
  status: 'brouillon'
});

const errors = ref<Record<string, string>>({});

watch(() => props.initialData, (data) => {
  if (data) {
    formData.value = {
      date: data.date,
      prospects: data.prospects,
      nouveaux_prospects: data.nouveaux_prospects,
      comm_prospects: data.comm_prospects,
      commandes: data.commandes,
      ca: data.ca,
      comm_commandes: data.comm_commandes,
      status: data.status
    };
  }
}, { immediate: true });

const validate = (): boolean => {
  errors.value = {};

  if (formData.value.prospects < 0) {
    errors.value.prospects = 'Le nombre de prospects ne peut pas être négatif';
  }

  if (formData.value.nouveaux_prospects < 0) {
    errors.value.nouveaux_prospects = 'Le nombre de nouveaux prospects ne peut pas être négatif';
  }

  if (formData.value.nouveaux_prospects > formData.value.prospects) {
    errors.value.nouveaux_prospects = 'Ne peut pas dépasser le nombre total de prospects';
  }

  if (formData.value.commandes < 0) {
    errors.value.commandes = 'Le nombre de commandes ne peut pas être négatif';
  }

  if (formData.value.ca < 0) {
    errors.value.ca = 'Le CA ne peut pas être négatif';
  }

  return Object.keys(errors.value).length === 0;
};

const handleSave = () => {
  if (!validate()) return;
  emit('save', { ...formData.value });
};

const handleSendWhatsApp = () => {
  if (!validate()) return;
  emit('sendWhatsApp', { ...formData.value, status: 'envoye' });
};
</script>

<template>
  <div v-if="isOpen" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
      <div class="flex justify-between items-center mb-6">
        <h2 class="text-xl md:text-2xl font-bold text-gray-800">
          {{ initialData ? 'Modifier le rapport' : 'Nouveau rapport' }}
        </h2>
        <button
          @click="emit('close')"
          class="text-gray-400 hover:text-gray-600 transition-colors"
          aria-label="Fermer"
        >
          <Icon name="x" class="w-6 h-6" />
        </button>
      </div>

      <form @submit.prevent="handleSave" class="space-y-5">
      <div>
        <label class="label inline-flex items-center gap-2">
          <Icon name="clock" class="w-4 h-4 text-gray-500" />
          <span>Date</span>
        </label>
        <input
          v-model="formData.date"
          type="date"
          class="input-field"
          required
        />
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="label inline-flex items-center gap-2">
            <Icon name="users" class="w-4 h-4 text-gray-500" />
            <span>Prospects rencontrés</span>
          </label>
          <input
            v-model.number="formData.prospects"
            type="number"
            min="0"
            class="input-field"
            :class="{ 'border-red-500': errors.prospects }"
            required
          />
          <p v-if="errors.prospects" class="text-red-500 text-sm mt-1">{{ errors.prospects }}</p>
        </div>

        <div>
          <label class="label inline-flex items-center gap-2">
            <Icon name="user" class="w-4 h-4 text-gray-500" />
            <span>Nouveaux prospects</span>
          </label>
          <input
            v-model.number="formData.nouveaux_prospects"
            type="number"
            min="0"
            class="input-field"
            :class="{ 'border-red-500': errors.nouveaux_prospects }"
            required
          />
          <p v-if="errors.nouveaux_prospects" class="text-red-500 text-sm mt-1">{{ errors.nouveaux_prospects }}</p>
        </div>
      </div>

      <div>
        <label class="label inline-flex items-center gap-2">
          <Icon name="document" class="w-4 h-4 text-gray-500" />
          <span>Commentaires prospects</span>
        </label>
        <textarea
          v-model="formData.comm_prospects"
          class="textarea-field"
          rows="3"
          placeholder="Décrivez vos rencontres avec les prospects..."
        ></textarea>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="label inline-flex items-center gap-2">
            <Icon name="shopping-cart" class="w-4 h-4 text-gray-500" />
            <span>Commandes du jour</span>
          </label>
          <input
            v-model.number="formData.commandes"
            type="number"
            min="0"
            class="input-field"
            :class="{ 'border-red-500': errors.commandes }"
            required
          />
          <p v-if="errors.commandes" class="text-red-500 text-sm mt-1">{{ errors.commandes }}</p>
        </div>

        <div>
          <label class="label inline-flex items-center gap-2">
            <Icon name="money-bag" class="w-4 h-4 text-gray-500" />
            <span>CA réalisé (FCFA)</span>
          </label>
          <input
            v-model.number="formData.ca"
            type="number"
            min="0"
            step="1000"
            class="input-field"
            :class="{ 'border-red-500': errors.ca }"
            required
          />
          <p v-if="errors.ca" class="text-red-500 text-sm mt-1">{{ errors.ca }}</p>
        </div>
      </div>

      <div>
        <label class="label inline-flex items-center gap-2">
          <Icon name="document" class="w-4 h-4 text-gray-500" />
          <span>Commentaires commandes</span>
        </label>
        <textarea
          v-model="formData.comm_commandes"
          class="textarea-field"
          rows="3"
          placeholder="Décrivez les commandes réalisées..."
        ></textarea>
      </div>

      <div class="flex flex-col sm:flex-row gap-3 pt-4 border-t">
        <button
          type="submit"
          class="btn-primary flex-1 inline-flex items-center justify-center gap-2"
        >
          <Icon name="check-circle" class="w-5 h-5" />
          <span>Enregistrer</span>
        </button>
        <button
          type="button"
          @click="handleSendWhatsApp"
          class="bg-emerald-500 text-white px-6 py-3 rounded-lg font-semibold transition-all duration-200 hover:bg-emerald-600 active:scale-95 shadow-md flex-1 inline-flex items-center justify-center gap-2"
        >
          <Icon name="phone" class="w-5 h-5" />
          <span>Envoyer WhatsApp</span>
        </button>
      </div>
    </form>
    </div>
  </div>
</template>
