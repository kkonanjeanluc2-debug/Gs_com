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
  window.open('https://wa.me/22507088645227', '_blank');
};

const callPhone = () => {
  window.location.href = 'tel:+22507088645227';
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
            <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg">
              <Icon name="shopping-cart" class="w-7 h-7 text-white" />
            </div>
            <span class="text-2xl font-bold text-white">Ges-com</span>
          </div>

          <!-- Navigation Desktop -->
          <nav class="hidden md:flex items-center gap-8">
            <a href="#solutions" class="text-gray-300 hover:text-white transition-colors font-medium">Solutions</a>
            <a href="#contact-section" @click.prevent="scrollToContact" class="text-gray-300 hover:text-white transition-colors font-medium">Contact</a>
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
            <h1 class="text-5xl md:text-6xl font-bold leading-tight">
              Ges-com
            </h1>

            <p class="text-xl text-gray-300 leading-relaxed">
              La solution complète de suivi des commerciaux moderne pour votre entreprise. Gérez votre entreprise comme un professionnel avec nos outils intelligents.
            </p>

            <!-- Contact Buttons -->
            <div class="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
              <button
                @click="callPhone"
                class="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl font-semibold text-white bg-blue-600 hover:bg-blue-700 transition-all duration-200 shadow-lg hover:shadow-xl"
              >
                <Icon name="phone" class="w-5 h-5" />
                <span>Appelez-nous : 07 08 86 45 27</span>
              </button>

              <button
                @click="openWhatsApp"
                class="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl font-semibold text-white bg-emerald-600 hover:bg-emerald-700 transition-all duration-200 shadow-lg hover:shadow-xl"
              >
                <Icon name="phone" class="w-5 h-5" />
                <span>WhatsApp</span>
              </button>
            </div>
          </div>

          <!-- Right Image/Dashboard Preview -->
          <div class="relative">
            <div class="relative rounded-2xl overflow-hidden shadow-2xl border-4 border-slate-700 bg-white">
              <!-- Dashboard Mockup -->
              <div class="flex h-[600px]">
                <!-- Sidebar -->
                <div class="w-56 bg-blue-700 text-white p-4 flex flex-col">
                  <!-- Logo/Company -->
                  <div class="flex items-center gap-3 mb-8 bg-blue-800 p-3 rounded-lg">
                    <div class="w-10 h-10 bg-white rounded-lg flex items-center justify-center">
                      <Icon name="shopping-cart" class="w-6 h-6 text-blue-700" />
                    </div>
                    <div>
                      <div class="font-bold text-sm">Ges-com</div>
                      <div class="text-xs text-blue-200">Gestion Pro</div>
                    </div>
                  </div>

                  <!-- Menu Items -->
                  <nav class="space-y-1 flex-1">
                    <div class="bg-green-500 text-white px-3 py-2.5 rounded-lg flex items-center gap-2 text-sm font-medium">
                      <Icon name="chart-bar" class="w-4 h-4" />
                      <span>Tableau de bord</span>
                    </div>
                    <div class="text-white/80 hover:text-white px-3 py-2.5 rounded-lg flex items-center gap-2 text-sm">
                      <Icon name="document" class="w-4 h-4" />
                      <span>Rapports</span>
                    </div>
                    <div class="text-white/80 hover:text-white px-3 py-2.5 rounded-lg flex items-center gap-2 text-sm">
                      <Icon name="users-group" class="w-4 h-4" />
                      <span>CRM</span>
                    </div>
                    <div class="text-white/80 hover:text-white px-3 py-2.5 rounded-lg flex items-center gap-2 text-sm">
                      <Icon name="shopping-cart" class="w-4 h-4" />
                      <span>Commandes</span>
                    </div>
                    <div class="text-white/80 hover:text-white px-3 py-2.5 rounded-lg flex items-center gap-2 text-sm">
                      <Icon name="package" class="w-4 h-4" />
                      <span>Stock</span>
                    </div>
                  </nav>
                </div>

                <!-- Main Content -->
                <div class="flex-1 bg-gray-50 overflow-auto">
                  <!-- Top Bar -->
                  <div class="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
                    <h1 class="text-xl font-bold text-gray-800">Tableau de bord</h1>
                    <div class="flex items-center gap-3">
                      <div class="text-right text-sm">
                        <div class="font-semibold text-gray-800">Jean-Luc</div>
                        <div class="text-gray-500 text-xs">Administrateur</div>
                      </div>
                      <div class="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold">
                        J
                      </div>
                    </div>
                  </div>

                  <!-- Stats Cards -->
                  <div class="p-6">
                    <div class="grid grid-cols-5 gap-3 mb-6">
                      <!-- Recette du jour -->
                      <div class="bg-gradient-to-br from-emerald-500 to-emerald-600 rounded-xl p-4 text-white shadow-lg">
                        <div class="flex items-center gap-2 mb-2">
                          <Icon name="document" class="w-5 h-5" />
                          <div class="text-xs font-medium">Recette du jour</div>
                        </div>
                        <div class="text-2xl font-bold">487,500</div>
                        <div class="text-xs mt-1 opacity-90">FCFA aujourd'hui</div>
                      </div>

                      <!-- CA mensuel -->
                      <div class="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-4 text-white shadow-lg">
                        <div class="flex items-center gap-2 mb-2">
                          <Icon name="chart-bar" class="w-5 h-5" />
                          <div class="text-xs font-medium">CA mensuel</div>
                        </div>
                        <div class="text-2xl font-bold">12.4M</div>
                        <div class="text-xs mt-1 flex items-center gap-1 opacity-90">
                          <span>→ +24%</span>
                          <span>vs mois dernier</span>
                        </div>
                      </div>

                      <!-- Ventes -->
                      <div class="bg-gradient-to-br from-green-500 to-green-600 rounded-xl p-4 text-white shadow-lg">
                        <div class="flex items-center gap-2 mb-2">
                          <Icon name="shopping-cart" class="w-5 h-5" />
                          <div class="text-xs font-medium">Ventes</div>
                        </div>
                        <div class="text-2xl font-bold">847</div>
                        <div class="text-xs mt-1 flex items-center gap-1 opacity-90">
                          <span>→ +18%</span>
                          <span>vs mois dernier</span>
                        </div>
                      </div>

                      <!-- Clients -->
                      <div class="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-4 text-white shadow-lg">
                        <div class="flex items-center gap-2 mb-2">
                          <Icon name="users-group" class="w-5 h-5" />
                          <div class="text-xs font-medium">Clients</div>
                        </div>
                        <div class="text-2xl font-bold">324</div>
                        <div class="text-xs mt-1 opacity-90">clients actifs</div>
                      </div>

                      <!-- Produits -->
                      <div class="bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl p-4 text-white shadow-lg">
                        <div class="flex items-center gap-2 mb-2">
                          <Icon name="package" class="w-5 h-5" />
                          <div class="text-xs font-medium">Produits</div>
                        </div>
                        <div class="text-2xl font-bold">1,247</div>
                        <div class="text-xs mt-1 opacity-90">en catalogue</div>
                      </div>
                    </div>

                    <!-- Bottom Sections -->
                    <div class="grid grid-cols-2 gap-4">
                      <!-- Meilleurs Commerciaux -->
                      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-200">
                        <div class="flex items-center justify-between mb-4">
                          <div class="flex items-center gap-2">
                            <div class="w-8 h-8 rounded-lg bg-yellow-100 flex items-center justify-center">
                              <Icon name="users" class="w-5 h-5 text-yellow-600" />
                            </div>
                            <div>
                              <div class="font-bold text-gray-800 text-sm">Meilleurs Commerciaux</div>
                              <div class="text-xs text-gray-500">Top 3 du mois en cours</div>
                            </div>
                          </div>
                        </div>
                        <div class="space-y-3">
                          <div class="flex items-center justify-between text-sm">
                            <div class="flex items-center gap-2">
                              <div class="w-6 h-6 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-bold text-xs">1</div>
                              <span class="font-medium text-gray-700">Kouassi A.</span>
                            </div>
                            <span class="font-bold text-gray-800">3.2M FCFA</span>
                          </div>
                          <div class="flex items-center justify-between text-sm">
                            <div class="flex items-center gap-2">
                              <div class="w-6 h-6 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-bold text-xs">2</div>
                              <span class="font-medium text-gray-700">Koné S.</span>
                            </div>
                            <span class="font-bold text-gray-800">2.8M FCFA</span>
                          </div>
                          <div class="flex items-center justify-between text-sm">
                            <div class="flex items-center gap-2">
                              <div class="w-6 h-6 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-bold text-xs">3</div>
                              <span class="font-medium text-gray-700">Diallo M.</span>
                            </div>
                            <span class="font-bold text-gray-800">2.1M FCFA</span>
                          </div>
                        </div>
                      </div>

                      <!-- Produits les Plus Vendus -->
                      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-200">
                        <div class="flex items-center justify-between mb-4">
                          <div class="flex items-center gap-2">
                            <div class="w-8 h-8 rounded-lg bg-blue-100 flex items-center justify-center">
                              <Icon name="chart-bar" class="w-5 h-5 text-blue-600" />
                            </div>
                            <div>
                              <div class="font-bold text-gray-800 text-sm">Produits les Plus Vendus</div>
                              <div class="text-xs text-gray-500">Top 5</div>
                            </div>
                          </div>
                        </div>
                        <div class="space-y-2.5">
                          <div class="flex items-center justify-between text-xs">
                            <span class="font-medium text-gray-700">Cahier 200 pages</span>
                            <span class="font-bold text-gray-800">847 unités</span>
                          </div>
                          <div class="flex items-center justify-between text-xs">
                            <span class="font-medium text-gray-700">Stylo BIC bleu</span>
                            <span class="font-bold text-gray-800">612 unités</span>
                          </div>
                          <div class="flex items-center justify-between text-xs">
                            <span class="font-medium text-gray-700">Classeur A4</span>
                            <span class="font-bold text-gray-800">423 unités</span>
                          </div>
                          <div class="flex items-center justify-between text-xs">
                            <span class="font-medium text-gray-700">Ramette papier</span>
                            <span class="font-bold text-gray-800">298 unités</span>
                          </div>
                          <div class="flex items-center justify-between text-xs">
                            <span class="font-medium text-gray-700">Marqueur tableau</span>
                            <span class="font-bold text-gray-800">276 unités</span>
                          </div>
                        </div>
                      </div>
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

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <button
              @click="callPhone"
              class="flex flex-col items-center gap-4 p-6 rounded-xl bg-slate-700/50 border border-slate-600 hover:border-blue-500 transition-all duration-200 group"
            >
              <div class="w-16 h-16 rounded-full bg-blue-500/20 flex items-center justify-center group-hover:bg-blue-500 transition-all duration-200">
                <Icon name="phone" class="w-8 h-8 text-blue-400 group-hover:text-white transition-all duration-200" />
              </div>
              <div class="text-center">
                <div class="text-sm text-gray-400 mb-1">Téléphone</div>
                <div class="text-white font-semibold">07 08 86 45 27</div>
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
                <div class="text-white font-semibold">07 08 86 45 27</div>
              </div>
            </button>
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
            <span class="text-xl font-bold text-white">Ges-com</span>
          </div>

          <div class="text-gray-400 text-sm">
            © 2025 Ges-com. Tous droits réservés.
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
