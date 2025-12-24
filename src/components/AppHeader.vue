<script setup lang="ts">
import { computed } from 'vue';

const emit = defineEmits<{
  newReport: [];
  exportAll: [];
}>();

const currentDate = computed(() => {
  return new Date().toLocaleDateString('fr-FR', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
});
</script>

<template>
  <header class="sticky top-0 z-50 bg-gradient-to-r from-primary to-blue-600 text-white shadow-lg">
    <div class="container mx-auto px-4 py-4">
      <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div class="flex-1">
          <h1 class="text-2xl md:text-3xl font-bold">Gestion commerciale</h1>
          <p class="text-blue-100 text-sm mt-1">{{ currentDate }}</p>
        </div>

        <div class="flex flex-wrap gap-2 md:gap-3">
          <button
            @click="emit('newReport')"
            class="btn-secondary flex-1 md:flex-none text-sm md:text-base"
          >
            ➕ Nouveau rapport
          </button>
          <button
            @click="emit('exportAll')"
            class="bg-white text-primary px-4 md:px-6 py-3 rounded-lg font-semibold transition-all duration-200 hover:bg-blue-50 active:scale-95 flex-1 md:flex-none text-sm md:text-base"
            style="min-height: 48px;"
          >
            📤 Exporter tous
          </button>
        </div>
      </div>
    </div>
  </header>
</template>
