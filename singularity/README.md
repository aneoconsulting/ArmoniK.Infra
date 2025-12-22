# Notes sur Jean Zay

## Copie d'une image

Il faut construire l'image locallement sous la forme d'un .sif puis l'ajouter dans le gestionnaire de conteneurs.

```bash
singularity build armonik_pollingagent_0.35.0.sif docker://dockerhubaneo/armonik_pollingagent:0.35.0
idrcontmgr cp armonik_pollingagent_0.35.0.sif
```


## Install de MongoDB

Copie des binaires => choix des binaires RedHat Centos 9.
Idem pour `mongosh` (MongoDB Shell).


## Install d'ActiveMQ

(Page de download des binaires)[https://activemq.apache.org/components/classic/download/] (les liens sont morts).
Utilisation des binaires Unix.