<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import type { Profile } from '../services/supabase';
import type { Company } from '../services/companies.service';
import Icon from './Icon.vue';

const props = defineProps<{
  profile: Profile;
  company: Company | null;
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
const expandedCategories = ref<Set<string>>(new Set(['dashboard']));

const toggleSidebar = () => {
  isCollapsed.value = !isCollapsed.value;
  emit('sidebarToggled', isCollapsed.value);
};

const handleSelectTab = (tabId: string) => {
  emit('selectTab', tabId);
  emit('closeMobileMenu');
};

const toggleCategory = (categoryId: string) => {
  if (expandedCategories.value.has(categoryId)) {
    expandedCategories.value.delete(categoryId);
  } else {
    expandedCategories.value.add(categoryId);
  }
};

interface MenuCategory {
  id: string;
  label: string;
  icon: string;
  items?: Array<{ id: string; label: string; icon: string; badge?: number }>;
}

const menuStructure = computed((): MenuCategory[] => {
  const tabsMap = new Map(props.tabs.map(tab => [tab.id, tab]));

  const structure: MenuCategory[] = [];

  // Tableau de bord (standalone)
  if (tabsMap.has('dashboard')) {
    structure.push({
      id: 'dashboard',
      label: 'Tableau de bord',
      icon: 'chart',
    });
  }

  // Ventes
  const ventesItems = [];
  if (tabsMap.has('reports')) ventesItems.push({ ...tabsMap.get('reports')! });
  if (tabsMap.has('clients & Prospects')) ventesItems.push({ ...tabsMap.get('clients')! });
  if (tabsMap.has('tracking')) ventesItems.push({ ...tabsMap.get('tracking')! });
  if (tabsMap.has('orders')) ventesItems.push({ ...tabsMap.get('orders')! });

  if (ventesItems.length > 0) {
    structure.push({
      id: 'ventes',
      label: 'CRM',
      icon: 'cart',
      items: ventesItems,
    });
  }

  // Stocks
  const stocksItems = [];
  if (tabsMap.has('stock')) stocksItems.push({ ...tabsMap.get('stock')! });
  if (tabsMap.has('categories')) stocksItems.push({ ...tabsMap.get('categories')! });

  if (stocksItems.length > 0) {
    structure.push({
      id: 'stocks',
      label: 'Stocks',
      icon: 'box',
      items: stocksItems,
    });
  }

  // Achats
  const achatsItems = [];
  if (tabsMap.has('suppliers')) achatsItems.push({ ...tabsMap.get('suppliers')! });
  if (tabsMap.has('purchases')) achatsItems.push({ ...tabsMap.get('purchases')! });

  if (achatsItems.length > 0) {
    structure.push({
      id: 'achats',
      label: 'Achats',
      icon: 'truck',
      items: achatsItems,
    });
  }

  // Administration
  const adminItems = [];
  if (tabsMap.has('users')) adminItems.push({ ...tabsMap.get('users')! });
  if (tabsMap.has('subscription-plans')) adminItems.push({ ...tabsMap.get('subscription-plans')! });
  if (tabsMap.has('company')) adminItems.push({ ...tabsMap.get('company')! });

  if (adminItems.length > 0) {
    structure.push({
      id: 'administration',
      label: 'Administration',
      icon: 'settings',
      items: adminItems,
    });
  }

  // Gestion (Super Admin)
  const gestionItems = [];
  if (tabsMap.has('companies')) gestionItems.push({ ...tabsMap.get('companies')! });
  if (tabsMap.has('subscriptions')) gestionItems.push({ ...tabsMap.get('subscriptions')! });
  if (tabsMap.has('settings')) gestionItems.push({ ...tabsMap.get('settings')! });

  if (gestionItems.length > 0) {
    structure.push({
      id: 'gestion',
      label: 'Gestion',
      icon: 'buildings',
      items: gestionItems,
    });
  }

  return structure;
});

const isCategoryActive = (category: MenuCategory): boolean => {
  if (category.id === 'dashboard') {
    return props.activeTab === 'dashboard';
  }
  return category.items?.some(item => item.id === props.activeTab) || false;
};

// Auto-expand category when active tab changes
watch(() => props.activeTab, (newTab) => {
  const category = menuStructure.value.find(cat =>
    cat.items?.some(item => item.id === newTab)
  );
  if (category) {
    expandedCategories.value.add(category.id);
  }
}, { immediate: true });
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
        <div v-if="profile.role === 'super_admin'" class="bg-white rounded-lg p-2 flex-shrink-0 w-10 h-10 flex items-center justify-center">
          <Icon name="building" size="w-6 h-6" class="text-blue-600" />
        </div>
        <div v-else class="bg-white rounded-lg p-2 flex-shrink-0 w-10 h-10 flex items-center justify-center">
          <img
            v-if="company?.logo_url"
            :src="company.logo_url"
            :alt="company.name"
            class="w-full h-full object-contain"
          />
          <Icon v-else name="building" size="w-6 h-6" class="text-blue-600" />
        </div>
        <div v-if="!isCollapsed && profile.role !== 'super_admin'" class="flex-1 min-w-0">
          <h1 class="text-xl font-bold truncate">{{ company?.name || 'ImmoGest' }}</h1>
          <p class="text-blue-200 text-xs truncate">Gestion Pro</p>
        </div>
      </div>
    </div>

    <nav class="flex-1 overflow-y-auto py-4 px-3">
      <div v-for="category in menuStructure" :key="category.id" class="mb-2">
        <!-- Standalone item (e.g., Dashboard) -->
        <button
          v-if="!category.items"
          @click="handleSelectTab(category.id)"
          :class="[
            'w-full flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition-all relative group',
            isCategoryActive(category)
              ? 'bg-green-500 text-white shadow-lg'
              : 'text-blue-100 hover:bg-blue-800'
          ]"
        >
          <Icon :name="category.icon" class="flex-shrink-0" />
          <span v-if="!isCollapsed" class="flex-1 text-left truncate">{{ category.label }}</span>
          <div
            v-if="isCollapsed"
            class="absolute left-full ml-2 px-3 py-2 bg-gray-900 text-white text-sm rounded-lg opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity whitespace-nowrap z-50"
          >
            {{ category.label }}
          </div>
        </button>

        <!-- Category with subitems -->
        <div v-else>
          <button
            @click="toggleCategory(category.id)"
            :class="[
              'w-full flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition-all relative group',
              isCategoryActive(category)
                ? 'bg-blue-800 text-white'
                : 'text-blue-100 hover:bg-blue-800'
            ]"
          >
            <Icon :name="category.icon" class="flex-shrink-0" />
            <span v-if="!isCollapsed" class="flex-1 text-left truncate">{{ category.label }}</span>
            <Icon
              v-if="!isCollapsed"
              :name="expandedCategories.has(category.id) ? 'chevron-down' : 'chevron-right'"
              class="w-4 h-4 flex-shrink-0"
            />
            <div
              v-if="isCollapsed"
              class="absolute left-full ml-2 px-3 py-2 bg-gray-900 text-white text-sm rounded-lg opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity whitespace-nowrap z-50"
            >
              {{ category.label }}
            </div>
          </button>

          <!-- Subitems -->
          <div
            v-show="expandedCategories.has(category.id) && !isCollapsed"
            class="ml-4 mt-1 space-y-1"
          >
            <button
              v-for="item in category.items"
              :key="item.id"
              @click="handleSelectTab(item.id)"
              :class="[
                'w-full flex items-center gap-3 px-4 py-2 rounded-lg font-medium transition-all relative',
                activeTab === item.id
                  ? 'bg-green-500 text-white shadow-lg'
                  : 'text-blue-100 hover:bg-blue-700'
              ]"
            >
              <Icon :name="item.icon" class="flex-shrink-0 w-4 h-4" />
              <span class="flex-1 text-left truncate text-sm">{{ item.label }}</span>
              <span
                v-if="item.badge && item.badge > 0"
                class="flex items-center justify-center px-2 py-0.5 text-xs font-bold leading-none text-white bg-red-600 rounded-full"
              >
                {{ item.badge }}
              </span>
            </button>
          </div>
        </div>
      </div>
    </nav>

    <div class="p-3 border-t border-blue-600">
      <button
        @click="toggleSidebar"
        class="w-full flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-blue-100 hover:bg-blue-800 transition-all"
      >
        <Icon :name="isCollapsed ? 'arrow-right' : 'arrow-left'" class="flex-shrink-0" />
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
            <div v-if="profile.role === 'super_admin'" class="bg-white rounded-lg p-2 flex-shrink-0 w-10 h-10 flex items-center justify-center">
              <Icon name="building" size="w-6 h-6" class="text-blue-600" />
            </div>
            <div v-else class="bg-white rounded-lg p-2 flex-shrink-0 w-10 h-10 flex items-center justify-center">
              <img
                v-if="company?.logo_url"
                :src="company.logo_url"
                :alt="company.name"
                class="w-full h-full object-contain"
              />
              <Icon v-else name="building" size="w-6 h-6" class="text-blue-600" />
            </div>
            <div v-if="profile.role !== 'super_admin'" class="flex-1 min-w-0">
              <h1 class="text-xl font-bold truncate">{{ company?.name || 'ImmoGest' }}</h1>
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
        <div v-for="category in menuStructure" :key="category.id" class="mb-2">
          <!-- Standalone item (e.g., Dashboard) -->
          <button
            v-if="!category.items"
            @click="handleSelectTab(category.id)"
            :class="[
              'w-full flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition-all relative',
              isCategoryActive(category)
                ? 'bg-green-500 text-white shadow-lg'
                : 'text-blue-100 hover:bg-blue-800'
            ]"
          >
            <Icon :name="category.icon" class="flex-shrink-0" />
            <span class="flex-1 text-left truncate">{{ category.label }}</span>
          </button>

          <!-- Category with subitems -->
          <div v-else>
            <button
              @click="toggleCategory(category.id)"
              :class="[
                'w-full flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition-all relative',
                isCategoryActive(category)
                  ? 'bg-blue-800 text-white'
                  : 'text-blue-100 hover:bg-blue-800'
              ]"
            >
              <Icon :name="category.icon" class="flex-shrink-0" />
              <span class="flex-1 text-left truncate">{{ category.label }}</span>
              <Icon
                :name="expandedCategories.has(category.id) ? 'chevron-down' : 'chevron-right'"
                class="w-4 h-4 flex-shrink-0"
              />
            </button>

            <!-- Subitems -->
            <div
              v-show="expandedCategories.has(category.id)"
              class="ml-4 mt-1 space-y-1"
            >
              <button
                v-for="item in category.items"
                :key="item.id"
                @click="handleSelectTab(item.id)"
                :class="[
                  'w-full flex items-center gap-3 px-4 py-2 rounded-lg font-medium transition-all relative',
                  activeTab === item.id
                    ? 'bg-green-500 text-white shadow-lg'
                    : 'text-blue-100 hover:bg-blue-700'
                ]"
              >
                <Icon :name="item.icon" class="flex-shrink-0 w-4 h-4" />
                <span class="flex-1 text-left truncate text-sm">{{ item.label }}</span>
                <span
                  v-if="item.badge && item.badge > 0"
                  class="flex items-center justify-center px-2 py-0.5 text-xs font-bold leading-none text-white bg-red-600 rounded-full"
                >
                  {{ item.badge }}
                </span>
              </button>
            </div>
          </div>
        </div>
      </nav>

      <div class="p-3 border-t border-blue-600">
        <button
          @click="emit('logout')"
          class="w-full flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-blue-100 hover:bg-red-600 transition-all"
        >
          <Icon name="logout" class="flex-shrink-0" />
          <span class="flex-1 text-left">Déconnexion</span>
        </button>
      </div>
    </aside>
  </div>
</template>
