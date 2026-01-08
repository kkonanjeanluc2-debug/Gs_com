<script setup lang="ts">
import Icon from './Icon.vue';

const emit = defineEmits<{
  navigateToLogin: [];
  navigateToRegister: [];
}>();

const features = [
  {
    icon: 'chart-bar',
    title: 'Tableau de bord intelligent',
    description: 'Visualisez vos performances en temps réel avec des graphiques et indicateurs clés'
  },
  {
    icon: 'package',
    title: 'Gestion du stock',
    description: 'Gérez votre inventaire facilement avec import Excel et suivi des mouvements'
  },
  {
    icon: 'users',
    title: 'CRM complet',
    description: 'Gérez vos clients et prospects avec géolocalisation et suivi WhatsApp'
  },
  {
    icon: 'shopping-cart',
    title: 'Gestion des commandes',
    description: 'Créez et suivez vos commandes avec génération automatique de factures'
  },
  {
    icon: 'document',
    title: 'Rapports d\'activité',
    description: 'Créez et envoyez vos rapports quotidiens directement sur WhatsApp'
  },
  {
    icon: 'users-group',
    title: 'Multi-utilisateurs',
    description: 'Gérez votre équipe commerciale avec rôles et permissions'
  }
];

const scrollToContact = () => {
  const contactSection = document.getElementById('contact-section');
  if (contactSection) {
    contactSection.scrollIntoView({ behavior: 'smooth' });
  }
};

const openWhatsApp = () => {
  window.open('https://wa.me/22577370177', '_blank');
};

