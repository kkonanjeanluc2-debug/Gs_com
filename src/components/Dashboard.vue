<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type { Profile } from '../services/supabase';
import { authService } from '../services/auth';
import { ordersService } from '../services/orders.service';
import DashboardView from './DashboardView.vue';
import ReportForm from './ReportForm.vue';
import ReportList from './ReportList.vue';
import ProductManagement from './ProductManagement.vue';
import ClientManagement from './ClientManagement.vue';
import CommercialManagement from './CommercialManagement.vue';
import UserManagement from './UserManagement.vue';
import CategoryManagement from './CategoryManagement.vue';
import OrderManagement from './OrderManagement.vue';
import CompanySettings from './CompanySettings.vue';
import CompanyManagement from './CompanyManagement.vue';
import SuperAdminSettings from './SuperAdminSettings.vue';
import SubscriptionManagement from './SubscriptionManagement.vue';
import SubscriptionPlans from './SubscriptionPlans.vue';
import AppFooter from './AppFooter.vue';
import { reportsService } from '../services/reports.service';
import { whatsappService } from '../services/whatsapp';
import type { ReportDB } from '../services/supabase';
import type { Report } from '../services/storage';

const props = defineProps<{
  profile: Profile;
}>();

const emit = defineEmits<{
  logout: [];
}>();

const activeTab = ref<'dashboard' | 'reports' | 'clients' | 'stock' | 'categories' | 'users' | 'orders' | 'company' | 'companies' | 'subscriptions' | 'subscription-plans' | 'settings'>('dashboard');
const crmSubTab = ref<'clients' | 'commercials'>('clients');
const reports = ref<ReportDB[]>([]);
const isFormOpen = ref(false);
const editingReport = ref<ReportDB | null>(null);
const mobileMenuOpen = ref(false);
const pendingOrdersCount = ref(0);

const canManageStock = computed(() => {
  return ['admin', 'superviseur'].includes(props.profile.role);
});

const canManageClients = computed(() => {
  return ['admin', 'superviseur', 'commercial'].includes(props.profile.role);
});

const canManageUsers = computed(() => {
  return ['admin', 'superviseur'].includes(props.profile.role);
});

const canManageCommercials = computed(() => {
  return ['admin', 'superviseur'].includes(props.profile.role);
});

const isAdmin = computed(() => {
  return props.profile.role === 'admin';
});

const isSuperAdmin = computed(() => {
  return props.profile.role === 'super_admin';
});

const tabs = computed(() => {
  const allTabs = [
    { id: 'dashboard', label: 'Tableau de bord', icon: '📊' },
    { id: 'reports', label: 'Rapports', icon: '📝', visible: !isSuperAdmin.value },
    { id: 'clients', label: 'CRM', icon: '👥', visible: canManageClients.value && !isSuperAdmin.value },
    { id: 'orders', label: 'Commandes', icon: '🛒', visible: canManageClients.value && !isSuperAdmin.value },
    { id: 'stock', label: 'Stock', icon: '📦', visible: canManageStock.value && !isSuperAdmin.value },
    { id: 'categories', label: 'Catégories', icon: '📁', visible: canManageStock.value && !isSuperAdmin.value },
    { id: 'users', label: 'Utilisateurs', icon: '👤', visible: canManageUsers.value && !isSuperAdmin.value },
    { id: 'subscription-plans', label: 'Mon Abonnement', icon: '💳', visible: isAdmin.value && !isSuperAdmin.value },
    { id: 'company', label: 'Entreprise', icon: '🏢', visible: isAdmin.value && !isSuperAdmin.value },
    { id: 'companies', label: 'Entreprises', icon: '🏢', visible: isSuperAdmin.value },
    { id: 'subscriptions', label: 'Abonnements', icon: '💳', visible: isSuperAdmin.value },
    { id: 'settings', label: 'Paramètres', icon: '⚙️', visible: isSuperAdmin.value },
  ];
  return allTabs.filter(tab => tab.visible !== false);
});

const loadReports = async () => {
  try {
    if (props.profile.role === 'commercial') {
      reports.value = await reportsService.getMyReports(props.profile.id);
    } else {
      reports.value = await reportsService.getAllReports();
    }
  } catch (error) {
    console.error('Error loading reports:', error);
  }
};

const handleNewReport = () => {
  editingReport.value = null;
  isFormOpen.value = true;
};

