import jsPDF from 'jspdf';
import type { Sale } from './sales.service';
import type { CompanySettings } from './company.service';

const formatAmount = (amount: number): string => {
  return Math.round(amount).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
};

export const saleReceiptService = {
  async generateA4Receipt(sale: Sale, company: CompanySettings): Promise<void> {
    const pdf = new jsPDF('p', 'mm', 'a4');
    const pageWidth = pdf.internal.pageSize.getWidth();
    const margin = 20;
    let yPos = 20;

    pdf.setFontSize(10);

    if (company.logo_url) {
      try {
        const img = new Image();
        img.crossOrigin = 'anonymous';
        await new Promise((resolve, reject) => {
          img.onload = resolve;
          img.onerror = reject;
          img.src = company.logo_url!;
        });
        pdf.addImage(img, 'PNG', margin, yPos, 30, 30);
      } catch (err) {
        console.error('Erreur chargement logo:', err);
      }
    }

    pdf.setFontSize(16);
    pdf.setFont('helvetica', 'bold');
    pdf.text(company.name, pageWidth / 2, yPos + 5, { align: 'center' });

    yPos += 12;
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'normal');
    if (company.address) pdf.text(company.address, pageWidth / 2, yPos, { align: 'center' });

    yPos += 5;
    if (company.phone) pdf.text(`Tél: ${company.phone}`, pageWidth / 2, yPos, { align: 'center' });

    yPos += 5;
    if (company.email) pdf.text(`Email: ${company.email}`, pageWidth / 2, yPos, { align: 'center' });

    yPos += 15;
    pdf.setLineWidth(0.5);
    pdf.line(margin, yPos, pageWidth - margin, yPos);

    yPos += 10;
    pdf.setFontSize(14);
    pdf.setFont('helvetica', 'bold');
    pdf.text('REÇU DE VENTE', pageWidth / 2, yPos, { align: 'center' });

    yPos += 10;
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'normal');
    pdf.text(`N° Vente: ${sale.sale_number}`, margin, yPos);
    pdf.text(`Date: ${new Date(sale.created_at!).toLocaleString('fr-FR')}`, pageWidth - margin, yPos, { align: 'right' });

    yPos += 8;
    pdf.text(`Client: ${sale.client?.name || 'N/A'}`, margin, yPos);
    if (sale.client?.phone) {
      yPos += 5;
      pdf.text(`Tél: ${sale.client.phone}`, margin, yPos);
    }

    yPos += 10;
    pdf.setLineWidth(0.3);
    pdf.line(margin, yPos, pageWidth - margin, yPos);

    yPos += 8;
    pdf.setFont('helvetica', 'bold');
    pdf.text('Désignation', margin, yPos);
    pdf.text('Qté', 100, yPos, { align: 'right' });
    pdf.text('P.U.', 125, yPos, { align: 'right' });
    pdf.text('Remise', 145, yPos, { align: 'right' });
    pdf.text('Total', pageWidth - margin, yPos, { align: 'right' });

    yPos += 5;
    pdf.line(margin, yPos, pageWidth - margin, yPos);

    yPos += 7;
    pdf.setFont('helvetica', 'normal');

    if (sale.sale_items) {
      for (const item of sale.sale_items) {
        if (yPos > 270) {
          pdf.addPage();
          yPos = 20;
        }

        const productName = item.product?.name || 'N/A';
        const lines = pdf.splitTextToSize(productName, 70);

        pdf.text(lines, margin, yPos);
        pdf.text(item.quantity.toString(), 100, yPos, { align: 'right' });
        pdf.text(`${formatAmount(item.unit_price)} F`, 125, yPos, { align: 'right' });
        pdf.text(`${item.discount_percentage}%`, 145, yPos, { align: 'right' });
        pdf.text(`${formatAmount(item.subtotal)} F`, pageWidth - margin, yPos, { align: 'right' });

        yPos += lines.length * 5 + 3;
      }
    }

    yPos += 5;
    pdf.setLineWidth(0.3);
    pdf.line(margin, yPos, pageWidth - margin, yPos);

    yPos += 8;
    pdf.setFont('helvetica', 'bold');

    if (sale.discount_amount && sale.discount_amount > 0) {
      pdf.text('Total avant remise:', 120, yPos);
      pdf.text(`${formatAmount(sale.total_amount)} F CFA`, pageWidth - margin, yPos, { align: 'right' });
      yPos += 6;
      pdf.setFont('helvetica', 'normal');
      pdf.text('Remise:', 120, yPos);
      pdf.text(`-${formatAmount(sale.discount_amount)} F CFA`, pageWidth - margin, yPos, { align: 'right' });
      yPos += 6;
      pdf.setFont('helvetica', 'bold');
    }

    pdf.setFontSize(12);
    pdf.text('TOTAL À PAYER:', 120, yPos);
    pdf.text(`${formatAmount(sale.final_amount)} F CFA`, pageWidth - margin, yPos, { align: 'right' });

    yPos += 10;
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'normal');
    pdf.text(`Mode de paiement: ${this.getPaymentMethodLabel(sale.payment_method)}`, margin, yPos);

    yPos += 5;
    pdf.text(`Statut: ${this.getPaymentStatusLabel(sale.payment_status)}`, margin, yPos);

    if (sale.notes) {
      yPos += 10;
      pdf.setFont('helvetica', 'italic');
      pdf.text('Notes:', margin, yPos);
      yPos += 5;
      const notesLines = pdf.splitTextToSize(sale.notes, pageWidth - 2 * margin);
      pdf.text(notesLines, margin, yPos);
    }

    yPos = pdf.internal.pageSize.getHeight() - 30;
    pdf.setLineWidth(0.3);
    pdf.line(margin, yPos, pageWidth - margin, yPos);

    yPos += 7;
    pdf.setFontSize(9);
    pdf.setFont('helvetica', 'normal');
    pdf.text('Merci pour votre confiance !', pageWidth / 2, yPos, { align: 'center' });

    if (company.rccm || company.ncc) {
      yPos += 5;
      let companyInfo = '';
      if (company.rccm) companyInfo += `RCCM: ${company.rccm}`;
      if (company.ncc) companyInfo += (companyInfo ? ' | ' : '') + `NCC: ${company.ncc}`;
      pdf.text(companyInfo, pageWidth / 2, yPos, { align: 'center' });
    }

    pdf.save(`vente_${sale.sale_number}_A4.pdf`);
  },

  async generateTicketReceipt(sale: Sale, company: CompanySettings): Promise<void> {
    const ticketWidth = 80;
    const pdf = new jsPDF({
      orientation: 'portrait',
      unit: 'mm',
      format: [ticketWidth, 297]
    });

    const margin = 5;
    let yPos = 10;

    pdf.setFontSize(11);
    pdf.setFont('helvetica', 'bold');
    const companyLines = pdf.splitTextToSize(company.name, ticketWidth - 10);
    pdf.text(companyLines, ticketWidth / 2, yPos, { align: 'center' });
    yPos += (companyLines.length - 1) * 4;

    yPos += 6;
    pdf.setFontSize(8);
    pdf.setFont('helvetica', 'normal');
    if (company.address) {
      const addressLines = pdf.splitTextToSize(company.address, ticketWidth - 2 * margin);
      pdf.text(addressLines, ticketWidth / 2, yPos, { align: 'center' });
      yPos += addressLines.length * 4;
    }

    if (company.phone) {
      pdf.text(`Tél: ${company.phone}`, ticketWidth / 2, yPos, { align: 'center' });
      yPos += 4;
    }

    if (company.email) {
      const emailLines = pdf.splitTextToSize(company.email, ticketWidth - 10);
      pdf.text(emailLines, ticketWidth / 2, yPos, { align: 'center' });
      yPos += emailLines.length * 3.5;
    }

    yPos += 3;
    pdf.setLineWidth(0.3);
    pdf.line(margin, yPos, ticketWidth - margin, yPos);

    yPos += 6;
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'bold');
    pdf.text('REÇU DE VENTE', ticketWidth / 2, yPos, { align: 'center' });

    yPos += 6;
    pdf.setFontSize(8);
    pdf.setFont('helvetica', 'normal');
    pdf.text(`N° ${sale.sale_number}`, ticketWidth / 2, yPos, { align: 'center' });

    yPos += 4;
    pdf.text(`${new Date(sale.created_at!).toLocaleString('fr-FR')}`, ticketWidth / 2, yPos, { align: 'center' });

    yPos += 5;
    pdf.line(margin, yPos, ticketWidth - margin, yPos);

    yPos += 5;
    const clientName = sale.client?.name || 'N/A';
    const clientLines = pdf.splitTextToSize(`Client: ${clientName}`, ticketWidth - 10);
    pdf.text(clientLines, margin, yPos);
    yPos += clientLines.length * 3.5;

    if (sale.client?.phone) {
      const phoneLines = pdf.splitTextToSize(`Tél: ${sale.client.phone}`, ticketWidth - 10);
      pdf.text(phoneLines, margin, yPos);
      yPos += phoneLines.length * 3.5;
    }

    yPos += 2;
    pdf.line(margin, yPos, ticketWidth - margin, yPos);

    yPos += 5;
    pdf.setFont('helvetica', 'bold');
    pdf.text('Article', margin, yPos);
    pdf.text('Total', ticketWidth - margin, yPos, { align: 'right' });

    yPos += 4;
    pdf.line(margin, yPos, ticketWidth - margin, yPos);

    yPos += 5;
    pdf.setFont('helvetica', 'normal');

    if (sale.sale_items) {
      for (const item of sale.sale_items) {
        const productName = item.product?.name || 'N/A';
        const lines = pdf.splitTextToSize(productName, ticketWidth - 10);

        pdf.text(lines, margin, yPos);
        yPos += lines.length * 3.5;

        const qtyPrice = `${item.quantity} x ${formatAmount(item.unit_price)} F`;
        pdf.text(qtyPrice, margin, yPos);

        pdf.setFont('helvetica', 'bold');
        pdf.text(`${formatAmount(item.subtotal)} F`, ticketWidth - margin, yPos, { align: 'right' });
        pdf.setFont('helvetica', 'normal');

        if (item.discount_percentage > 0) {
          yPos += 3;
          pdf.setFontSize(7);
          pdf.text(`Remise: -${item.discount_percentage}%`, margin, yPos);
          pdf.setFontSize(8);
        }

        yPos += 5;
      }
    }

    pdf.line(margin, yPos, ticketWidth - margin, yPos);

    yPos += 5;
    pdf.setFont('helvetica', 'bold');

    if (sale.discount_amount && sale.discount_amount > 0) {
      pdf.setFontSize(8);
      pdf.text('Sous-total:', margin, yPos);
      pdf.text(`${formatAmount(sale.total_amount)} F`, ticketWidth - margin, yPos, { align: 'right' });
      yPos += 4;
      pdf.setFont('helvetica', 'normal');
      pdf.text('Remise:', margin, yPos);
      pdf.text(`-${formatAmount(sale.discount_amount)} F`, ticketWidth - margin, yPos, { align: 'right' });
      yPos += 5;
      pdf.setFont('helvetica', 'bold');
    }

    pdf.setFontSize(10);
    pdf.text('TOTAL:', margin, yPos);
    pdf.text(`${formatAmount(sale.final_amount)} F`, ticketWidth - margin, yPos, { align: 'right' });

    yPos += 6;
    pdf.setFontSize(7);
    pdf.setFont('helvetica', 'normal');
    const paymentLines = pdf.splitTextToSize(`Paiement: ${this.getPaymentMethodLabel(sale.payment_method)}`, ticketWidth - 10);
    pdf.text(paymentLines, margin, yPos);
    yPos += paymentLines.length * 3;

    const statusLines = pdf.splitTextToSize(`Statut: ${this.getPaymentStatusLabel(sale.payment_status)}`, ticketWidth - 10);
    pdf.text(statusLines, margin, yPos);
    yPos += statusLines.length * 3;

    if (sale.notes) {
      yPos += 6;
      pdf.setFont('helvetica', 'italic');
      const notesLines = pdf.splitTextToSize(sale.notes, ticketWidth - 2 * margin);
      pdf.text(notesLines, margin, yPos);
      yPos += notesLines.length * 4;
    }

    yPos += 8;
    pdf.line(margin, yPos, ticketWidth - margin, yPos);

    yPos += 5;
    pdf.setFont('helvetica', 'bold');
    pdf.text('Merci pour votre confiance !', ticketWidth / 2, yPos, { align: 'center' });

    if (company.rccm || company.ncc) {
      yPos += 5;
      pdf.setFont('helvetica', 'normal');
      pdf.setFontSize(7);
      if (company.rccm) {
        pdf.text(`RCCM: ${company.rccm}`, ticketWidth / 2, yPos, { align: 'center' });
        yPos += 3;
      }
      if (company.ncc) {
        pdf.text(`NCC: ${company.ncc}`, ticketWidth / 2, yPos, { align: 'center' });
      }
    }

    pdf.save(`vente_${sale.sale_number}_ticket.pdf`);
  },

  getPaymentMethodLabel(method: string): string {
    const labels: Record<string, string> = {
      'especes': 'Espèces',
      'mobile_money': 'Mobile Money',
      'virement': 'Virement',
      'cheque': 'Chèque',
      'carte_bancaire': 'Carte bancaire',
      'wave': 'Wave',
      'orange_money': 'Orange Money',
      'mtn_money': 'MTN Money',
      'moov_money': 'Moov Money'
    };
    return labels[method] || method;
  },

  getPaymentStatusLabel(status: string): string {
    const labels: Record<string, string> = {
      'paye': 'Payé',
      'partiellement_paye': 'Partiellement payé',
      'en_attente': 'En attente'
    };
    return labels[status] || status;
  }
};
