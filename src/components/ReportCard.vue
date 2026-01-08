<script setup lang="ts">
import { computed } from 'vue';
import type { Report } from '../services/storage';
import Icon from './Icon.vue';

const props = defineProps<{
  report: Report;
}>();

defineEmits<{
  edit: [report: Report];
  duplicate: [report: Report];
  print: [report: Report];
  sendWhatsApp: [report: Report];
  delete: [report: Report];
}>();

const formattedDate = computed(() => {
  return new Date(props.report.date).toLocaleDateString('fr-FR', {
    weekday: 'short',
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  });
});

const formattedCA = computed(() => {
  return props.report.ca.toLocaleString('fr-FR');
});

const statusColor = computed(() => {
  switch (props.report.status) {
    case 'envoye':
      return 'bg-green-100 text-green-800';
    case 'brouillon':
      return 'bg-yellow-100 text-yellow-800';
    case 'archive':
      return 'bg-gray-100 text-gray-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
});

const statusLabel = computed(() => {
  switch (props.report.status) {
    case 'envoye':
      return 'Envoyé';
    case 'brouillon':
      return 'Brouillon';
    case 'archive':
      return 'Archivé';
    default:
      return props.report.status;
  }
});
</script>

<template>
  <div class="card hover:shadow-xl transition-all duration-200 border border-gray-100">
    <div class="flex flex-col gap-4">
      <div class="flex justify-between items-start">
        <div class="flex items-start gap-3">
          <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-md flex-shrink-0">
            <Icon name="document" class="w-5 h-5 text-white" />
          </div>
          <div>
            <h3 class="text-lg font-bold text-gray-800">{{ formattedDate }}</h3>
            <span
              class="inline-block px-3 py-1 rounded-full text-xs font-semibold mt-1"
              :class="statusColor"
            >
              {{ statusLabel }}
            </span>
          </div>
        </div>
      </div>

      <div class="p-3 bg-gradient-to-br from-emerald-50 to-emerald-100 rounded-lg border border-emerald-200">
        <div class="flex items-center gap-2 mb-1">
          <Icon name="money-bag" class="w-5 h-5 text-emerald-600" />
          <p class="text-sm text-emerald-700 font-medium">Chiffre d'affaires</p>
        </div>
        <p class="text-2xl font-bold text-emerald-800">{{ formattedCA }} <span class="text-base">FCFA</span></p>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div class="p-3 bg-blue-50 rounded-lg border border-blue-200">
          <div class="flex items-center gap-2 mb-1">
            <Icon name="users" class="w-4 h-4 text-blue-600" />
            <p class="text-sm text-blue-700 font-medium">Prospects</p>
          </div>
          <p class="text-xl font-bold text-blue-800">{{ report.prospects }}</p>
          <div class="flex items-center gap-1 mt-1">
            <Icon name="user" class="w-3 h-3 text-blue-600" />
            <p class="text-xs text-blue-600">{{ report.nouveaux_prospects }} nouveaux</p>
          </div>
        </div>
        <div class="p-3 bg-amber-50 rounded-lg border border-amber-200">
          <div class="flex items-center gap-2 mb-1">
            <Icon name="shopping-cart" class="w-4 h-4 text-amber-600" />
            <p class="text-sm text-amber-700 font-medium">Commandes</p>
          </div>
          <p class="text-xl font-bold text-amber-800">{{ report.commandes }}</p>
        </div>
      </div>

      <div v-if="report.comm_prospects || report.comm_commandes" class="text-sm text-gray-700 space-y-3 p-3 bg-gray-50 rounded-lg">
        <div v-if="report.comm_prospects">
          <div class="flex items-center gap-2 mb-1">
            <Icon name="users" class="w-4 h-4 text-gray-500" />
            <p class="font-semibold text-gray-700">Prospects:</p>
          </div>
          <p class="line-clamp-2 text-gray-600">{{ report.comm_prospects }}</p>
        </div>
        <div v-if="report.comm_commandes">
          <div class="flex items-center gap-2 mb-1">
            <Icon name="shopping-cart" class="w-4 h-4 text-gray-500" />
            <p class="font-semibold text-gray-700">Commandes:</p>
          </div>
          <p class="line-clamp-2 text-gray-600">{{ report.comm_commandes }}</p>
        </div>
      </div>

      <div v-if="report.commercial" class="flex items-center gap-2 py-2 border-t border-gray-200">
        <Icon name="briefcase" class="w-4 h-4 text-gray-400" />
        <div>
          <p class="text-xs text-gray-500">Commercial:</p>
          <p class="text-sm font-medium text-gray-700">{{ report.commercial.full_name }}</p>
        </div>
      </div>

      <div class="grid grid-cols-2 sm:grid-cols-5 gap-2 pt-3 border-t border-gray-100">
        <button
          @click="$emit('edit', props.report)"
          class="px-3 py-2 text-sm bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors font-medium inline-flex items-center justify-center gap-1.5"
        >
          <Icon name="edit" class="w-4 h-4" />
          <span>Modifier</span>
        </button>
        <button
          @click="$emit('duplicate', props.report)"
          class="px-3 py-2 text-sm bg-gray-50 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors font-medium inline-flex items-center justify-center gap-1.5"
        >
          <Icon name="document" class="w-4 h-4" />
          <span>Dupliquer</span>
        </button>
        <button
          @click="$emit('print', props.report)"
          class="px-3 py-2 text-sm bg-indigo-50 text-indigo-700 rounded-lg hover:bg-indigo-100 transition-colors font-medium inline-flex items-center justify-center gap-1.5"
        >
          <Icon name="document" class="w-4 h-4" />
          <span>Imprimer</span>
        </button>
        <button
          @click="$emit('sendWhatsApp', props.report)"
          class="px-3 py-2 text-sm bg-emerald-50 text-emerald-700 rounded-lg hover:bg-emerald-100 transition-colors font-medium inline-flex items-center justify-center gap-1.5"
        >
          <Icon name="phone" class="w-4 h-4" />
          <span>WhatsApp</span>
        </button>
        <button
          @click="$emit('delete', props.report)"
          class="px-3 py-2 text-sm bg-red-50 text-red-700 rounded-lg hover:bg-red-100 transition-colors font-medium inline-flex items-center justify-center gap-1.5"
        >
          <Icon name="trash" class="w-4 h-4" />
          <span>Supprimer</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
