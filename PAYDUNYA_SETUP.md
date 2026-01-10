# Guide de Configuration PayDunya

PayDunya est un agrégateur de paiements africains qui permet d'accepter plusieurs moyens de paiement:
- Mobile Money (Orange, MTN, Moov, Airtel, etc.)
- Cartes bancaires (Visa, Mastercard)
- Virements bancaires

## Prérequis

1. Créer un compte marchand sur [PayDunya](https://paydunya.com)
2. Compléter la vérification KYC
3. Obtenir vos clés API

## Configuration

### 1. Obtenir les Clés API

Pour PayDunya, vous avez besoin de **3 clés différentes**:

#### Étape 1: Créer un compte
1. Allez sur [https://paydunya.com](https://paydunya.com) ou [https://app.paydunya.com](https://app.paydunya.com)
2. Créez un compte marchand
3. Complétez les informations de votre entreprise

#### Étape 2: Accéder aux clés API
1. Connectez-vous à votre compte PayDunya
2. Allez dans **Paramètres** → **Clés API** ou **API Keys**
3. Vous verrez 3 clés importantes:

**Les 3 clés requises:**

| Champ dans l'app | Nom dans PayDunya | Description |
|------------------|-------------------|-------------|
| **Clé API** | Master Key ou Public Key | Clé publique (commence souvent par "test_" en mode test) |
| **Clé Secrète** | Private Key ou Secret Key | Clé privée (à garder confidentielle) |
| **Merchant ID** | Token ou Store Token | Identifiant unique de votre boutique |

**IMPORTANT:** Tous les 3 champs sont obligatoires!

### 2. Configuration dans l'Application

1. Connectez-vous en tant qu'**Administrateur**
2. Allez dans **Paramètres** → **Moyens de paiement**
3. Sélectionnez **PayDunya**
4. Remplissez les champs:
   - **Clé API**: Votre Master Key
   - **Clé secrète**: Votre Private Key
   - **ID Marchand**: Votre Token
   - **Mode test**: Activé pour les tests, désactivé pour la production
5. Activez le moyen de paiement
6. Cliquez sur **Enregistrer**

### 3. Mode Test vs Production

**Mode Test (Sandbox):**
- Utilisez les clés de test de votre compte sandbox
- URL API: `https://app.paydunya.com/sandbox-api/v1`
- Aucun argent réel n'est débité
- Idéal pour tester l'intégration

**Mode Production:**
- Utilisez les clés de production
- URL API: `https://app.paydunya.com/api/v1`
- Transactions réelles
- Nécessite une vérification KYC complète

## Utilisation

### Initier un Paiement

1. Dans la liste des commandes, cliquez sur **Ajouter un paiement**
2. Sélectionnez l'onglet **Paiement en ligne**
3. Choisissez **PayDunya** comme moyen de paiement
4. Entrez le montant et le numéro de téléphone du client
5. Cliquez sur **Initier le paiement**
6. Une nouvelle fenêtre s'ouvrira avec le formulaire de paiement PayDunya
7. Le client choisit son moyen de paiement préféré et finalise

### Moyens de Paiement Disponibles

**Mobile Money:**
- Orange Money (CI, SN, ML, BF, etc.)
- MTN Mobile Money (CI, GH, UG, etc.)
- Moov Money (CI, BF, BJ, TG)
- Airtel Money (plusieurs pays)

**Cartes Bancaires:**
- Visa
- Mastercard

**Virements:**
- Virement bancaire local
- Virement SWIFT international

## Frais de Transaction

Les frais varient selon:
- Le pays
- Le moyen de paiement utilisé
- Le volume de transactions

Consultez votre contrat PayDunya pour les détails spécifiques.

## Webhooks

Le système est configuré automatiquement pour recevoir les notifications de paiement via webhook.

URL du webhook: `https://[votre-domaine].supabase.co/functions/v1/paydunya-webhook`

Cette URL est configurée automatiquement lors de l'initiation du paiement.

## Statuts des Paiements

- **pending**: Paiement en attente
- **completed**: Paiement confirmé
- **cancelled**: Paiement annulé par le client
- **failed**: Paiement échoué

## Sécurité

- Les clés API sont stockées de manière sécurisée dans la base de données
- Seuls les administrateurs peuvent voir et modifier les configurations
- Les webhooks sont vérifiés pour garantir l'authenticité
- Les transactions sont chiffrées de bout en bout

## Dépannage

### Le paiement ne s'initialise pas

1. Vérifiez que les clés API sont correctes
2. Vérifiez que le mode (test/production) correspond aux clés utilisées
3. Vérifiez que votre compte PayDunya est actif

### Le webhook ne fonctionne pas

1. Vérifiez que l'URL du webhook est accessible
2. Consultez les logs dans PayDunya Dashboard
3. Vérifiez les logs de l'application

### Le paiement reste en "pending"

1. Vérifiez le statut sur PayDunya Dashboard
2. Le client doit finaliser le paiement dans la fenêtre PayDunya
3. Attendez la notification webhook (peut prendre quelques minutes)

## Support

Pour toute question concernant PayDunya:
- Site web: [https://paydunya.com](https://paydunya.com)
- Documentation API: [https://paydunya.com/developers](https://paydunya.com/developers)
- Support: support@paydunya.com

## Limites

- Montant minimum: Variable selon le pays et le moyen de paiement
- Montant maximum: Variable selon le pays et le moyen de paiement
- Vérification KYC obligatoire pour les volumes importants
