# Configuration de Dexchange - Guide d'Installation

## À propos de Dexchange

Dexchange est une passerelle de paiement africaine qui permet d'accepter et d'envoyer des paiements via plusieurs moyens de paiement mobile money (Orange Money, MTN Money, Moov Money, Wave) en Afrique de l'Ouest, notamment en Côte d'Ivoire et au Sénégal.

## Prérequis

1. Créer un compte Dexchange sur [https://dexchange.sn](https://dexchange.sn)
2. Obtenir vos identifiants API depuis le tableau de bord Dexchange

## Étape 1: Obtenir les clés API Dexchange

1. Connectez-vous à votre tableau de bord Dexchange
2. Allez dans **API → Clés API**
3. Copiez votre **Bearer Token** (clé d'API)
4. Notez l'URL de l'API:
   - **Test (Sandbox)**: `https://api-m.dexchange.sn/api/v1`
   - **Production**: `https://api-m.dexchange.sn/api/v1`

## Étape 2: Configuration dans l'Application

### Via l'interface administrateur

1. Connectez-vous avec un compte **Admin** ou **Super Admin**
2. Allez dans **Paramètres → Moyens de Paiement**
3. Trouvez **Dexchange** dans la liste
4. Cliquez sur **Configurer**
5. Remplissez les champs suivants:
   - **Activer ce moyen de paiement**: Cochez la case
   - **Clé API**: Collez votre Bearer Token Dexchange
   - **Service Code (optionnel)**: Code du service par défaut (ex: `OM_CI_CASHOUT` pour Orange Money Côte d'Ivoire)
   - **Mode test (Sandbox)**: Cochez si vous testez, décochez pour la production
6. Cliquez sur **Enregistrer**

## Étape 3: Codes de Service Disponibles

Dexchange utilise des codes de service spécifiques pour chaque opérateur et pays. Voici quelques exemples:

### Côte d'Ivoire
- `OM_CI_CASHOUT` - Orange Money Côte d'Ivoire (Retrait)
- `MTN_CI_CASHOUT` - MTN Mobile Money Côte d'Ivoire
- `MOOV_CI_CASHOUT` - Moov Money Côte d'Ivoire
- `WAVE_CI_CASHOUT` - Wave Côte d'Ivoire
- `DEXCHANGE` - 

### Sénégal
- `OM_SN_CASHOUT` - Orange Money Sénégal
- `FREE_SN_CASHOUT` - Free Money Sénégal
- `WAVE_SN_CASHOUT` - Wave Sénégal

**Note**: Consultez la documentation Dexchange pour la liste complète des codes de service disponibles.

## Étape 4: Configuration du Webhook

Le webhook Dexchange est automatiquement configuré lors de l'initiation d'une transaction. L'URL du webhook est:

```
https://votre-domaine.supabase.co/functions/v1/dexchange-webhook
```

Cette URL est automatiquement fournie lors de chaque transaction et permet à Dexchange de notifier votre application du statut des paiements.

## Étape 5: Test de l'Intégration

1. Allez dans **Commandes**
2. Créez une nouvelle commande ou sélectionnez une commande existante
3. Cliquez sur **Ajouter un paiement**
4. Sélectionnez l'onglet **Paiement en ligne**
5. Choisissez **Dexchange**
6. Entrez le montant et le numéro de téléphone du client
7. Cliquez sur **Initier le paiement**
8. Une fenêtre s'ouvrira pour finaliser le paiement

## Fonctionnement Technique

### Initiation du Paiement

L'application effectue un appel à l'API Dexchange pour créer une transaction:

```
POST https://api-m.dexchange.sn/api/v1/transaction/init
Authorization: Bearer VOTRE_API_KEY
```

Paramètres:
- `externalTransactionId`: ID unique de votre commande
- `serviceCode`: Code du service (ex: OM_CI_CASHOUT)
- `amount`: Montant en FCFA (min: 200, max: 1,000,000)
- `number`: Numéro de téléphone du client
- `callBackURL`: URL du webhook pour les notifications
- `successUrl`: URL de redirection après succès
- `failureUrl`: URL de redirection après échec

### Notification par Webhook

Lorsque le paiement est confirmé, Dexchange envoie une notification à votre webhook avec les informations suivantes:

```json
{
  "id": "TID123456789",
  "externalTransactionId": "ORDER-001",
  "STATUS": "SUCCESS",
  "AMOUNT": 1000,
  "PHONE_NUMBER": "0701234567"
}
```

L'application traite automatiquement cette notification et enregistre le paiement dans la base de données.

## Limites et Contraintes

- **Montant minimum**: 200 FCFA
- **Montant maximum**: 1,000,000 FCFA par transaction
- **Format du numéro**: 10 chiffres (exemple: 0701234567)

## Support

Pour toute question concernant Dexchange:
- Documentation: [https://docs-api.dexchange.sn](https://docs-api.dexchange.sn)
- Support Dexchange: Contactez votre gestionnaire de compte Dexchange

## Migration depuis PayDunya

Si vous utilisiez précédemment PayDunya:
1. Toutes les références à PayDunya ont été remplacées par Dexchange
2. Vous devez reconfigurer Dexchange avec vos nouvelles clés API
3. Les anciennes transactions PayDunya restent accessibles dans l'historique
4. Les nouveaux paiements utilisent automatiquement Dexchange

## Résolution des Problèmes

### Le paiement ne s'initie pas
- Vérifiez que votre Bearer Token est correct
- Vérifiez que le service code est valide
- Assurez-vous que le montant est entre 200 et 1,000,000 FCFA
- Vérifiez le format du numéro de téléphone

### Le webhook ne fonctionne pas
- L'URL du webhook est automatiquement configurée
- Vérifiez les logs dans Supabase → Edge Functions
- Contactez le support Dexchange pour vérifier la configuration

### Mode test vs Production
- En mode test, utilisez les numéros de test fournis par Dexchange
- En production, utilisez de vrais numéros de téléphone
- Basculez entre les modes dans Paramètres → Moyens de Paiement
