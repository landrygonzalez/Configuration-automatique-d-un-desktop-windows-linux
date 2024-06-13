#!/bin/bash

clear
#set -x

###################################################################
# Vérification du lancement du terminal en tant qu'administrateur #
###################################################################
#printf "Etape 1/4..."
if [ "$(id -u)" != "0" ]; then
  printf "Ce script doit être exécuté en tant qu'administrateur (sudo).\nCette fenêtre se fermera automatiquement dans 5 secondes." 1>&2
  sleep 5s
  exit 1
fi

#############################
# Déclaration des variables #
#############################
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
