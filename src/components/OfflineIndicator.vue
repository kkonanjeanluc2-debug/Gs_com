<template>
  <div class="fixed top-4 right-4 z-50">
    <div
      v-if="!networkStatus.isOnline"
      class="bg-yellow-500 text-white px-4 py-3 rounded-lg shadow-lg flex items-center gap-3 animate-pulse"
    >
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 5.636a9 9 0 010 12.728m0 0l-2.829-2.829m2.829 2.829L21 21M15.536 8.464a5 5 0 010 7.072m0 0l-2.829-2.829m-4.243 2.829a4.978 4.978 0 01-1.414-2.83m-1.414 5.658a9 9 0 01-2.167-9.238m7.824 2.167a1 1 0 111.414 1.414m-1.414-1.414L3 3m8.293 8.293l1.414 1.414" />
      </svg>
      <div>
        <p class="font-semibold text-sm">Mode Hors ligne</p>
        <p class="text-xs">{{ syncStatus.pendingCount }} opération(s) en attente</p>
      </div>
    </div>

    <div
      v-else-if="syncStatus.isSyncing"
      class="bg-blue-500 text-white px-4 py-3 rounded-lg shadow-lg flex items-center gap-3"
    >
      <svg class="w-5 h-5 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
      </svg>
      <div>
        <p class="font-semibold text-sm">Synchronisation en cours...</p>
        <p class="text-xs">{{ syncStatus.pendingCount }} opération(s) restante(s)</p>
      </div>
    </div>

    <transition
      enter-active-class="transition ease-out duration-300"
      enter-from-class="opacity-0 transform scale-95"
      enter-to-class="opacity-100 transform scale-100"
      leave-active-class="transition ease-in duration-200"
      leave-from-class="opacity-100 transform scale-100"
      leave-to-class="opacity-0 transform scale-95"
    >
      <div
        v-if="showSyncSuccess"
        class="bg-green-500 text-white px-4 py-3 rounded-lg shadow-lg flex items-center gap-3"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        <div>
          <p class="font-semibold text-sm">Synchronisation réussie</p>
          <p class="text-xs">Toutes les données sont à jour</p>
        </div>
      </div>
    </transition>

    <div
      v-if="syncStatus.error"
      class="mt-2 bg-red-500 text-white px-4 py-3 rounded-lg shadow-lg flex items-center gap-3"
    >
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <div class="flex-1">
        <p class="font-semibold text-sm">Erreur de synchronisation</p>
        <p class="text-xs">{{ syncStatus.error }}</p>
      </div>
      <button
        @click="retrySync"
        class="text-white hover:text-gray-200 text-xs underline"
      >
        Réessayer
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import { networkService, type NetworkStatus } from '../services/network.service';
import { syncService, type SyncStatus } from '../services/sync.service';

const networkStatus = ref<NetworkStatus>({
  isOnline: true,
  wasOffline: false,
});

const syncStatus = ref<SyncStatus>({
  isSyncing: false,
  lastSyncTime: null,
  pendingCount: 0,
  error: null,
});

const showSyncSuccess = ref(false);
let successTimeout: number | null = null;

let unsubscribeNetwork: (() => void) | null = null;
let unsubscribeSync: (() => void) | null = null;

const retrySync = async () => {
  if (networkStatus.value.isOnline) {
    await syncService.syncAll();
  }
};

onMounted(() => {
  unsubscribeNetwork = networkService.onStatusChange((status) => {
    networkStatus.value = status;

    if (status.isOnline && status.wasOffline) {
      syncService.syncAll();
      networkService.resetWasOffline();
    }
  });

  unsubscribeSync = syncService.onStatusChange((status) => {
    const wasSyncing = syncStatus.value.isSyncing;
    syncStatus.value = status;

    if (wasSyncing && !status.isSyncing && !status.error && status.pendingCount === 0) {
      showSyncSuccess.value = true;
      if (successTimeout) clearTimeout(successTimeout);
      successTimeout = window.setTimeout(() => {
        showSyncSuccess.value = false;
      }, 3000);
    }
  });

  syncService.startAutoSync(30000);
});

onUnmounted(() => {
  if (unsubscribeNetwork) unsubscribeNetwork();
  if (unsubscribeSync) unsubscribeSync();
  if (successTimeout) clearTimeout(successTimeout);
  syncService.stopAutoSync();
});
</script>
