import * as XLSX from 'xlsx';
import { productsService } from './products.service';

export interface ImportProduct {
  sku: string;
  name: string;
  price: number;
  stock_quantity: number;
  category?: string;
  subcategory?: string;
}

export interface ImportResult {
  success: number;
  failed: number;
  errors: string[];
}

class ProductImportService {
  async importFromExcel(file: File): Promise<ImportResult> {
    const result: ImportResult = {
      success: 0,
      failed: 0,
      errors: [],
    };

    try {
      const data = await this.readExcelFile(file);

      if (data.length === 0) {
        result.errors.push('Le fichier est vide ou ne contient pas de données');
        return result;
      }

      for (let i = 0; i < data.length; i++) {
        const row = data[i];

        if (this.isEmptyRow(row)) {
          continue;
        }

        try {
          await this.importProduct(row);
          result.success++;
        } catch (error) {
          result.failed++;
          const errorMessage = error instanceof Error ? error.message : 'Erreur inconnue';
          result.errors.push(`Ligne ${i + 2}: ${errorMessage}`);
        }
      }
    } catch (error) {
      result.errors.push(error instanceof Error ? error.message : 'Erreur de lecture du fichier');
    }

    return result;
  }

  private isEmptyRow(row: any): boolean {
    if (!row || typeof row !== 'object') return true;
    return Object.values(row).every(value =>
      value === null || value === undefined || value === ''
    );
  }

  private async readExcelFile(file: File): Promise<any[]> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();

      reader.onload = (e) => {
        try {
          const data = e.target?.result;
          const workbook = XLSX.read(data, { type: 'binary' });
          const firstSheetName = workbook.SheetNames[0];
          const worksheet = workbook.Sheets[firstSheetName];
          const jsonData = XLSX.utils.sheet_to_json(worksheet);
          resolve(jsonData);
        } catch (error) {
          reject(new Error('Erreur lors de la lecture du fichier Excel'));
        }
      };

      reader.onerror = () => {
        reject(new Error('Erreur lors de la lecture du fichier'));
      };

      reader.readAsBinaryString(file);
    });
  }

  private async importProduct(row: any): Promise<void> {
    const sku = this.findValue(row, ['Code', 'SKU', 'code', 'sku', 'Référence', 'référence', 'ref', 'Ref']) || this.generateSKU();
    const name = this.findValue(row, ['Désignation', 'Nom', 'designation', 'nom', 'name', 'Name', 'Produit', 'produit', 'Article', 'article']) || 'Produit sans nom';
    const priceValue = this.findValue(row, ['Prix', 'price', 'Price', 'PRIX', 'Montant', 'montant', 'Tarif', 'tarif']) || '0';
    const stockValue = this.findValue(row, ['Stock', 'stock', 'STOCK', 'Quantité', 'quantité', 'Qty', 'qty', 'Qté', 'qté']) || '0';

    let price = 0;
    let stock = 0;

    try {
      const cleanPrice = priceValue.toString().replace(/\s/g, '').replace(',', '.');
      price = parseFloat(cleanPrice);
      if (isNaN(price)) {
        price = 0;
      }
    } catch {
      price = 0;
    }

    try {
      const cleanStock = stockValue.toString().replace(/\s/g, '');
      stock = parseInt(cleanStock);
      if (isNaN(stock)) {
        stock = 0;
      }
    } catch {
      stock = 0;
    }

    const productData = {
      name,
      price: Math.max(0, price),
      stock_quantity: Math.max(0, stock),
    };

    const existingProduct = await productsService.getProductBySku(sku);

    if (existingProduct) {
      await productsService.updateProduct(existingProduct.id, productData);
    } else {
      await productsService.createProduct({
        ...productData,
        sku,
        description: null,
        min_stock: 0,
        category_id: null,
        subcategory_id: null,
        image_url: null,
      });
    }
  }

  private findValue(row: any, possibleKeys: string[]): any {
    for (const key of possibleKeys) {
      if (row[key] !== undefined && row[key] !== null && row[key] !== '') {
        return row[key];
      }
    }
    return null;
  }

  private generateSKU(): string {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 7);
    return `PROD-${timestamp}-${random}`.toUpperCase();
  }

  validateFile(file: File): { valid: boolean; error?: string } {
    const validExtensions = ['.xlsx', '.xls'];
    const fileName = file.name.toLowerCase();
    const hasValidExtension = validExtensions.some(ext => fileName.endsWith(ext));

    if (!hasValidExtension) {
      return {
        valid: false,
        error: 'Format de fichier non supporté. Veuillez utiliser un fichier Excel (.xlsx ou .xls)',
      };
    }

    if (file.size > 10 * 1024 * 1024) {
      return {
        valid: false,
        error: 'Le fichier est trop volumineux (max. 10 MB)',
      };
    }

    return { valid: true };
  }

  generateTemplate(): void {
    const template = [
      {
        Code: 'PROD001',
        Désignation: 'Exemple de produit',
        Prix: 5000,
        Stock: 100,
      },
    ];

    const worksheet = XLSX.utils.json_to_sheet(template);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Produits');

    XLSX.writeFile(workbook, 'modele_import_produits.xlsx');
  }
}

export const productImportService = new ProductImportService();
