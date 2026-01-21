# Guide du Mode Hors Ligne

L'application supporte maintenant le mode hors ligne complet avec synchronisation automatique des données.

## Fonctionnalités

### 1. Détection de Connexion
- Détection automatique de l'état de connexion (online/offline)
- Indicateur visuel en temps réel dans l'interface

### 2. Stockage Local
- Utilisation d'IndexedDB pour stocker les données localement
- Cache automatique des données lors de la connexion
- Accès aux données même sans connexion

### 3. Synchronisation Automatique
- Synchronisation automatique toutes les 30 secondes quand connecté
- Synchronisation immédiate lors du retour de connexion
- File d'attente pour les opérations en attente

### 4. Indicateurs Visuels
L'application affiche différents indicateurs selon l'état :

#### Mode Hors Ligne (Jaune)
```
Mode Hors ligne
X opération(s) en attente
```
Indique que vous êtes hors ligne et combien d'opérations attendent la synchronisation.

#### Synchronisation en Cours (Bleu)
```
Synchronisation en cours...
X opération(s) restante(s)
```
Indique que les données sont en cours de synchronisation avec le serveur.

#### Synchronisation Réussie (Vert)
```
Synchronisation réussie
Toutes les données sont à jour
```
Confirmation que toutes les données ont été synchronisées avec succès.

#### Erreur de Synchronisation (Rouge)
```
Erreur de synchronisation
[Message d'erreur]
[Bouton Réessayer]
```
Indique un problème lors de la synchronisation avec option de réessayer.

## Fonctionnement Technique

### Service de Stockage Local (`local-storage.service.ts`)
Gère le stockage IndexedDB avec les tables suivantes :
- `products` - Produits
- `clients` - Clients
- `sales` - Ventes
- `orders` - Commandes
- `categories` - Catégories
- `suppliers` - Fournisseurs
- `purchases` - Achats
- `pendingOperations` - Opérations en attente de synchronisation
- `lastSync` - Horodatage de la dernière synchronisation par table

### Service de Synchronisation (`sync.service.ts`)
- Gère la synchronisation bidirectionnelle des données
- Traite la file d'attente des opérations en attente
- Notifie les composants des changements d'état
- Système de retry automatique (jusqu'à 5 tentatives)

### Service Réseau (`network.service.ts`)
- Écoute les événements `online` et `offline` du navigateur
- Notifie les composants des changements d'état réseau
- Détecte le retour de connexion pour déclencher la synchronisation

### Service Worker (`sw.js`)
- Cache les ressources statiques (JS, CSS, HTML, images, fonts)
- Stratégie Cache-First pour les assets statiques
- Network-First avec fallback sur le cache pour l'API Supabase
- Gestion intelligente du cache avec versioning

## Utilisation dans le Code

### Wrapper Offline pour les Services

Le fichier `offline-wrapper.service.ts` fournit des fonctions utilitaires :

#### Requête avec Cache Offline
```typescript
import { offlineQuery } from './services/offline-wrapper.service';

const products = await offlineQuery<Product>(
  'products',
  () => supabase.from('products').select('*').eq('company_id', companyId),
  true // useOfflineCache
);
```

#### Création avec Queue
```typescript
import { offlineCreate } from './services/offline-wrapper.service';

const newProduct = await offlineCreate<Product>(
  'products',
  productData,
  () => supabase.from('products').insert([productData]).select().single()
);
```

#### Mise à Jour avec Queue
```typescript
import { offlineUpdate } from './services/offline-wrapper.service';

await offlineUpdate<Product>(
  'products',
  productId,
  { name: 'Nouveau nom' },
  () => supabase.from('products').update({ name: 'Nouveau nom' }).eq('id', productId)
);
```

#### Suppression avec Queue
```typescript
import { offlineDelete } from './services/offline-wrapper.service';

await offlineDelete(
  'products',
  productId,
  () => supabase.from('products').delete().eq('id', productId)
);
```

### Vérifier l'État de Connexion
```typescript
import { isOfflineMode } from './services/offline-wrapper.service';

if (isOfflineMode()) {
  console.log('Application en mode hors ligne');
}
```

### Écouter les Changements d'État
```typescript
import { networkService } from './services/network.service';
import { syncService } from './services/sync.service';

// État réseau
const unsubNetwork = networkService.onStatusChange((status) => {
  console.log('Online:', status.isOnline);
});

// État synchronisation
const unsubSync = syncService.onStatusChange((status) => {
  console.log('Syncing:', status.isSyncing);
  console.log('Pending:', status.pendingCount);
});

// N'oubliez pas de vous désabonner
onUnmounted(() => {
  unsubNetwork();
  unsubSync();
});
```

## Comportement par Table

### Données Critiques (Toujours en Cache)
- Produits
- Clients
- Catégories
- Fournisseurs

Ces données sont systématiquement mises en cache et accessibles hors ligne.

### Opérations Transactionnelles (Queue)
- Ventes
- Commandes
- Achats
- Paiements

Ces opérations sont ajoutées à la queue si créées hors ligne et synchronisées dès le retour de connexion.

## Limitations

1. **Images** : Les nouvelles images ne peuvent pas être uploadées en mode hors ligne
2. **Webhooks** : Les paiements par webhook nécessitent une connexion
3. **Rapports en temps réel** : Les statistiques ne sont pas mises à jour en temps réel en mode hors ligne
4. **Modifications concurrentes** : Pas de résolution automatique des conflits (last-write-wins)

## Recommandations

1. **Attendre la synchronisation** : Avant de fermer l'application, attendez que toutes les opérations soient synchronisées
2. **Vérifier l'indicateur** : Consultez régulièrement l'indicateur en haut à droite pour connaître l'état de synchronisation
3. **Connexion stable** : Pour les opérations critiques, assurez-vous d'avoir une connexion stable
4. **Données sensibles** : Les données en cache local sont stockées en clair dans IndexedDB

## Dépannage

### Les données ne se synchronisent pas
1. Vérifiez votre connexion Internet
2. Consultez la console du navigateur pour les erreurs
3. Cliquez sur "Réessayer" si un message d'erreur apparaît
4. Rafraîchissez la page si le problème persiste

### Opérations en attente bloquées
Les opérations sont automatiquement réessayées jusqu'à 5 fois. Si elles échouent après 5 tentatives, elles sont supprimées de la queue et loguées dans la console.

### Vider le cache
Pour vider complètement le cache local :
1. Ouvrez les outils de développement (F12)
2. Allez dans l'onglet "Application" (Chrome) ou "Stockage" (Firefox)
3. Sélectionnez "IndexedDB"
4. Supprimez la base de données `gestion_commerciale_db`
5. Rafraîchissez la page

## Support

Pour toute question ou problème, consultez les logs de la console du navigateur qui fournissent des informations détaillées sur l'état de synchronisation et les erreurs éventuelles.
