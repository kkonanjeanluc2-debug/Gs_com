<script setup lang="ts">
import { ref, computed } from 'vue';
import ReportCard from './ReportCard.vue';
import type { Report } from '../services/storage';
import Icon from './Icon.vue';

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
      <div class="flex items-center gap-3">
        <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg">
          <Icon name="document" class="w-6 h-6 text-white" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-gray-800">Historique des Rapports</h2>
          <p class="text-sm text-gray-500">Consultez vos rapports d'activité</p>
        </div>
      </div>

      <div class="flex gap-2 w-full sm:w-auto">
        <button
          @click="filter = 'all'"
          :class="[
            'flex-1 sm:flex-none px-4 py-2.5 rounded-lg font-medium transition-all',
            filter === 'all'
              ? 'bg-primary text-white shadow-md'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
        >
          Tout
        </button>
        <button
          @click="filter = 'week'"
          :class="[
            'flex-1 sm:flex-none px-4 py-2.5 rounded-lg font-medium transition-all',
            filter === 'week'
              ? 'bg-primary text-white shadow-md'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
        >
          Cette semaine
        </button>
        <button
          @click="filter = 'today'"
          :class="[
            'flex-1 sm:flex-none px-4 py-2.5 rounded-lg font-medium transition-all',
            filter === 'today'
              ? 'bg-primary text-white shadow-md'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
        >
          Aujourd'hui
        </button>
      </div>
    </div>

    <div v-if="filteredReports.length > 0" class="card bg-gradient-to-br from-blue-50 via-white to-blue-50 border border-blue-100">
      <div class="flex items-center gap-2 mb-4">
        <Icon name="chart-bar" class="w-5 h-5 text-blue-600" />
        <h3 class="text-lg font-bold text-gray-800">Statistiques</h3>
      </div>
      <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
        <div class="p-3 bg-white rounded-lg border border-gray-200">
          <div class="flex items-center gap-2 mb-1">
            <Icon name="document" class="w-4 h-4 text-gray-400" />
            <p class="text-sm text-gray-600 font-medium">Rapports</p>
          </div>
          <p class="text-2xl font-bold text-gray-800">{{ stats.total }}</p>
        </div>
        <div class="p-3 bg-white rounded-lg border border-gray-200">
          <div class="flex items-center gap-2 mb-1">
            <Icon name="users" class="w-4 h-4 text-gray-400" />
            <p class="text-sm text-gray-600 font-medium">Prospects</p>
          </div>
          <p class="text-2xl font-bold text-gray-800">{{ stats.prospects }}</p>
        </div>
        <div class="p-3 bg-white rounded-lg border border-gray-200">
          <div class="flex items-center gap-2 mb-1">
            <Icon name="user" class="w-4 h-4 text-gray-400" />
            <p class="text-sm text-gray-600 font-medium">Nouveaux</p>
          </div>
          <p class="text-2xl font-bold text-gray-800">{{ stats.nouveaux }}</p>
        </div>
        <div class="p-3 bg-white rounded-lg border border-gray-200">
          <div class="flex items-center gap-2 mb-1">
            <Icon name="shopping-cart" class="w-4 h-4 text-gray-400" />
            <p class="text-sm text-gray-600 font-medium">Commandes</p>
          </div>
          <p class="text-2xl font-bold text-gray-800">{{ stats.commandes }}</p>
        </div>
        <div class="col-span-2 md:col-span-1 p-3 bg-gradient-to-br from-emerald-50 to-emerald-100 rounded-lg border border-emerald-200">
          <div class="flex items-center gap-2 mb-1">
            <Icon name="money-bag" class="w-4 h-4 text-emerald-600" />
            <p class="text-sm text-emerald-700 font-medium">CA Total</p>
          </div>
          <p class="text-xl md:text-2xl font-bold text-emerald-800">{{ stats.ca.toLocaleString('fr-FR') }} <span class="text-sm">FCFA</span></p>
        </div>
      </div>
    </div>

    <div v-if="filteredReports.length === 0" class="text-center py-16">
      <div class="w-20 h-20 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center">
        <Icon name="document" class="w-10 h-10 text-gray-400" />
      </div>
      <p class="text-xl font-semibold text-gray-700 mb-2">Aucun rapport pour cette période</p>
      <p class="text-gray-500">Créez votre premier rapport pour commencer</p>
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
