#!/bin/bash

clear

# Passage en mode debug :
if [ verbose = "1" ]; then 
  set -x
fi

# -----------------------------------------------------------------------------
# Nom du Script : dns_config.sh
# Version       : 1.0.0
# Auteur        : Landry Gonzalez
# Date          : 2024-06-20
# Description   : Ce script configure les DNS sur poste linux.
# Usage         : ./dns_config.sh
# Contacts      : landry.gonzalez@gmail.com
# -----------------------------------------------------------------------------
# Historique des Versions :
# 1.0.0  2024-06-20  Première version
# -----------------------------------------------------------------------------

# Déclaration des variables :
verbose="0"
fichier_conf="dns_config"

# Fonction pour afficher l'aide
function afficher_aide() {
    echo "Usage: $0 chemin_du_fichier"
    echo
    echo "chemin_du_fichier : Chemin vers le fichier à vérifier."
    exit 1
}

# Vérification des arguments
if [ $# -ne 1 ]; then
    afficher_aide
fi

chemin_du_fichier=$1

# Vérifier si le fichier existe
if [ ! -f "$chemin_du_fichier" ]; then
    echo "Le fichier '$chemin_du_fichier' n'existe pas."
    exit 1
fi

# Vérifier si le fichier est vide
if [ ! -s "$chemin_du_fichier" ]; then
    echo "Le fichier '$chemin_du_fichier' est vide."
    exit 0
fi

# Afficher le contenu du fichier
echo "Le fichier '$chemin_du_fichier' n'est pas vide. Son contenu est :"
cat "$chemin_du_fichier"
echo

# Demander à l'utilisateur s'il souhaite poursuivre ou arrêter
while true; do
    read -p "Souhaitez-vous poursuivre le script ? (o/n) : " choix
    case $choix in
        [oO]* ) 
            echo "Vous avez choisi de poursuivre le script."
            # Ajoutez ici la logique à exécuter si l'utilisateur choisit de poursuivre
            break
            ;;
        [nN]* )
            echo "Vous avez choisi d'arrêter le script."
            exit 0
            ;;
        * ) 
            echo "Veuillez répondre par o (oui) ou n (non)."
            ;;
    esac
done




# Vérification du lancement du terminal en tant qu'administrateur :
if [ "$(id -u)" != "0" ]; then
  printf "Ce script doit être exécuté en tant qu'administrateur (sudo).\nCette fenêtre se fermera automatiquement dans 5 secondes." 1>&2
  sleep 5s
  exit 1
fi

# Déclaration des variables :
# Les DNS ci-dessous sont ceux de Quad9 (https://quad9.net/fr/service/service-addresses-and-features).
dns_primaire='9.9.9.9'
dns_secondaire='149.112.112.112'
fichier_configuration_dns='/etc/systemd/resolved.conf'
# La variable ci-dessous compte le nombre de serveurs DNS déclarés en remontant les lignes avec la valeur "DNS=", mais sans "#".
dns_count=`cat $fichier_configuration_dns | grep -i 'DNS=' | grep -v '#' | wc -l`

#######################################
# Sauvegarde du fichier resolved.conf #
#######################################
date=`date +"%Y%m%d_%H%M%S"`
cp $fichier_configuration_dns /etc/systemd/resolved.conf_bak_$date
# Vérification du code de sortie :
exit_code=$?
if [ $exit_code -ne "0" ]; then
  printf "La sauvegarde du fichier de configuration DNS a échoué.\nCe script s'arrêtera donc dans 5 secondes.\n\n"
else
  printf "La sauvegarde du fichier de configuration DNS a réussi.\nCe script se poursuivra donc dans 5 secondes.\n\n"
fi
sleep 5s
printf "#####\n\n"

#######################################################################################
# Intéraction avec l'utilisateur pour lui proposer de poursuivre ou arrêter le script #
#######################################################################################
liste_dns=`cat $fichier_configuration_dns | grep -i 'DNS=' | grep -v '#'`
printf "Configuration DNS actuelle :\n"
if [ $dns_count = 0 ]; then # S'il n'y a aucune configuration DNS.
  printf "Aucune configuration.\n\n"
else
  printf "${liste_dns}\n\n"
fi
printf "Nouvelle configuration DNS à appliquer :\nDNS=$dns_primaire\nDNS=$dns_secondaire\n\n"

while :; do
  printf "Que voulez-vous faire ?\n"
  printf "1. Appliquer la nouvelle configuration.\n2. Garder l\'ancienne configuration.\n"
  read choix
  printf "\n"
  case $choix in
    1)
      break
      ;;
    2)
      exit 0
      ;;
    *)
      printf "Le choix $choix n'est pas valide. Attendez 5 secondes pour recommencer.\n\n"
      sleep 5s
      continue
      ;;
  esac
done
printf "#####\n\n"

###################################
# Modification du fichier des DNS #
###################################
if [ $dns_count = 0 ]; then # S'il n'y a aucun enregistrement DNS, alors on saisit les DNS.
  echo 'DNS=9.9.9.9' >> $fichier_configuration_dns
  echo 'DNS=149.112.112.112' >> $fichier_configuration_dns
  printf "Les nouveaux DNS ont été enregistrés.\n\n"
elif [ $dns_count > 0 ]; then # S'il y a au moins 1 enregistrement DNS, on supprime les enregistrements DNS, et on les redéclare.
  #sed -i '/^DNS=[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}/d' $fichier_configuration_dns
  sed -i '/^DNS=.*/d' $fichier_configuration_dns
  echo 'DNS=9.9.9.9' >> $fichier_configuration_dns
  echo 'DNS=149.112.112.112' >> $fichier_configuration_dns
  printf "Les anciens DNS ont été supprimés et les nouveaux DNS ont été enregistrés.\n\n"
else
  printf "La valeur de '$dns_count' est $dns_count, mais elle n'est pas celle attendue.\nContactez l'administrateur du script.\n\nCe script se fermera dans 10 secondes.\n\n"
  sleep 10s
  exit 1
fi
printf "#####\n\n"

# Tests effectués et validés jusqu'ici.

##################################
# Relance du service DNS systemd #
##################################
systemctl stop systemd-resolved.service
systemctl start systemd-resolved.service

##################################################
# Affichage de la configuration actuelle des DNS #
##################################################
liste_dns=`cat $fichier_configuration_dns | grep -i 'DNS=' | grep -v '#'`
printf "Configuration actuelle des DNS :\n${liste_dns}\nCe script se fermera dans 10 secondes."
sleep 10s

#################
# Fin du script #
#################
exit 0