const callPhone = () => {
  window.location.href = 'tel:+22577370177';
};
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
    <!-- Header -->
    <header class="fixed top-0 left-0 right-0 z-50 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
      <div class="container mx-auto px-4">
        <div class="flex items-center justify-between h-20">
          <!-- Logo -->
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg">
              <Icon name="shopping-cart" class="w-6 h-6 text-white" />
            </div>
            <span class="text-2xl font-bold text-white">GescomPro</span>
          </div>

          <!-- Navigation Desktop -->
          <nav class="hidden md:flex items-center gap-8">
            <a href="#accueil" class="text-gray-300 hover:text-white transition-colors font-medium">Accueil</a>
            <a href="#solutions" class="text-gray-300 hover:text-white transition-colors font-medium">Solutions</a>
            <a href="#contact-section" @click.prevent="scrollToContact" class="text-gray-300 hover:text-white transition-colors font-medium">Contact</a>
            <a href="#boutique" class="text-gray-300 hover:text-white transition-colors font-medium">Boutique en ligne</a>
          </nav>

          <!-- Auth Buttons -->
          <div class="flex items-center gap-3">
            <button
              @click="emit('navigateToLogin')"
              class="px-6 py-2.5 rounded-lg font-medium text-white border-2 border-blue-500 hover:bg-blue-500 transition-all duration-200"
            >
              Se connecter
            </button>
            <button
              @click="emit('navigateToRegister')"
              class="px-6 py-2.5 rounded-lg font-medium text-white bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 transition-all duration-200 shadow-lg hover:shadow-xl"
            >
              S'inscrire
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Hero Section -->
    <section id="accueil" class="pt-32 pb-20 px-4">
      <div class="container mx-auto">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <!-- Left Content -->
          <div class="text-white space-y-8">
            <div class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-500/20 border border-blue-500/30 text-blue-300 text-sm font-medium">
              <Icon name="star" class="w-4 h-4" />
              <span>Solution Tech20i</span>
            </div>

            <h1 class="text-5xl md:text-6xl font-bold leading-tight">
              Gescom<span class="text-blue-400">Pro</span>
            </h1>

            <p class="text-xl text-gray-300 leading-relaxed">
              La solution complète de gestion commerciale moderne pour votre entreprise. Gérez votre boutique comme un professionnel avec nos outils intelligents.
            </p>

            <!-- Contact Buttons -->
            <div class="flex flex-col sm:flex-row gap-4">
              <button
                @click="callPhone"
                class="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl font-semibold text-white bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 transition-all duration-200 shadow-xl hover:shadow-2xl"
              >
                <Icon name="phone" class="w-5 h-5" />
                <span>Appelez-nous : 77 370 17 27</span>
              </button>

              <button
                @click="openWhatsApp"
                class="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl font-semibold text-white bg-gradient-to-r from-emerald-600 to-emerald-700 hover:from-emerald-700 hover:to-emerald-800 transition-all duration-200 shadow-xl hover:shadow-2xl"
              >
                <Icon name="phone" class="w-5 h-5" />
                <span>WhatsApp</span>
              </button>
            </div>

            <button
              @click="scrollToContact"
              class="inline-flex items-center gap-2 text-gray-300 hover:text-white transition-colors"
            >
              <Icon name="mail" class="w-5 h-5" />
              <span>contact@gescompro.com</span>
            </button>
          </div>

          <!-- Right Image/Dashboard Preview -->
          <div class="relative">
            <div class="relative rounded-2xl overflow-hidden shadow-2xl border-4 border-slate-700 bg-slate-800">
              <div class="aspect-video bg-gradient-to-br from-slate-800 to-slate-900 p-6">
                <!-- Mockup Dashboard -->
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                      <div class="w-8 h-8 rounded-lg bg-blue-500 flex items-center justify-center">
                        <Icon name="chart-bar" class="w-5 h-5 text-white" />
                      </div>
                      <span class="text-white font-semibold">Tableau de bord</span>
                    </div>
                    <div class="text-sm text-gray-400">Bienvenue sur GescomPro</div>
                  </div>

                  <div class="grid grid-cols-3 gap-3">
                    <div class="bg-blue-500/20 rounded-lg p-3 border border-blue-500/30">
                      <div class="text-xs text-blue-300 mb-1">Ventes</div>
                      <div class="text-lg font-bold text-white">2 871 FCFA</div>
                    </div>
                    <div class="bg-emerald-500/20 rounded-lg p-3 border border-emerald-500/30">
                      <div class="text-xs text-emerald-300 mb-1">CA total</div>
                      <div class="text-lg font-bold text-white">29 000 F</div>
                    </div>
                    <div class="bg-amber-500/20 rounded-lg p-3 border border-amber-500/30">
                      <div class="text-xs text-amber-300 mb-1">Tendance</div>
                      <div class="text-lg font-bold text-white">+165%</div>
                    </div>
                  </div>

                  <div class="bg-slate-700/50 rounded-lg p-4">
                    <div class="flex items-center gap-2 mb-2">
                      <Icon name="chart-bar" class="w-4 h-4 text-blue-400" />
                      <span class="text-sm text-gray-300">Évolution des ventes</span>
                    </div>
                    <div class="h-24 flex items-end gap-1">
                      <div class="flex-1 bg-blue-500 rounded-t" style="height: 40%"></div>
                      <div class="flex-1 bg-blue-500 rounded-t" style="height: 60%"></div>
                      <div class="flex-1 bg-blue-500 rounded-t" style="height: 45%"></div>
                      <div class="flex-1 bg-blue-500 rounded-t" style="height: 80%"></div>
                      <div class="flex-1 bg-blue-500 rounded-t" style="height: 70%"></div>
                      <div class="flex-1 bg-blue-500 rounded-t" style="height: 95%"></div>
                      <div class="flex-1 bg-emerald-500 rounded-t" style="height: 100%"></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Floating elements -->
            <div class="absolute -top-6 -left-6 w-24 h-24 bg-blue-500/20 rounded-full blur-2xl"></div>
            <div class="absolute -bottom-6 -right-6 w-32 h-32 bg-emerald-500/20 rounded-full blur-2xl"></div>
          </div>
        </div>
      </div>
    </section>

    <!-- Features Section -->
    <section id="solutions" class="py-20 px-4 bg-slate-800/50">
      <div class="container mx-auto">
        <div class="text-center mb-16">
          <h2 class="text-4xl font-bold text-white mb-4">
            Fonctionnalités puissantes
          </h2>
          <p class="text-xl text-gray-400">
            Tout ce dont vous avez besoin pour gérer votre business efficacement
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <div
            v-for="feature in features"
            :key="feature.title"
            class="bg-slate-800/80 rounded-2xl p-8 border border-slate-700 hover:border-blue-500/50 transition-all duration-300 hover:shadow-xl hover:shadow-blue-500/10"
          >
            <div class="w-14 h-14 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg mb-6">
              <Icon :name="feature.icon" class="w-7 h-7 text-white" />
            </div>
            <h3 class="text-xl font-bold text-white mb-3">{{ feature.title }}</h3>
            <p class="text-gray-400 leading-relaxed">{{ feature.description }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Contact Section -->
    <section id="contact-section" class="py-20 px-4">
      <div class="container mx-auto max-w-4xl">
        <div class="bg-gradient-to-br from-slate-800 to-slate-900 rounded-3xl p-12 border border-slate-700 shadow-2xl">
          <div class="text-center mb-12">
            <h2 class="text-4xl font-bold text-white mb-4">
              Contactez-nous
            </h2>
            <p class="text-xl text-gray-400">
              Notre équipe est là pour répondre à toutes vos questions
            </p>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <button
              @click="callPhone"
              class="flex flex-col items-center gap-4 p-6 rounded-xl bg-slate-700/50 border border-slate-600 hover:border-blue-500 transition-all duration-200 group"
            >
              <div class="w-16 h-16 rounded-full bg-blue-500/20 flex items-center justify-center group-hover:bg-blue-500 transition-all duration-200">
                <Icon name="phone" class="w-8 h-8 text-blue-400 group-hover:text-white transition-all duration-200" />
              </div>
              <div class="text-center">
                <div class="text-sm text-gray-400 mb-1">Téléphone</div>
                <div class="text-white font-semibold">77 370 17 27</div>
              </div>
            </button>

            <button
              @click="openWhatsApp"
              class="flex flex-col items-center gap-4 p-6 rounded-xl bg-slate-700/50 border border-slate-600 hover:border-emerald-500 transition-all duration-200 group"
            >
              <div class="w-16 h-16 rounded-full bg-emerald-500/20 flex items-center justify-center group-hover:bg-emerald-500 transition-all duration-200">
                <Icon name="phone" class="w-8 h-8 text-emerald-400 group-hover:text-white transition-all duration-200" />
              </div>
              <div class="text-center">
                <div class="text-sm text-gray-400 mb-1">WhatsApp</div>
                <div class="text-white font-semibold">77 370 17 27</div>
              </div>
            </button>

            <div class="flex flex-col items-center gap-4 p-6 rounded-xl bg-slate-700/50 border border-slate-600">
              <div class="w-16 h-16 rounded-full bg-gray-500/20 flex items-center justify-center">
                <Icon name="mail" class="w-8 h-8 text-gray-400" />
              </div>
              <div class="text-center">
                <div class="text-sm text-gray-400 mb-1">Email</div>
                <div class="text-white font-semibold text-sm">contact@gescompro.com</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="py-12 px-4 bg-slate-900/80 border-t border-slate-800">
      <div class="container mx-auto">
        <div class="flex flex-col md:flex-row justify-between items-center gap-6">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg">
              <Icon name="shopping-cart" class="w-6 h-6 text-white" />
            </div>
            <span class="text-xl font-bold text-white">GescomPro</span>
          </div>

          <div class="text-gray-400 text-sm">
            © 2025 GescomPro - Solution Tech20i. Tous droits réservés.
          </div>

          <div class="flex gap-4">
            <button
              @click="openWhatsApp"
              class="w-10 h-10 rounded-lg bg-slate-800 border border-slate-700 flex items-center justify-center hover:border-emerald-500 transition-colors"
            >
              <Icon name="phone" class="w-5 h-5 text-emerald-400" />
            </button>
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>
