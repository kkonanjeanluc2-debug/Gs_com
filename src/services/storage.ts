import { v4 as uuidv4 } from 'uuid';

export interface Report {
  id: string;
  date: string;
  prospects: number;
  nouveaux_prospects: number;
  comm_prospects: string;
  commandes: number;
  ca: number;
  comm_commandes: string;
  status: 'envoye' | 'brouillon' | 'archive';
  createdAt: number;
  updatedAt: number;
  commercial?: {
    full_name: string;
    email: string;
    phone?: string;
  };
}

const DB_NAME = 'rapports_commerciaux_db';
const STORE_NAME = 'rapports';
const DB_VERSION = 1;

class StorageService {
  private db: IDBDatabase | null = null;

  async init(): Promise<void> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          const objectStore = db.createObjectStore(STORE_NAME, { keyPath: 'id' });
          objectStore.createIndex('date', 'date', { unique: false });
          objectStore.createIndex('status', 'status', { unique: false });
          objectStore.createIndex('createdAt', 'createdAt', { unique: false });
        }
      };
    });
  }

  async createReport(reportData: Omit<Report, 'id' | 'createdAt' | 'updatedAt'>): Promise<Report> {
    if (!this.db) await this.init();

    const report: Report = {
      ...reportData,
      id: uuidv4(),
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.add(report);

      request.onsuccess = () => resolve(report);
      request.onerror = () => reject(request.error);
    });
  }

  async updateReport(id: string, updates: Partial<Report>): Promise<Report> {
    if (!this.db) await this.init();

    const existing = await this.getReport(id);
    if (!existing) throw new Error('Report not found');

    const updated: Report = {
      ...existing,
      ...updates,
      id: existing.id,
      createdAt: existing.createdAt,
      updatedAt: Date.now(),
    };

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.put(updated);

      request.onsuccess = () => resolve(updated);
      request.onerror = () => reject(request.error);
    });
  }

  async getReport(id: string): Promise<Report | null> {
    if (!this.db) await this.init();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readonly');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.get(id);

      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error);
    });
  }

  async getAllReports(): Promise<Report[]> {
    if (!this.db) await this.init();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readonly');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.getAll();

      request.onsuccess = () => {
        const reports = request.result.sort((a: Report, b: Report) => b.createdAt - a.createdAt);
        resolve(reports);
      };
      request.onerror = () => reject(request.error);
    });
  }

  async deleteReport(id: string): Promise<void> {
    if (!this.db) await this.init();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.delete(id);

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  async getReportsByDate(date: string): Promise<Report[]> {
    if (!this.db) await this.init();

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readonly');
      const store = transaction.objectStore(STORE_NAME);
      const index = store.index('date');
      const request = index.getAll(date);

      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  async getReportsByDateRange(startDate: string, endDate: string): Promise<Report[]> {
    const allReports = await this.getAllReports();
    return allReports.filter(report => report.date >= startDate && report.date <= endDate);
  }
}

export const storageService = new StorageService();
