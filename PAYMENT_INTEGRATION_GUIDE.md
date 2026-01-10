# Guide d'Intégration des Moyens de Paiement

Ce guide explique les nouvelles fonctionnalités de paiement intégrées à l'application.

## Fonctionnalités Ajoutées

### 1. Calcul des Revenus Basé sur les Paiements Réels

Le système calcule maintenant le chiffre d'affaires et les commissions en fonction des **montants réellement payés** plutôt que des montants totaux des commandes.

**Changements:**
- Dashboard: Affiche le CA basé sur les paiements reçus
- Recette du jour: Utilise les montants payés uniquement
- Commissions des commerciaux: Calculées sur les montants payés
- Top commerciaux/produits/clients: Basés sur les paiements réels

### 2. Intégration des Moyens de Paiement Mobiles

L'application supporte maintenant plusieurs méthodes de paiement locales:

#### Moyens de Paiement Supportés:
- **Wave** - Paiement mobile Wave
- **Orange Money** - Paiement mobile Orange
- **MTN Mobile Money** - Paiement mobile MTN
- **Moov Money** - Paiement mobile Moov
- **CinetPay** - Passerelle de paiement (déjà existant)

### 3. Configuration des Moyens de Paiement

Les administrateurs peuvent configurer les moyens de paiement depuis les **Paramètres de l'entreprise**.

#### Comment Configurer:

1. Allez dans **Paramètres** → **Moyens de paiement**
2. Cliquez sur **Configurer** pour le moyen de paiement souhaité
3. Renseignez les informations requises:
   - **Clé API**: Votre clé API du fournisseur
   - **Clé Secrète**: Votre clé secrète (si applicable)
   - **Merchant ID**: Votre identifiant marchand
   - **Mode test**: Activez pour tester sans vrais paiements
4. Cochez **Activer ce moyen de paiement**
5. Cliquez sur **Enregistrer**

### 4. Webhooks pour Notifications de Paiement

Deux webhooks ont été créés pour recevoir les notifications en temps réel:

#### Wave Webhook
- **URL**: `https://votre-projet.supabase.co/functions/v1/wave-webhook`
- **Utilisation**: Configurez cette URL dans votre tableau de bord Wave

#### Mobile Money Webhook
- **URL**: `https://votre-projet.supabase.co/functions/v1/mobile-money-webhook?provider={provider}`
- **Paramètres**: Remplacez `{provider}` par `orange_money`, `mtn_money`, ou `moov_money`
- **Utilisation**: Configurez cette URL dans les tableaux de bord respectifs

### 5. Génération de PDF des Reçus

Les reçus de paiement peuvent maintenant être:
- Téléchargés en PDF
- Envoyés par WhatsApp au client (avec téléchargement automatique du PDF)

## Obtenir vos Clés API

### Wave
1. Créez un compte sur [https://wave.com/](https://wave.com/)
2. Accédez à votre tableau de bord développeur
3. Créez une nouvelle application
4. Copiez votre **API Key**

### Orange Money
1. Inscrivez-vous sur [https://developer.orange.com/](https://developer.orange.com/)
2. Créez une application Orange Money
3. Obtenez vos clés API et Merchant ID

### MTN Mobile Money
1. Inscrivez-vous sur [https://momodeveloper.mtn.com/](https://momodeveloper.mtn.com/)
2. Créez une subscription pour Collection API
3. Obtenez vos clés API

### Moov Money
1. Contactez Moov Africa pour obtenir un compte marchand
2. Obtenez vos identifiants API

## Initier une Transaction de Paiement

### Interface de Paiement

Lorsqu'un client souhaite effectuer un paiement, deux options sont disponibles:

#### 1. Paiement Manuel
- Pour les paiements en espèces, chèques, virements
- Enregistrement manuel des informations de paiement
- Possibilité d'ajouter une référence et des notes

#### 2. Paiement en Ligne
- Disponible si au moins un moyen de paiement est configuré
- Le commercial peut initier directement le paiement
- Vérification automatique du statut en temps réel

### Comment Initier un Paiement en Ligne:

1. Dans la liste des commandes, cliquez sur **Ajouter un paiement**
2. Sélectionnez l'onglet **Paiement en ligne**
3. Entrez le montant à payer (ou cliquez sur "Solde" pour le montant total)
4. Choisissez le moyen de paiement (Wave, Orange Money, MTN, Moov)
5. Vérifiez le numéro de téléphone du client (pré-rempli si disponible)
6. Cliquez sur **Initier le paiement**

**Pour Wave:**
- Une nouvelle fenêtre s'ouvrira avec le formulaire de paiement Wave
- Le client finalise le paiement dans cette fenêtre
- Le statut est vérifié automatiquement toutes les 3 secondes

**Pour Mobile Money:**
- Le client reçoit une notification USSD sur son téléphone
- Il doit composer le code pour valider le paiement
- Le statut est vérifié automatiquement toutes les 3 secondes

### Vérification Automatique du Statut

- Le système vérifie automatiquement le statut du paiement
- Maximum 30 tentatives (1.5 minutes)
- Notification immédiate quand le paiement est confirmé
- La commande est automatiquement mise à jour

## Sécurité

- Les clés API sont stockées de manière sécurisée dans la base de données
- Seuls les administrateurs peuvent configurer les moyens de paiement
- Les webhooks vérifient l'authenticité des notifications
- Le mode test permet de tester sans risque

## Support

Pour toute question ou problème, contactez le support technique.
