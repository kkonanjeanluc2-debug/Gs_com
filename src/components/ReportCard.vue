<script setup lang="ts">
import { computed } from 'vue';
import type { Report } from '../services/storage';

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
  <div class="card">
    <div class="flex flex-col gap-4">
      <div class="flex justify-between items-start">
        <div>
          <h3 class="text-lg font-bold text-secondary">{{ formattedDate }}</h3>
          <span
            class="inline-block px-3 py-1 rounded-full text-xs font-semibold mt-2"
            :class="statusColor"
          >
            {{ statusLabel }}
          </span>
        </div>
        <div class="text-right">
          <p class="text-2xl font-bold text-primary">{{ formattedCA }} FCFA</p>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-4 py-4 border-t border-b border-gray-200">
        <div>
          <p class="text-sm text-gray-600">📞 Prospects</p>
          <p class="text-xl font-semibold">{{ report.prospects }}</p>
          <p class="text-xs text-gray-500">dont {{ report.nouveaux_prospects }} nouveaux</p>
        </div>
        <div>
          <p class="text-sm text-gray-600">🛒 Commandes</p>
          <p class="text-xl font-semibold">{{ report.commandes }}</p>
        </div>
      </div>

      <div v-if="report.comm_prospects || report.comm_commandes" class="text-sm text-gray-700 space-y-2">
        <div v-if="report.comm_prospects">
          <p class="font-semibold text-gray-600">📝 Prospects:</p>
          <p class="line-clamp-2">{{ report.comm_prospects }}</p>
        </div>
        <div v-if="report.comm_commandes">
          <p class="font-semibold text-gray-600">📝 Commandes:</p>
          <p class="line-clamp-2">{{ report.comm_commandes }}</p>
        </div>
      </div>

      <div v-if="report.commercial" class="py-2 border-t border-gray-200">
        <p class="text-xs text-gray-500">Commercial:</p>
        <p class="text-sm font-medium text-gray-700">{{ report.commercial.full_name }}</p>
      </div>

      <div class="grid grid-cols-2 sm:grid-cols-5 gap-2 pt-2">
        <button
          @click="$emit('edit', props.report)"
          class="px-3 py-2 text-sm bg-blue-50 text-primary rounded-lg hover:bg-blue-100 transition-colors font-medium"
          style="min-height: 44px;"
        >
          ✏️ Modifier
        </button>
        <button
          @click="$emit('duplicate', props.report)"
          class="px-3 py-2 text-sm bg-gray-50 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors font-medium"
          style="min-height: 44px;"
        >
          📋 Dupliquer
        </button>
        <button
          @click="$emit('print', props.report)"
          class="px-3 py-2 text-sm bg-purple-50 text-purple-700 rounded-lg hover:bg-purple-100 transition-colors font-medium"
          style="min-height: 44px;"
        >
          🖨️ Imprimer
        </button>
        <button
          @click="$emit('sendWhatsApp', props.report)"
          class="px-3 py-2 text-sm bg-green-50 text-green-700 rounded-lg hover:bg-green-100 transition-colors font-medium"
          style="min-height: 44px;"
        >
          📱 WhatsApp
        </button>
        <button
          @click="$emit('delete', props.report)"
          class="px-3 py-2 text-sm bg-red-50 text-red-700 rounded-lg hover:bg-red-100 transition-colors font-medium"
          style="min-height: 44px;"
        >
          🗑️ Supprimer
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
