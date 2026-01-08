<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import type { Profile } from '../services/supabase';

const { profile } = defineProps<{
  profile: Profile;
}>();

const emit = defineEmits<{
  logout: [];
}>();

const showDropdown = ref(false);
const dropdownRef = ref<HTMLElement | null>(null);

const handleClickOutside = (event: MouseEvent) => {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target as Node)) {
    showDropdown.value = false;
  }
};

onMounted(() => {
  document.addEventListener('click', handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});

const getRoleLabel = (role: string) => {
  const roles: Record<string, string> = {
    'admin': 'Administrateur',
    'super_admin': 'Super Administrateur',
    'superviseur': 'Superviseur',
    'commercial': 'Commercial'
  };
  return roles[role] || role;
};

const getInitials = (name: string) => {
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
};
</script>

<template>
  <header class="sticky top-0 z-40 bg-white border-b border-gray-200 shadow-sm hidden md:block">
    <div class="flex items-center justify-end px-6 py-4">
      <div class="flex items-center gap-3">
        <div class="hidden sm:block text-right">
          <p class="text-sm font-semibold text-gray-900">{{ profile.full_name }}</p>
          <p class="text-xs text-gray-500">{{ getRoleLabel(profile.role) }}</p>
        </div>

        <div class="relative" ref="dropdownRef">
          <button
            @click.stop="showDropdown = !showDropdown"
            class="flex items-center gap-2 focus:outline-none hover:opacity-80 transition-opacity"
          >
            <div
              v-if="profile.photo_url"
              class="w-10 h-10 rounded-full overflow-hidden border-2 border-blue-600"
            >
              <img
                :src="profile.photo_url"
                :alt="profile.full_name"
                class="w-full h-full object-cover"
              />
            </div>
            <div
              v-else
              class="w-10 h-10 rounded-full bg-blue-600 text-white flex items-center justify-center font-semibold text-sm border-2 border-blue-700"
            >
              {{ getInitials(profile.full_name) }}
            </div>
          </button>

          <transition
            enter-active-class="transition ease-out duration-100"
            enter-from-class="transform opacity-0 scale-95"
            enter-to-class="transform opacity-100 scale-100"
            leave-active-class="transition ease-in duration-75"
            leave-from-class="transform opacity-100 scale-100"
            leave-to-class="transform opacity-0 scale-95"
          >
            <div
              v-if="showDropdown"
              class="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg py-2 border border-gray-200"
              @click.stop
            >
            <div class="px-4 py-2 border-b border-gray-200 sm:hidden">
              <p class="text-sm font-semibold text-gray-900">{{ profile.full_name }}</p>
              <p class="text-xs text-gray-500">{{ getRoleLabel(profile.role) }}</p>
            </div>
              <button
                @click="emit('logout'); showDropdown = false"
                class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 transition-colors"
              >
                🚪 Déconnexion
              </button>
            </div>
          </transition>
        </div>
      </div>
    </div>
  </header>
</template>
