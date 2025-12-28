<script setup lang="ts">
import { ref, onMounted } from 'vue';
import LoginForm from './components/LoginForm.vue';
import CompanyRegistration from './components/CompanyRegistration.vue';
import ForgotPassword from './components/ForgotPassword.vue';
import ResetPassword from './components/ResetPassword.vue';
import Dashboard from './components/Dashboard.vue';
import { authService } from './services/auth';
import { updateFavicon } from './utils/favicon';
import type { Profile } from './services/supabase';

const loading = ref(true);
const isAuthenticated = ref(false);
const currentProfile = ref<Profile | null>(null);
const currentRoute = ref('login');

const updateRoute = () => {
  const hash = window.location.hash.slice(1);
  if (hash === '/register') {
    currentRoute.value = 'register';
  } else if (hash === '/forgot-password') {
    currentRoute.value = 'forgot-password';
  } else if (hash === '/reset-password') {
    currentRoute.value = 'reset-password';
  } else {
    currentRoute.value = 'login';
  }
};

onMounted(async () => {
  updateFavicon();
  updateRoute();

  window.addEventListener('hashchange', updateRoute);

  try {
    const profile = await authService.getCurrentProfile();
    if (profile) {
      currentProfile.value = profile;
      isAuthenticated.value = true;
    }
  } catch (error) {
    console.error('Error checking auth:', error);
  } finally {
    loading.value = false;
  }

  authService.onAuthStateChange(async (session) => {
    if (session) {
      const profile = await authService.getCurrentProfile();
      if (profile) {
        currentProfile.value = profile;
        isAuthenticated.value = true;
      }
    } else {
      currentProfile.value = null;
      isAuthenticated.value = false;
    }
  });
});

const handleLoginSuccess = async () => {
  try {
    const profile = await authService.getCurrentProfile();
    if (profile) {
      currentProfile.value = profile;
      isAuthenticated.value = true;
    }
  } catch (error) {
    console.error('Error after login:', error);
  }
};

const handleLogout = () => {
  currentProfile.value = null;
  isAuthenticated.value = false;
};

const handleResetSuccess = async () => {
  window.location.hash = '/login';
  try {
    const profile = await authService.getCurrentProfile();
    if (profile) {
      currentProfile.value = profile;
      isAuthenticated.value = true;
    }
  } catch (error) {
    console.error('Error after password reset:', error);
  }
};
</script>

<template>
  <div v-if="loading" class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-white">
    <div class="text-center">
      <div class="text-6xl mb-4">⏳</div>
      <p class="text-xl text-gray-600">Chargement...</p>
    </div>
  </div>

  <CompanyRegistration v-else-if="!isAuthenticated && currentRoute === 'register'" />

  <ForgotPassword v-else-if="!isAuthenticated && currentRoute === 'forgot-password'" />

  <ResetPassword
    v-else-if="currentRoute === 'reset-password'"
    @success="handleResetSuccess"
  />

  <LoginForm
    v-else-if="!isAuthenticated"
    @success="handleLoginSuccess"
  />

  <Dashboard
    v-else-if="currentProfile"
    :profile="currentProfile"
    @logout="handleLogout"
  />
</template>
