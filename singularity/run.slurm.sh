#!/bin/bash

#SBATCH --job-name=ArmoniK              # nom du job
#SBATCH --nodes=2                       # Nombre total de noeuds
#SBATCH --ntasks-per-node=40            # Nombre de processus MPI par noeud
# /!\ Attention, la ligne suivante est trompeuse mais dans le vocabulaire
# de Slurm "multithread" fait bien référence à l'hyperthreading.
#SBATCH --hint=nomultithread            # 1 processus MPI par coeur physique (pas d'hyperthreading)
#SBATCH --time=00:10:00                 # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH --output=logs/ArmoniK%j.out          # Nom du fichier de sortie
#SBATCH --error=logs/ArmoniK%j.out           # Nom du fichier d'erreur (ici commun avec la sortie)

source singularity/deploy.slurm.sh

singularity/client-htcmock.sh \
    -i $SINGULARITY_ALLOWED_DIR/armonik_core_htcmock_test_client_${ARMONIK_VERSION}.sif \
    -l $LOGS_DIR
