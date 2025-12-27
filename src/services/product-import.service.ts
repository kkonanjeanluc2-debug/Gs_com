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

      for (let i = 0; i < data.length; i++) {
        const row = data[i];
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
    const sku = row['Code'] || row['SKU'] || row['code'] || row['sku'];
    const name = row['Désignation'] || row['Nom'] || row['designation'] || row['nom'] || row['name'];
    const price = parseFloat(row['Prix'] || row['price'] || '0');
    const stock = parseInt(row['Stock'] || row['stock'] || '0');

    if (!sku) {
      throw new Error('Code (SKU) manquant');
    }
    if (!name) {
      throw new Error('Désignation manquante');
    }
    if (isNaN(price) || price < 0) {
      throw new Error('Prix invalide');
    }
    if (isNaN(stock) || stock < 0) {
      throw new Error('Stock invalide');
    }

    const productData = {
      sku,
      name,
      price,
      stock_quantity: stock,
      description: null,
      min_stock: 0,
      category_id: null,
      subcategory_id: null,
      image_url: null,
    };

    await productsService.createProduct(productData);
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
