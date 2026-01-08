# Configuration CinetPay - Système d'Abonnement

Ce guide explique comment configurer et utiliser le système d'abonnement avec paiements CinetPay (Wave, Mobile Money).

## Fonctionnalités

- **30 jours d'essai automatique** pour toutes les nouvelles entreprises
- **Plans d'abonnement** : Mensuel, Trimestriel, Annuel
- **Méthodes de paiement** : Wave, Orange Money, MTN Money, Moov Money, Mobile Money
- **Gestion automatique** : L'abonnement est activé automatiquement après paiement
- **Webhooks CinetPay** : Confirmation automatique des paiements

## Configuration

### 1. Obtenir les identifiants CinetPay

1. Créez un compte sur [CinetPay](https://cinetpay.com/)
2. Connectez-vous à votre tableau de bord
3. Récupérez vos identifiants API :
   - `API Key` : Votre clé API
   - `Site ID` : Identifiant de votre site

### 2. Configurer les variables d'environnement

Ajoutez vos identifiants CinetPay dans le fichier `.env` :

```env
VITE_CINETPAY_API_KEY=votre_cle_api_cinetpay
VITE_CINETPAY_SITE_ID=votre_site_id_cinetpay
```

### 3. Configurer l'URL de notification (Webhook)

Dans votre tableau de bord CinetPay, configurez l'URL de notification :

```
https://votre-domaine.supabase.co/functions/v1/cinetpay-webhook
```

Cette URL recevra les notifications de paiement de CinetPay.

## Fonctionnement

### Essai gratuit de 30 jours

Lorsqu'une nouvelle entreprise est créée et approuvée :
1. Elle reçoit automatiquement **30 jours d'essai gratuit**
2. La période d'essai commence dès l'approbation
3. Le statut de l'entreprise est défini sur `trial`

### Plans d'abonnement disponibles

| Plan | Durée | Prix (FCFA) | Économie |
|------|-------|-------------|----------|
| Mensuel | 30 jours | 15,000 | - |
| Trimestriel | 90 jours | 40,000 | 11% |
| Annuel | 365 jours | 150,000 | 17% |

### Processus de paiement

1. **Sélection du plan** : L'admin de l'entreprise choisit un plan dans l'onglet "Mon Abonnement"
2. **Saisie des informations** : Nom, prénom, email, téléphone, méthode de paiement
3. **Redirection vers CinetPay** : L'utilisateur est redirigé vers la page de paiement sécurisée
4. **Paiement** : L'utilisateur effectue le paiement via Wave ou Mobile Money
5. **Webhook** : CinetPay envoie une notification au serveur
6. **Activation automatique** : L'abonnement est activé et la date de fin est calculée

### États d'abonnement

- **trial** : Période d'essai active
- **active** : Abonnement payant actif
- **expired** : Abonnement expiré (essai ou payant)
- **suspended** : Entreprise suspendue par le super admin

## Utilisation

### Pour les entreprises (Admins)

1. Connectez-vous à votre compte admin
2. Accédez à l'onglet **Mon Abonnement**
3. Consultez votre statut actuel d'abonnement
4. Choisissez un plan et cliquez sur "Choisir ce plan"
5. Remplissez le formulaire de paiement
6. Procédez au paiement via Wave ou Mobile Money
7. Votre abonnement sera activé automatiquement

### Pour le Super Admin

Le Super Admin peut :
- Voir tous les paiements dans l'onglet "Abonnements"
- Accorder des périodes d'essai supplémentaires
- Activer/suspendre des entreprises
- Gérer les plans d'abonnement

## Architecture technique

### Base de données

#### Table `subscription_plans`
- Contient les plans d'abonnement disponibles
- Modifiable uniquement par le super admin

#### Table `payments`
- Historique de tous les paiements
- Lien avec les entreprises et les plans
- Stockage des données CinetPay pour traçabilité

#### Colonnes ajoutées à `companies`
- `trial_days` : Nombre de jours d'essai (par défaut : 30)
- `trial_end_date` : Date de fin d'essai
- `subscription_status` : Statut actuel
- `subscription_end_date` : Date de fin d'abonnement payant
- `blocked_reason` : Raison du blocage (si applicable)

### Edge Functions

#### `cinetpay-webhook`
- Reçoit les notifications de CinetPay
- Vérifie le montant et l'ID de transaction
- Met à jour le statut du paiement
- Active automatiquement l'abonnement

### Services

#### `cinetpay.service.ts`
- Gestion des plans d'abonnement
- Initialisation des paiements
- Historique des paiements
- Vérification des statuts

#### `subscription.service.ts`
- Gestion des périodes d'essai
- Activation/suspension d'entreprises
- Vérification des abonnements

## Sécurité

### Row Level Security (RLS)

- **subscription_plans** : Lecture publique, modification par super admin uniquement
- **payments** : Chaque entreprise voit uniquement ses propres paiements
- **Super admin** : Accès complet à tous les paiements

### Triggers automatiques

1. **set_company_trial_period()** : Définit automatiquement 30 jours d'essai
2. **activate_subscription_after_payment()** : Active l'abonnement après paiement réussi

## Tests

### Test du système d'essai

1. Créez une nouvelle entreprise via l'inscription
2. Approuvez l'entreprise (en tant que super admin)
3. Vérifiez que l'entreprise a reçu 30 jours d'essai

### Test du paiement (avec CinetPay en mode test)

1. Connectez-vous en tant qu'admin d'une entreprise
2. Allez dans "Mon Abonnement"
3. Choisissez un plan
4. Utilisez les identifiants de test CinetPay
5. Vérifiez que l'abonnement est activé

## Dépannage

### Le paiement n'est pas confirmé

1. Vérifiez les logs de l'Edge Function `cinetpay-webhook`
2. Vérifiez l'URL de notification dans le tableau de bord CinetPay
3. Assurez-vous que l'Edge Function est bien déployée

### L'essai n'est pas accordé automatiquement

1. Vérifiez que le trigger `set_company_trial_period` est actif
2. Vérifiez que l'entreprise est approuvée (`is_approved = true`)
3. Vérifiez les logs Supabase

### Les plans ne s'affichent pas

1. Vérifiez que la table `subscription_plans` contient des données
2. Vérifiez les permissions RLS sur `subscription_plans`
3. Vérifiez les variables d'environnement CinetPay

## Support

Pour toute question ou problème :
- Consultez la documentation CinetPay : https://docs.cinetpay.com/
- Vérifiez les logs Supabase
- Contactez le support CinetPay pour les problèmes de paiement
