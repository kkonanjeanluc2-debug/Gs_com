<script setup lang="ts">
import { ref, computed } from 'vue';
import ReportCard from './ReportCard.vue';
import type { Report } from '../services/storage';

const props = defineProps<{
  reports: Report[];
}>();

defineEmits<{
  edit: [report: Report];
  duplicate: [report: Report];
  print: [report: Report];
  sendWhatsApp: [report: Report];
  delete: [report: Report];
}>();

type FilterType = 'all' | 'today' | 'week';
const filter = ref<FilterType>('all');

const today = new Date();
today.setHours(0, 0, 0, 0);

const weekAgo = new Date(today);
weekAgo.setDate(today.getDate() - 7);

const filteredReports = computed(() => {
  if (filter.value === 'all') {
    return props.reports;
  }

  if (filter.value === 'today') {
    const todayStr = today.toISOString().split('T')[0];
    return props.reports.filter(report => report.date === todayStr);
  }

  if (filter.value === 'week') {
    return props.reports.filter(report => {
      const reportDate = new Date(report.date);
      return reportDate >= weekAgo;
    });
  }

  return props.reports;
});

const stats = computed(() => {
  const reports = filteredReports.value;
  return {
    total: reports.length,
    prospects: reports.reduce((sum, r) => sum + r.prospects, 0),
    nouveaux: reports.reduce((sum, r) => sum + r.nouveaux_prospects, 0),
    commandes: reports.reduce((sum, r) => sum + r.commandes, 0),
    ca: reports.reduce((sum, r) => sum + r.ca, 0),
  };
});
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <h2 class="text-2xl font-bold text-secondary">Historique des Rapports</h2>

      <div class="flex gap-2 w-full sm:w-auto">
        <button
          @click="filter = 'all'"
          :class="[
            'flex-1 sm:flex-none px-4 py-2 rounded-lg font-medium transition-all',
            filter === 'all'
              ? 'bg-primary text-white shadow-md'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
          style="min-height: 44px;"
        >
          Tout
        </button>
        <button
          @click="filter = 'week'"
          :class="[
            'flex-1 sm:flex-none px-4 py-2 rounded-lg font-medium transition-all',
            filter === 'week'
              ? 'bg-primary text-white shadow-md'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
          style="min-height: 44px;"
        >
          Cette semaine
        </button>
        <button
          @click="filter = 'today'"
          :class="[
            'flex-1 sm:flex-none px-4 py-2 rounded-lg font-medium transition-all',
            filter === 'today'
              ? 'bg-primary text-white shadow-md'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
          style="min-height: 44px;"
        >
          Aujourd'hui
        </button>
      </div>
    </div>

    <div v-if="filteredReports.length > 0" class="card bg-gradient-to-r from-blue-50 to-blue-100">
      <h3 class="text-lg font-bold text-primary mb-4">📊 Statistiques</h3>
      <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
        <div>
          <p class="text-sm text-gray-600">Rapports</p>
          <p class="text-2xl font-bold text-secondary">{{ stats.total }}</p>
        </div>
        <div>
          <p class="text-sm text-gray-600">Prospects</p>
          <p class="text-2xl font-bold text-secondary">{{ stats.prospects }}</p>
        </div>
        <div>
          <p class="text-sm text-gray-600">Nouveaux</p>
          <p class="text-2xl font-bold text-secondary">{{ stats.nouveaux }}</p>
        </div>
        <div>
          <p class="text-sm text-gray-600">Commandes</p>
          <p class="text-2xl font-bold text-secondary">{{ stats.commandes }}</p>
        </div>
        <div class="col-span-2 md:col-span-1">
          <p class="text-sm text-gray-600">CA Total</p>
          <p class="text-xl md:text-2xl font-bold text-primary">{{ stats.ca.toLocaleString('fr-FR') }} FCFA</p>
        </div>
      </div>
    </div>

    <div v-if="filteredReports.length === 0" class="text-center py-12">
      <div class="text-6xl mb-4">📋</div>
      <p class="text-xl text-gray-600">Aucun rapport pour cette période</p>
      <p class="text-gray-500 mt-2">Créez votre premier rapport pour commencer</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <ReportCard
        v-for="report in filteredReports"
        :key="report.id"
        :report="report"
        @edit="$emit('edit', report)"
        @duplicate="$emit('duplicate', report)"
        @print="$emit('print', report)"
        @sendWhatsApp="$emit('sendWhatsApp', report)"
        @delete="$emit('delete', report)"
      />
    </div>
  </div>
</template>
