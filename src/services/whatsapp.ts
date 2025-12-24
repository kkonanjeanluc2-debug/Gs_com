import type { Report } from './storage';
import { companyService } from './company.service';

const DEFAULT_PHONE = '+225XXXXXXXXXX';

export class WhatsAppService {
  async getPhoneNumber(): Promise<string> {
    try {
      const settings = await companyService.getSettings();
      if (settings?.phone) {
        return settings.phone;
      }
    } catch (error) {
      console.error('Error getting company phone:', error);
    }
    return DEFAULT_PHONE;
  }

  formatReport(report: Report): string {
    const date = new Date(report.date).toLocaleDateString('fr-FR', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });

    let message = `*RAPPORT JOURNALIER - ${date}*\n\n`;
    message += `📞 *Prospects rencontrés:* ${report.prospects}\n`;
    message += `💬 *Nouveaux prospects:* ${report.nouveaux_prospects}\n`;

    if (report.comm_prospects) {
      message += `📝 *Commentaires prospects:*\n${report.comm_prospects}\n\n`;
    }

    message += `🛒 *Commandes du jour:* ${report.commandes}\n`;
    message += `💰 *CA réalisé:* ${this.formatCurrency(report.ca)} FCFA\n`;

    if (report.comm_commandes) {
      message += `📝 *Commentaires commandes:*\n${report.comm_commandes}`;
    }

    return message;
  }

  formatMultipleReports(reports: Report[]): string {
    const startDate = new Date(reports[reports.length - 1].date).toLocaleDateString('fr-FR');
    const endDate = new Date(reports[0].date).toLocaleDateString('fr-FR');

    let message = `*RAPPORTS COMMERCIAUX*\n`;
    message += `*Période:* ${startDate} - ${endDate}\n\n`;

    const totalProspects = reports.reduce((sum, r) => sum + r.prospects, 0);
    const totalNouveaux = reports.reduce((sum, r) => sum + r.nouveaux_prospects, 0);
    const totalCommandes = reports.reduce((sum, r) => sum + r.commandes, 0);
    const totalCA = reports.reduce((sum, r) => sum + r.ca, 0);

    message += `📊 *SYNTHÈSE GLOBALE*\n`;
    message += `📞 Total prospects: ${totalProspects}\n`;
    message += `💬 Nouveaux prospects: ${totalNouveaux}\n`;
    message += `🛒 Total commandes: ${totalCommandes}\n`;
    message += `💰 CA total: ${this.formatCurrency(totalCA)} FCFA\n\n`;

    message += `📋 *DÉTAIL PAR JOUR*\n`;
    reports.forEach(report => {
      const date = new Date(report.date).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' });
      message += `\n*${date}:* ${report.prospects} prospects | ${report.commandes} cmd | ${this.formatCurrency(report.ca)} FCFA`;
    });

    return message;
  }

  private formatCurrency(amount: number): string {
    return amount.toLocaleString('fr-FR');
  }

  private encodeMessage(message: string): string {
    return encodeURIComponent(message);
  }

  async sendReport(report: Report): Promise<void> {
    const phoneNumber = await this.getPhoneNumber();
    const message = this.formatReport(report);
    const url = `https://wa.me/${phoneNumber}?text=${this.encodeMessage(message)}`;
    window.open(url, '_blank');
  }

  async sendMultipleReports(reports: Report[]): Promise<void> {
    const phoneNumber = await this.getPhoneNumber();
    const message = this.formatMultipleReports(reports);
    const url = `https://wa.me/${phoneNumber}?text=${this.encodeMessage(message)}`;
    window.open(url, '_blank');
  }
}

export const whatsappService = new WhatsAppService();