const handleSaveReport = async (data: any) => {
  try {
    const reportData = {
      ...data,
      user_id: props.profile.id,
    };

    if (editingReport.value) {
      await reportsService.updateReport(editingReport.value.id, reportData);
    } else {
      await reportsService.createReport(reportData);
    }
    await loadReports();
    isFormOpen.value = false;
    editingReport.value = null;
  } catch (error) {
    console.error('Error saving report:', error);
    alert('Erreur lors de la sauvegarde du rapport');
  }
};

const handleSendWhatsApp = async (data: any) => {
  try {
    const reportData = {
      ...data,
      user_id: props.profile.id,
      status: 'envoye' as const,
    };

    let report: ReportDB;
    if (editingReport.value) {
      report = await reportsService.updateReport(editingReport.value.id, reportData);
    } else {
      report = await reportsService.createReport(reportData);
    }

    whatsappService.sendReport({
      id: report.id,
      date: report.date,
      prospects: report.prospects,
      nouveaux_prospects: report.nouveaux_prospects,
      comm_prospects: report.comm_prospects || '',
      commandes: report.commandes,
      ca: Number(report.ca),
      comm_commandes: report.comm_commandes || '',
      status: report.status,
      createdAt: new Date(report.created_at).getTime(),
      updatedAt: new Date(report.updated_at).getTime(),
    });

    await loadReports();
    isFormOpen.value = false;
    editingReport.value = null;
  } catch (error) {
    console.error('Error sending report:', error);
    alert('Erreur lors de l\'envoi du rapport');
  }
};

const handleEditReport = (report: Report) => {
  const dbReport = reports.value.find(r => r.id === report.id);
  if (dbReport) {
    editingReport.value = dbReport;
    isFormOpen.value = true;
  }
};

const handleDuplicateReport = async (report: Report) => {
  const today = new Date().toISOString().split('T')[0];
  const duplicatedData = {
    user_id: props.profile.id,
    date: today,
    prospects: report.prospects,
    nouveaux_prospects: report.nouveaux_prospects,
    comm_prospects: report.comm_prospects,
    commandes: report.commandes,
    ca: report.ca,
    comm_commandes: report.comm_commandes,
    status: 'brouillon' as const,
  };

  try {
    await reportsService.createReport(duplicatedData);
    await loadReports();
  } catch (error) {
    console.error('Error duplicating report:', error);
    alert('Erreur lors de la duplication du rapport');
  }
};

const handleSendWhatsAppFromList = (report: Report) => {
  whatsappService.sendReport(report);

  if (report.status !== 'envoye') {
    reportsService.updateReport(report.id, { status: 'envoye' });
    loadReports();
  }
};

