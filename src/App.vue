<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import LoginForm from './components/LoginForm.vue';
import CompanyRegistration from './components/CompanyRegistration.vue';
import ForgotPassword from './components/ForgotPassword.vue';
import ResetPassword from './components/ResetPassword.vue';
import Dashboard from './components/Dashboard.vue';
import { authService } from './services/auth';
import { updateFavicon } from './utils/favicon';
import { subscriptionService } from './services/subscription.service';
import type { Profile } from './services/supabase';

const loading = ref(true);
const isAuthenticated = ref(false);
const currentProfile = ref<Profile | null>(null);
const currentRoute = ref('login');
let subscriptionCheckInterval: number | null = null;

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

const checkSubscriptionStatus = async () => {
  if (!currentProfile.value || currentProfile.value.role === 'super_admin') {
    return;
  }

  try {
    const subscriptionInfo = await subscriptionService.getSubscriptionInfo(currentProfile.value.company_id);

    if (!subscriptionInfo) return;

    const now = new Date();
    let shouldLogout = false;
    let message = '';

    if (subscriptionInfo.subscription_status === 'trial') {
      if (subscriptionInfo.trial_end_date && new Date(subscriptionInfo.trial_end_date) < now) {
        shouldLogout = true;
        message = 'Votre période d\'essai a expiré. Veuillez contacter l\'administrateur.';
      }
    } else if (subscriptionInfo.subscription_status === 'active') {
      if (subscriptionInfo.subscription_end_date && new Date(subscriptionInfo.subscription_end_date) < now) {
        shouldLogout = true;
        message = 'Votre abonnement a expiré. Veuillez contacter l\'administrateur.';
      }
    } else if (subscriptionInfo.subscription_status === 'expired' || subscriptionInfo.subscription_status === 'suspended') {
      shouldLogout = true;
      message = subscriptionInfo.blocked_reason || 'Votre accès a été suspendu. Veuillez contacter l\'administrateur.';
    }

    if (shouldLogout) {
      if (subscriptionCheckInterval) {
        clearInterval(subscriptionCheckInterval);
        subscriptionCheckInterval = null;
      }
      await authService.signOut();
      alert(message);
      currentProfile.value = null;
      isAuthenticated.value = false;
    }
  } catch (error) {
    console.error('Error checking subscription status:', error);
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

      if (profile.role !== 'super_admin') {
        await checkSubscriptionStatus();

        if (subscriptionCheckInterval) {
          clearInterval(subscriptionCheckInterval);
        }
        subscriptionCheckInterval = window.setInterval(checkSubscriptionStatus, 5 * 60 * 1000);
      }
    }
  } catch (error: any) {
    console.error('Error checking auth:', error);
    if (error?.message?.includes('Invalid') || error?.message?.includes('JWT') || error?.message?.includes('expired')) {
      await authService.signOut().catch(() => {});
      currentProfile.value = null;
      isAuthenticated.value = false;
    }
  } finally {
    loading.value = false;
  }

  authService.onAuthStateChange(async (session) => {
    if (session) {
      try {
        const profile = await authService.getCurrentProfile();
        if (profile) {
          currentProfile.value = profile;
          isAuthenticated.value = true;

          if (profile.role !== 'super_admin') {
            await checkSubscriptionStatus();

            if (subscriptionCheckInterval) {
              clearInterval(subscriptionCheckInterval);
            }
            subscriptionCheckInterval = window.setInterval(checkSubscriptionStatus, 5 * 60 * 1000);
          }
        }
      } catch (error: any) {
        console.error('Error loading profile:', error);
        if (error?.message?.includes('Invalid') || error?.message?.includes('JWT') || error?.message?.includes('expired')) {
          await authService.signOut().catch(() => {});
          currentProfile.value = null;
          isAuthenticated.value = false;
        }
      }
    } else {
      currentProfile.value = null;
      isAuthenticated.value = false;

      if (subscriptionCheckInterval) {
        clearInterval(subscriptionCheckInterval);
        subscriptionCheckInterval = null;
      }
    }
  });
});

onUnmounted(() => {
  if (subscriptionCheckInterval) {
    clearInterval(subscriptionCheckInterval);
    subscriptionCheckInterval = null;
  }
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
