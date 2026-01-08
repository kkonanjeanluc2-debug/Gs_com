<script setup lang="ts">
import { ref } from 'vue';
import type { Profile } from '../services/supabase';

defineProps<{
  profile: Profile;
  tabs: Array<{ id: string; label: string; icon: string; badge?: number }>;
  activeTab: string;
  mobileMenuOpen?: boolean;
}>();

const emit = defineEmits<{
  selectTab: [tabId: string];
  logout: [];
  closeMobileMenu: [];
  sidebarToggled: [isCollapsed: boolean];
}>();

const isCollapsed = ref(false);

const toggleSidebar = () => {
  isCollapsed.value = !isCollapsed.value;
  emit('sidebarToggled', isCollapsed.value);
};

const handleSelectTab = (tabId: string) => {
  emit('selectTab', tabId);
  emit('closeMobileMenu');
};
</script>

<template>
  <aside
    :class="[
      'fixed left-0 top-0 bottom-0 bg-gradient-to-b from-blue-700 to-blue-900 text-white shadow-2xl transition-all duration-300 z-50 flex flex-col',
      isCollapsed ? 'w-20' : 'w-64',
      'hidden md:flex'
    ]"
  >
    <div class="p-6 border-b border-blue-600">
      <div class="flex items-center gap-3">
        <div class="bg-white rounded-lg p-2 flex-shrink-0">
          <span class="text-2xl">📊</span>
        </div>
        <div v-if="!isCollapsed" class="flex-1 min-w-0">
          <h1 class="text-xl font-bold truncate">ImmoGest</h1>
          <p class="text-blue-200 text-xs truncate">Gestion Pro</p>
        </div>
      </div>
    </div>

    <nav class="flex-1 overflow-y-auto py-4 px-3">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        @click="handleSelectTab(tab.id)"
        :class="[
          'w-full flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition-all mb-2 relative group',
          activeTab === tab.id
            ? 'bg-green-500 text-white shadow-lg'
            : 'text-blue-100 hover:bg-blue-800'
        ]"
      >
        <span class="text-xl flex-shrink-0">{{ tab.icon }}</span>
        <span v-if="!isCollapsed" class="flex-1 text-left truncate">{{ tab.label }}</span>
        <span
          v-if="tab.badge && tab.badge > 0"
          :class="[
            'flex items-center justify-center px-2 py-0.5 text-xs font-bold leading-none text-white bg-red-600 rounded-full',
            isCollapsed ? 'absolute -top-1 -right-1' : ''
          ]"
        >
          {{ tab.badge }}
        </span>
        <div
          v-if="isCollapsed"
          class="absolute left-full ml-2 px-3 py-2 bg-gray-900 text-white text-sm rounded-lg opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity whitespace-nowrap z-50"
        >
          {{ tab.label }}
        </div>
      </button>
    </nav>

    <div class="p-3 border-t border-blue-600">
      <button
        @click="toggleSidebar"
        class="w-full flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-blue-100 hover:bg-blue-800 transition-all"
      >
        <span class="text-xl flex-shrink-0">{{ isCollapsed ? '→' : '←' }}</span>
        <span v-if="!isCollapsed" class="flex-1 text-left">Réduire</span>
      </button>
    </div>
  </aside>

  <div
    v-if="mobileMenuOpen"
    class="fixed inset-0 z-50 md:hidden"
    @click="emit('closeMobileMenu')"
  >
    <div class="absolute inset-0 bg-black opacity-50"></div>
    <aside
      class="absolute left-0 top-0 bottom-0 w-64 bg-gradient-to-b from-blue-700 to-blue-900 text-white shadow-2xl flex flex-col"
      @click.stop
    >
      <div class="p-6 border-b border-blue-600">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="bg-white rounded-lg p-2 flex-shrink-0">
              <span class="text-2xl">📊</span>
            </div>
            <div class="flex-1 min-w-0">
              <h1 class="text-xl font-bold truncate">ImmoGest</h1>
              <p class="text-blue-200 text-xs truncate">Gestion Pro</p>
            </div>
          </div>
          <button
            @click="emit('closeMobileMenu')"
            class="text-white p-2"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
      </div>

      <nav class="flex-1 overflow-y-auto py-4 px-3">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          @click="handleSelectTab(tab.id)"
          :class="[
            'w-full flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition-all mb-2 relative',
            activeTab === tab.id
              ? 'bg-green-500 text-white shadow-lg'
              : 'text-blue-100 hover:bg-blue-800'
          ]"
        >
          <span class="text-xl flex-shrink-0">{{ tab.icon }}</span>
          <span class="flex-1 text-left truncate">{{ tab.label }}</span>
          <span
            v-if="tab.badge && tab.badge > 0"
            class="flex items-center justify-center px-2 py-0.5 text-xs font-bold leading-none text-white bg-red-600 rounded-full"
          >
            {{ tab.badge }}
          </span>
        </button>
      </nav>

      <div class="p-3 border-t border-blue-600">
        <button
          @click="emit('logout')"
          class="w-full flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-blue-100 hover:bg-red-600 transition-all"
        >
          <span class="text-xl flex-shrink-0">🚪</span>
          <span class="flex-1 text-left">Déconnexion</span>
        </button>
      </div>
    </aside>
  </div>
</template>