const handlePrintReport = (report: Report) => {
  const printWindow = window.open('', '_blank');
  if (!printWindow) return;

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Rapport du ${new Date(report.date).toLocaleDateString('fr-FR')}</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          max-width: 800px;
          margin: 0 auto;
          padding: 40px 20px;
          line-height: 1.6;
        }
        .header {
          text-align: center;
          margin-bottom: 30px;
          padding-bottom: 20px;
          border-bottom: 3px solid #2563eb;
        }
        .header h1 {
          color: #2563eb;
          margin: 0 0 10px 0;
          font-size: 32px;
        }
        .header .date {
          font-size: 18px;
          color: #64748b;
        }
        .commercial-info {
          background-color: #f8fafc;
          padding: 15px;
          border-radius: 8px;
          margin-bottom: 30px;
        }
        .commercial-info h3 {
          margin: 0 0 10px 0;
          color: #1e293b;
          font-size: 16px;
        }
        .commercial-info p {
          margin: 5px 0;
          color: #475569;
        }
        .status-badge {
          display: inline-block;
          padding: 6px 16px;
          border-radius: 20px;
          font-weight: 600;
          font-size: 14px;
        }
        .status-envoye {
          background-color: #dcfce7;
          color: #166534;
        }
        .status-brouillon {
          background-color: #fef9c3;
          color: #854d0e;
        }
        .status-archive {
          background-color: #f1f5f9;
          color: #475569;
        }
        .section {
          margin: 30px 0;
          padding: 20px;
          background-color: #f8fafc;
          border-radius: 8px;
        }
        .section h2 {
          color: #1e293b;
          margin: 0 0 15px 0;
          font-size: 20px;
        }
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 20px;
          margin: 20px 0;
        }
        .stat-card {
          background: white;
          padding: 15px;
          border-radius: 8px;
          border: 1px solid #e2e8f0;
        }
        .stat-card .label {
          color: #64748b;
          font-size: 14px;
          margin-bottom: 5px;
        }
        .stat-card .value {
          color: #1e293b;
          font-size: 28px;
          font-weight: bold;
        }
        .stat-card .subtext {
          color: #94a3b8;
          font-size: 12px;
          margin-top: 5px;
        }
        .ca-highlight {
          background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
          color: white;
          padding: 20px;
          border-radius: 8px;
          text-align: center;
          margin: 20px 0;
        }
        .ca-highlight .label {
          font-size: 16px;
          opacity: 0.9;
          margin-bottom: 10px;
        }
        .ca-highlight .value {
          font-size: 36px;
          font-weight: bold;
        }
        .comment-box {
          background: white;
          padding: 15px;
          border-radius: 8px;
          border-left: 4px solid #2563eb;
          margin: 15px 0;
        }
        .comment-box h3 {
          margin: 0 0 10px 0;
          color: #1e293b;
          font-size: 16px;
        }
        .comment-box p {
          margin: 0;
          color: #475569;
          white-space: pre-wrap;
        }
        .footer {
          margin-top: 40px;
          padding-top: 20px;
          border-top: 1px solid #e2e8f0;
          text-align: center;
          color: #94a3b8;
          font-size: 12px;
        }
        @media print {
          body { padding: 20px; }
          .section { break-inside: avoid; }
        }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>Rapport d'Activité Commerciale</h1>
        <div class="date">${new Date(report.date).toLocaleDateString('fr-FR', {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        })}</div>
        <div style="margin-top: 15px;">
          <span class="status-badge status-${report.status}">
            ${report.status === 'envoye' ? 'Envoyé' : report.status === 'brouillon' ? 'Brouillon' : 'Archivé'}
          </span>
        </div>
      </div>

      ${report.commercial ? `
        <div class="commercial-info">
          <h3>Commercial</h3>
          <p><strong>${report.commercial.full_name}</strong></p>
          <p>${report.commercial.email}</p>
          ${report.commercial.phone ? `<p>${report.commercial.phone}</p>` : ''}
        </div>
      ` : ''}

      <div class="section">
        <h2>Activité Prospects</h2>
        <div class="stats-grid">
          <div class="stat-card">
            <div class="label">Prospects rencontrés</div>
            <div class="value">${report.prospects}</div>
          </div>
          <div class="stat-card">
            <div class="label">Nouveaux prospects</div>
            <div class="value">${report.nouveaux_prospects}</div>
            <div class="subtext">sur ${report.prospects} rencontrés</div>
          </div>
        </div>
        ${report.comm_prospects ? `
          <div class="comment-box">
            <h3>Commentaires</h3>
            <p>${report.comm_prospects}</p>
          </div>
        ` : ''}
      </div>

      <div class="section">
        <h2>Commandes et Chiffre d'Affaires</h2>
        <div class="stats-grid">
          <div class="stat-card">
            <div class="label">Commandes réalisées</div>
            <div class="value">${report.commandes}</div>
          </div>
        </div>
        <div class="ca-highlight">
          <div class="label">Chiffre d'Affaires</div>
          <div class="value">${report.ca.toLocaleString('fr-FR')} FCFA</div>
        </div>
        ${report.comm_commandes ? `
          <div class="comment-box">
            <h3>Commentaires</h3>
            <p>${report.comm_commandes}</p>
          </div>
        ` : ''}
      </div>

      <div class="footer">
        <p>Document généré le ${new Date().toLocaleDateString('fr-FR')} à ${new Date().toLocaleTimeString('fr-FR')}</p>
      </div>
    </body>
    </html>
  `;

  printWindow.document.write(html);
  printWindow.document.close();

  printWindow.onload = () => {
    setTimeout(() => {
      printWindow.print();
    }, 500);
  };

  setTimeout(() => {
    if (printWindow.document.readyState === 'complete') {
      printWindow.print();
    }
  }, 1000);
};

const handleDeleteReport = async (report: Report) => {
  if (confirm('Êtes-vous sûr de vouloir supprimer ce rapport ?')) {
    try {
      await reportsService.deleteReport(report.id);
      await loadReports();
    } catch (error) {
      console.error('Error deleting report:', error);
      alert('Erreur lors de la suppression du rapport');
    }
  }
};

const handleExportAll = () => {
  if (reports.value.length === 0) {
    alert('Aucun rapport à exporter');
    return;
  }

  const mappedReports = reports.value.map(r => ({
    id: r.id,
    date: r.date,
    prospects: r.prospects,
    nouveaux_prospects: r.nouveaux_prospects,
    comm_prospects: r.comm_prospects || '',
    commandes: r.commandes,
    ca: Number(r.ca),
    comm_commandes: r.comm_commandes || '',
    status: r.status,
    createdAt: new Date(r.created_at).getTime(),
    updatedAt: new Date(r.updated_at).getTime(),
  }));

  whatsappService.sendMultipleReports(mappedReports);
};

const handleCloseForm = () => {
  isFormOpen.value = false;
  editingReport.value = null;
};

const handleLogout = async () => {
  try {
    await authService.signOut();
    emit('logout');
  } catch (error) {
    console.error('Error logging out:', error);
  }
};

const selectTab = (tabId: any) => {
  activeTab.value = tabId;
  mobileMenuOpen.value = false;
};

const loadPendingOrdersCount = async () => {
  try {
    const orders = await ordersService.getOrders();
    pendingOrdersCount.value = orders.filter(order => order.status === 'pending').length;
  } catch (error) {
    console.error('Error loading pending orders count:', error);
  }
};

onMounted(() => {
  loadPendingOrdersCount();
});

loadReports();
</script>

<template>
  <div class="min-h-screen flex flex-col bg-gray-50">
    <header class="sticky top-0 z-50 bg-white border-b border-gray-200 shadow-sm">
      <div class="container mx-auto px-4 py-4">
        <div class="flex items-center justify-between gap-4">
          <button
            @click="mobileMenuOpen = !mobileMenuOpen"
            class="md:hidden bg-gray-100 p-2 rounded-lg hover:bg-gray-200 transition-colors text-gray-700"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
            </svg>
          </button>

          <div class="flex-1">
            <h1 class="text-xl md:text-2xl font-bold text-gray-900">Gestion commerciale</h1>
            <p class="text-gray-500 text-xs md:text-sm mt-1">
              {{ profile.full_name }} - {{ profile.role === 'admin' ? 'Administrateur' : profile.role === 'super_admin' ? 'Super Administrateur' : profile.role === 'superviseur' ? 'Superviseur' : 'Commercial' }}
            </p>
          </div>

          <button
            @click="handleLogout"
            class="hidden md:block bg-blue-600 text-white px-4 py-2 rounded-lg font-semibold hover:bg-blue-700 transition-colors"
          >
            Déconnexion
          </button>
        </div>

        <div class="hidden md:flex gap-2 mt-4 overflow-x-auto">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="activeTab = tab.id as any"
            :class="[
              'px-4 py-2 rounded-lg font-medium transition-all whitespace-nowrap relative',
              activeTab === tab.id
                ? 'bg-blue-600 text-white shadow-sm'
                : 'text-gray-600 hover:bg-gray-100'
            ]"
          >
            {{ tab.icon }} {{ tab.label }}
            <span
              v-if="tab.id === 'orders' && pendingOrdersCount > 0"
              class="ml-2 inline-flex items-center justify-center px-2 py-0.5 text-xs font-bold leading-none text-white bg-red-600 rounded-full"
            >
              {{ pendingOrdersCount }}
            </span>
          </button>
        </div>
      </div>
    </header>

    <div
      v-if="mobileMenuOpen"
      class="fixed inset-0 z-40 md:hidden"
      @click="mobileMenuOpen = false"
    >
      <div class="absolute inset-0 bg-black opacity-50"></div>
      <div
        class="absolute left-0 top-0 bottom-0 w-64 bg-white shadow-xl"
        @click.stop
      >
        <div class="p-4 bg-blue-600 text-white">
          <button
            @click="mobileMenuOpen = false"
            class="absolute top-4 right-4 text-white"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
          <h2 class="text-lg font-bold">Menu</h2>
          <p class="text-sm text-blue-100 mt-1">{{ profile.full_name }}</p>
        </div>
        <nav class="p-2">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="selectTab(tab.id)"
            :class="[
              'w-full text-left px-4 py-3 rounded-lg font-medium transition-all mb-1 flex items-center justify-between',
              activeTab === tab.id
                ? 'bg-blue-50 text-primary'
                : 'text-gray-700 hover:bg-gray-100'
            ]"
          >
            <span>{{ tab.icon }} {{ tab.label }}</span>
            <span
              v-if="tab.id === 'orders' && pendingOrdersCount > 0"
              class="inline-flex items-center justify-center px-2 py-0.5 text-xs font-bold leading-none text-white bg-red-600 rounded-full"
            >
              {{ pendingOrdersCount }}
            </span>
          </button>
          <div class="border-t border-gray-200 my-2"></div>
          <button
            @click="handleLogout"
            class="w-full text-left px-4 py-3 rounded-lg font-medium text-red-600 hover:bg-red-50 transition-all"
          >
            🚪 Déconnexion
          </button>
        </nav>
      </div>
    </div>

    <main class="flex-1 container mx-auto px-4 py-6 md:py-8">
      <DashboardView v-if="activeTab === 'dashboard'" :profile="profile" />

      <div v-if="activeTab === 'reports'">
        <div class="mb-6 flex justify-end gap-3">
          <button @click="handleNewReport" class="btn-primary">
            ➕ Nouveau rapport
          </button>
          <button @click="handleExportAll" class="btn-secondary">
            📤 Exporter tous
          </button>
        </div>

        <ReportForm
          :is-open="isFormOpen"
          :initial-data="editingReport ? {
            id: editingReport.id,
            date: editingReport.date,
            prospects: editingReport.prospects,
            nouveaux_prospects: editingReport.nouveaux_prospects,
            comm_prospects: editingReport.comm_prospects || '',
            commandes: editingReport.commandes,
            ca: Number(editingReport.ca),
            comm_commandes: editingReport.comm_commandes || '',
            status: editingReport.status,
            createdAt: new Date(editingReport.created_at).getTime(),
            updatedAt: new Date(editingReport.updated_at).getTime(),
          } : undefined"
          @save="handleSaveReport"
          @send-whats-app="handleSendWhatsApp"
          @close="handleCloseForm"
        />

        <ReportList
          :reports="reports.map(r => ({
            id: r.id,
            date: r.date,
            prospects: r.prospects,
            nouveaux_prospects: r.nouveaux_prospects,
            comm_prospects: r.comm_prospects || '',
            commandes: r.commandes,
            ca: Number(r.ca),
            comm_commandes: r.comm_commandes || '',
            status: r.status,
            createdAt: new Date(r.created_at).getTime(),
            updatedAt: new Date(r.updated_at).getTime(),
            commercial: r.commercial,
          }))"
          @edit="handleEditReport"
          @duplicate="handleDuplicateReport"
          @print="handlePrintReport"
          @send-whats-app="handleSendWhatsAppFromList"
          @delete="handleDeleteReport"
        />
      </div>

      <div v-if="activeTab === 'clients'">
        <div class="flex gap-2 mb-6 bg-white rounded-lg p-2 shadow-sm">
          <button
            @click="crmSubTab = 'clients'"
            :class="[
              'flex-1 px-4 py-2 rounded-lg font-medium transition-all',
              crmSubTab === 'clients'
                ? 'bg-primary text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            👥 Clients & Prospects
          </button>
          <button
            v-if="canManageCommercials"
            @click="crmSubTab = 'commercials'"
            :class="[
              'flex-1 px-4 py-2 rounded-lg font-medium transition-all',
              crmSubTab === 'commercials'
                ? 'bg-primary text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            👔 Commerciaux
          </button>
        </div>

        <ClientManagement v-if="crmSubTab === 'clients'" />
        <CommercialManagement v-if="crmSubTab === 'commercials'" :profile="profile" />
      </div>

      <OrderManagement v-if="activeTab === 'orders'" />
      <ProductManagement v-if="activeTab === 'stock'" />
      <CategoryManagement v-if="activeTab === 'categories'" />
      <UserManagement v-if="activeTab === 'users'" />
      <SubscriptionPlans v-if="activeTab === 'subscription-plans'" />
      <CompanySettings v-if="activeTab === 'company'" />
      <CompanyManagement v-if="activeTab === 'companies'" />
      <SubscriptionManagement v-if="activeTab === 'subscriptions'" />
      <SuperAdminSettings v-if="activeTab === 'settings'" />
    </main>

    <AppFooter />
  </div>
</template>
