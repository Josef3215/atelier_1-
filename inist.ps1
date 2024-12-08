#!/bin/bash

# Fonction pour vérifier si mongos est prêt

function Wait-ForMongos {
  # Forcer l'encodage en UTF-8
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

  Write-Host "Attente de la disponibilité de mongos..."

  while ($true) {
      $result = docker exec mongos mongo --quiet --eval "db.runCommand({ ping: 1 })" 2>&1
      Write-Host "Résultat de la commande : $result"

      if ($LASTEXITCODE -eq 0 -and $result -match '"ok"\s*:\s*1') {
          Write-Host "mongos est prêt à répondre aux requêtes."
          break
      } else {
          Write-Host "mongos n'est pas encore prêt. Nouvelle tentative dans 5 secondes..."
          Start-Sleep -Seconds 5
      }
  }
}



# Lancer les conteneurs Docker en arrière-plan
docker-compose up -d

# Attendre quelques secondes pour s'assurer que les conteneurs sont en cours de démarrage
Start-Sleep -Seconds 20

# Configurer le premier config server
docker exec -it config-server-mongo-1 mongo --eval "
rs.initiate({
  _id: 'config-server-mongo',
  configsvr: true,
  members: [
    { _id: 0, host: 'config-server-mongo-1:27017' },
    { _id: 1, host: 'config-server-mongo-2:27017' },
    { _id: 2, host: 'config-server-mongo-3:27017' }
  ]
});
rs.status();
"

# Configurer le premier shard server
docker exec -it shard-server-mongo-1 mongo --eval "
rs.initiate({
  _id: 'shard-server-mongo',
  members: [
    { _id: 0, host: 'shard-server-mongo-1:27017' },
    { _id: 1, host: 'shard-server-mongo-2:27017' },
    { _id: 2, host: 'shard-server-mongo-3:27017' }
  ]
});
rs.status();
"

# Attendre que mongos soit prêt après la configuration du premier shard
Wait-ForMongos
# Ajouter le premier shard au cluster
docker exec -it mongos mongo --eval "
sh.addShard('shard-server-mongo/shard-server-mongo-1:27017,shard-server-mongo-2:27017,shard-server-mongo-3:27017');
sh.status();
"


# Configurer le deuxième shard server
docker exec -it shard2-server-mongo-1 mongo --eval "
rs.initiate({
  _id: 'shard2-server-mongo',
  members: [
    { _id: 0, host: 'shard2-server-mongo-1:27017' },
    { _id: 1, host: 'shard2-server-mongo-2:27017' },
    { _id: 2, host: 'shard2-server-mongo-3:27017' }
  ]
});
rs.status();
"


docker exec -it mongos mongo --eval "
sh.addShard('shard2-server-mongo/shard2-server-mongo-1:27017,shard2-server-mongo-2:27017,shard2-server-mongo-3:27017');
sh.status();
"

# Configurer le troisième shard server
docker exec -it shard3-server-mongo-1 mongo --eval "
rs.initiate({
  _id: 'shard3-server-mongo',
  members: [
    { _id: 0, host: 'shard3-server-mongo-1:27017' },
    { _id: 1, host: 'shard3-server-mongo-2:27017' },
    { _id: 2, host: 'shard3-server-mongo-3:27017' }
  ]
});
rs.status();
"

docker exec -it mongos mongo --eval "
sh.addShard('shard3-server-mongo/shard3-server-mongo-1:27017,shard3-server-mongo-2:27017,shard3-server-mongo-3:27017');
sh.status();
"

# Activer le sharding pour la base de données atelier1
Write-Output "Activation du sharding pour la base de données atelier1..."
docker exec -it mongos mongo --eval "sh.enableSharding('atelier1')"
docker exec -it mongos mongo --eval "sh.shardCollection('atelier1.table_entropot', { 'customer.mktsegment': 'hashed' })"

# Copier le fichier JSON dans le conteneur mongos
Write-Output "Copie du fichier JSON dans le conteneur mongos..."
docker cp "table_entropot.json" mongos:/table_entropot.json

# Importer le fichier JSON dans la collection
Write-Output "Importation du fichier JSON dans la collection table_entropot..."
docker exec -it mongos bash -c "time mongoimport --db atelier1 --collection table_entropot --file /table_entropot.json --jsonArray"

# Vérification de la distribution des shards
Write-Output "Vérification de la distribution des shards..."
docker exec -it mongos mongo --eval "
use atelier1;
db.table_entropot.getShardDistribution();
"

Write-Output "Importation et sharding réussis pour la collection 'table_entropot' !"
