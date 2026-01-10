export interface ProductField {
  name: string;
  label: string;
  type: 'text' | 'number' | 'select' | 'textarea' | 'date';
  required: boolean;
  placeholder?: string;
  options?: string[];
  description?: string;
}

export interface SectorConfig {
  sector: string;
  label: string;
  fields: ProductField[];
  specificColumns: string[];
}

class BusinessSectorConfigService {
  private configs: Record<string, SectorConfig> = {
    distribution: {
      sector: 'distribution',
      label: 'Distribution et commerce',
      specificColumns: ['reference', 'barcode', 'brand', 'supplier', 'min_stock', 'max_stock', 'reorder_point'],
      fields: [
        { name: 'reference', label: 'Référence', type: 'text', required: true, placeholder: 'REF-001' },
        { name: 'barcode', label: 'Code-barres', type: 'text', required: false, placeholder: '1234567890' },
        { name: 'brand', label: 'Marque', type: 'text', required: false, placeholder: 'Nom de la marque' },
        { name: 'supplier', label: 'Fournisseur', type: 'text', required: false, placeholder: 'Nom du fournisseur' },
        { name: 'min_stock', label: 'Stock minimum', type: 'number', required: false, placeholder: '10' },
        { name: 'max_stock', label: 'Stock maximum', type: 'number', required: false, placeholder: '1000' },
        { name: 'reorder_point', label: 'Seuil de réapprovisionnement', type: 'number', required: false, placeholder: '50' },
      ]
    },
    agroalimentaire: {
      sector: 'agroalimentaire',
      label: 'Agroalimentaire',
      specificColumns: ['reference', 'batch_number', 'expiry_date', 'production_date', 'certification', 'storage_conditions'],
      fields: [
        { name: 'reference', label: 'Référence produit', type: 'text', required: true, placeholder: 'REF-AGR-001' },
        { name: 'batch_number', label: 'Numéro de lot', type: 'text', required: false, placeholder: 'LOT-2024-001' },
        { name: 'expiry_date', label: 'Date de péremption', type: 'date', required: false },
        { name: 'production_date', label: 'Date de production', type: 'date', required: false },
        { name: 'certification', label: 'Certification', type: 'select', required: false,
          options: ['Bio', 'Halal', 'Kasher', 'Label Rouge', 'AOC', 'Aucune'] },
        { name: 'storage_conditions', label: 'Conditions de stockage', type: 'textarea', required: false,
          placeholder: 'Ex: Conserver au frais entre 2°C et 8°C' },
      ]
    },
    telecom_numerique: {
      sector: 'telecom_numerique',
      label: 'Télécom et services numériques',
      specificColumns: ['service_type', 'imei', 'serial_number', 'warranty_period', 'license_key'],
      fields: [
        { name: 'service_type', label: 'Type de service/produit', type: 'select', required: true,
          options: ['Téléphone mobile', 'Accessoire', 'Abonnement', 'Service', 'Logiciel', 'Matériel réseau'] },
        { name: 'imei', label: 'IMEI', type: 'text', required: false, placeholder: '123456789012345',
          description: 'Pour les téléphones mobiles' },
        { name: 'serial_number', label: 'Numéro de série', type: 'text', required: false, placeholder: 'SN-123456' },
        { name: 'warranty_period', label: 'Période de garantie (mois)', type: 'number', required: false, placeholder: '12' },
        { name: 'license_key', label: 'Clé de licence', type: 'text', required: false,
          description: 'Pour les logiciels' },
      ]
    },
    pharmacie_sante: {
      sector: 'pharmacie_sante',
      label: 'Pharmacie et santé',
      specificColumns: ['drug_code', 'dci', 'dosage', 'form', 'expiry_date', 'batch_number', 'prescription_required', 'storage_temperature'],
      fields: [
        { name: 'drug_code', label: 'Code médicament', type: 'text', required: true, placeholder: 'MED-001' },
        { name: 'dci', label: 'DCI (Dénomination Commune Internationale)', type: 'text', required: false,
          placeholder: 'Paracétamol' },
        { name: 'dosage', label: 'Dosage', type: 'text', required: false, placeholder: '500mg' },
        { name: 'form', label: 'Forme pharmaceutique', type: 'select', required: false,
          options: ['Comprimé', 'Gélule', 'Sirop', 'Injection', 'Pommade', 'Suppositoire', 'Autre'] },
        { name: 'expiry_date', label: 'Date de péremption', type: 'date', required: true },
        { name: 'batch_number', label: 'Numéro de lot', type: 'text', required: false, placeholder: 'LOT-2024-001' },
        { name: 'prescription_required', label: 'Ordonnance obligatoire', type: 'select', required: true,
          options: ['Oui', 'Non'] },
        { name: 'storage_temperature', label: 'Température de stockage', type: 'text', required: false,
          placeholder: 'Ex: Entre 15°C et 25°C' },
      ]
    },
    btp: {
      sector: 'btp',
      label: 'Bâtiment et travaux publics',
      specificColumns: ['reference', 'material_type', 'unit', 'brand', 'technical_specs', 'certification'],
      fields: [
        { name: 'reference', label: 'Référence', type: 'text', required: true, placeholder: 'BTP-001' },
        { name: 'material_type', label: 'Type de matériau', type: 'select', required: true,
          options: ['Ciment', 'Fer à béton', 'Brique', 'Peinture', 'Tuyauterie', 'Électricité', 'Bois', 'Autre'] },
        { name: 'unit', label: 'Unité de mesure', type: 'select', required: true,
          options: ['Kg', 'Tonne', 'Sac', 'Mètre', 'M²', 'M³', 'Litre', 'Pièce', 'Rouleau'] },
        { name: 'brand', label: 'Marque', type: 'text', required: false, placeholder: 'Nom de la marque' },
        { name: 'technical_specs', label: 'Spécifications techniques', type: 'textarea', required: false,
          placeholder: 'Caractéristiques techniques du matériau' },
        { name: 'certification', label: 'Certification/Norme', type: 'text', required: false,
          placeholder: 'Ex: NF, CE' },
      ]
    },
    transport_logistique: {
      sector: 'transport_logistique',
      label: 'Transport et logistique',
      specificColumns: ['vehicle_registration', 'vehicle_type', 'capacity', 'fuel_type', 'insurance_expiry', 'technical_control_date'],
      fields: [
        { name: 'vehicle_registration', label: 'Immatriculation', type: 'text', required: false,
          placeholder: 'AA-1234-AB' },
        { name: 'vehicle_type', label: 'Type de véhicule', type: 'select', required: false,
          options: ['Camion', 'Fourgon', 'Voiture', 'Moto', 'Remorque', 'Container', 'Autre'] },
        { name: 'capacity', label: 'Capacité de charge', type: 'text', required: false,
          placeholder: 'Ex: 5 tonnes, 20m³' },
        { name: 'fuel_type', label: 'Type de carburant', type: 'select', required: false,
          options: ['Essence', 'Diesel', 'Électrique', 'Hybride', 'GPL'] },
        { name: 'insurance_expiry', label: 'Date d\'expiration assurance', type: 'date', required: false },
        { name: 'technical_control_date', label: 'Date contrôle technique', type: 'date', required: false },
      ]
    },
    services: {
      sector: 'services',
      label: 'Services (nettoyage, sécurité, maintenance)',
      specificColumns: ['service_type', 'duration', 'equipment_required', 'certification', 'team_size'],
      fields: [
        { name: 'service_type', label: 'Type de service', type: 'select', required: true,
          options: ['Nettoyage', 'Sécurité', 'Maintenance', 'Jardinage', 'Plomberie', 'Électricité', 'Autre'] },
        { name: 'duration', label: 'Durée (heures)', type: 'number', required: false, placeholder: '2' },
        { name: 'equipment_required', label: 'Équipement nécessaire', type: 'textarea', required: false,
          placeholder: 'Liste des équipements requis pour le service' },
        { name: 'certification', label: 'Certification requise', type: 'text', required: false,
          placeholder: 'Ex: Habilitation électrique' },
        { name: 'team_size', label: 'Taille de l\'équipe', type: 'number', required: false, placeholder: '2',
          description: 'Nombre de personnes nécessaires' },
      ]
    }
  };

  getSectorConfig(sector: string): SectorConfig | null {
    return this.configs[sector] || null;
  }

  getAllSectors(): SectorConfig[] {
    return Object.values(this.configs);
  }

  getSectorLabel(sector: string): string {
    const config = this.getSectorConfig(sector);
    return config ? config.label : sector;
  }

  getSectorFields(sector: string): ProductField[] {
    const config = this.getSectorConfig(sector);
    return config ? config.fields : [];
  }
}

export const businessSectorConfigService = new BusinessSectorConfigService();
