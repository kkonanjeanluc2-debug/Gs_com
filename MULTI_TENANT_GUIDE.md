# Guide Multi-Tenant (Multi-Entreprise)

## Vue d'ensemble

L'application supporte maintenant le multi-tenant, permettant à plusieurs entreprises d'utiliser l'application de manière totalement indépendante. Chaque entreprise a ses propres:
- Utilisateurs (administrateurs, superviseurs, commerciaux)
- Clients et prospects
- Produits et catégories
- Commandes
- Rapports et données

## Architecture

### Table Companies

Chaque entreprise est représentée par un enregistrement dans la table `companies`:

```sql
companies
├── id (uuid)
├── name (text) - Nom de l'entreprise
├── email (text) - Email de contact
├── phone (text) - Téléphone WhatsApp
├── address (text) - Adresse
├── logo_url (text) - URL du logo
├── website (text) - Site web
├── tax_id (text) - N° SIRET/TVA
├── rccm (text) - N° RCCM
├── ncc (text) - N° NCC
├── status (text) - active, suspended, inactive
├── subscription_plan (text) - free, basic, premium
├── max_users (integer) - Nombre max d'utilisateurs
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

### Isolation des données

Toutes les tables principales ont un champ `company_id` qui référence l'entreprise:
- `profiles` - Utilisateurs
- `products` - Produits
- `categories` - Catégories
- `subcategories` - Sous-catégories
- `clients` - Clients et prospects
- `orders` - Commandes
- `order_items` - Lignes de commande
- `reports` - Rapports commerciaux
- `stock_movements` - Mouvements de stock

### Sécurité (RLS)

Les politiques de sécurité (Row Level Security) garantissent que:
1. Chaque utilisateur ne peut accéder qu'aux données de son entreprise
2. Un administrateur ne peut gérer que les utilisateurs de son entreprise
3. Aucun accès croisé entre entreprises n'est possible

## Inscription d'une nouvelle entreprise

### Pour l'utilisateur

1. Accéder à la page d'inscription: `/#/register`
2. Remplir les informations de l'entreprise
3. Créer le compte administrateur
4. Se connecter avec les identifiants créés

### Ce qui se passe en arrière-plan

L'edge function `register-company`:
1. Vérifie que l'email de l'entreprise n'est pas déjà utilisé
2. Crée l'enregistrement dans la table `companies`
3. Crée le compte utilisateur via Supabase Auth
4. Crée le profil dans la table `profiles` avec:
   - `role: 'admin'`
   - `company_id: [ID de l'entreprise]`
5. En cas d'erreur, annule toutes les opérations (rollback)

## Gestion des utilisateurs

### Administrateur
- Peut créer des superviseurs et des commerciaux
- Peut gérer tous les utilisateurs de son entreprise
- Peut modifier les paramètres de l'entreprise
- Accès complet aux données de l'entreprise

### Superviseur
- Peut voir toutes les données de l'entreprise
- Peut gérer les produits et le stock
- Peut voir tous les clients et commandes
- Ne peut pas créer d'autres utilisateurs

### Commercial
- Accès uniquement à ses propres clients et prospects
- Peut créer des rapports de visite
- Peut créer des commandes pour ses clients
- Vue limitée du stock

## Fonctions utiles

### Récupérer l'entreprise de l'utilisateur connecté

```typescript
import { companiesService } from './services/companies.service';

const company = await companiesService.getCurrentCompany();
console.log(company.name); // Nom de l'entreprise
```

### Créer un nouvel utilisateur dans l'entreprise

Les administrateurs peuvent créer des utilisateurs via:
- La page "Gestion des Utilisateurs" dans le dashboard
- L'edge function `create-user` qui assigne automatiquement le `company_id`

## Migration des données existantes

Si vous aviez des données avant la mise en place du multi-tenant:
1. Une entreprise par défaut a été créée automatiquement
2. Toutes les données existantes ont été assignées à cette entreprise
3. Tous les utilisateurs existants ont été liés à cette entreprise

## Limitations par plan

### Plan Free (Gratuit)
- Maximum 5 utilisateurs
- Toutes les fonctionnalités de base

### Plan Basic
- Maximum 20 utilisateurs
- Support prioritaire

### Plan Premium
- Utilisateurs illimités
- Fonctionnalités avancées
- Support dédié

## Notes importantes

1. **Isolation totale**: Il n'y a aucun moyen pour une entreprise d'accéder aux données d'une autre
2. **Un utilisateur = Une entreprise**: Un utilisateur ne peut appartenir qu'à une seule entreprise
3. **Suppression en cascade**: Si une entreprise est supprimée, toutes ses données sont supprimées
4. **Email unique**: Chaque entreprise doit avoir un email unique

## Troubleshooting

### L'utilisateur ne voit pas ses données
- Vérifier que `company_id` est bien défini dans son profil
- Vérifier que les données ont le bon `company_id`

### Erreur lors de la création d'utilisateur
- Vérifier que le nombre maximum d'utilisateurs n'est pas atteint
- Vérifier que l'utilisateur qui crée a le rôle 'admin'

### Les RLS policies bloquent les opérations
- Vérifier que l'utilisateur est bien authentifié
- Vérifier que `company_id` correspond dans toutes les tables liées
