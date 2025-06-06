#!/bin/bash

###############################################################
#
# PARAMETRE :
#   - 1 : source (KbPlus, CUFTS, AbesBacon, ...
#   - 2 : lors d'une coupure exceptionnelle, le nombre de jour d'arrêt doit être passé en second paramètre au script
#
# sous programme du programme MajEditeurs.sh
#
# Script de génération du fichier d'entrée pour la source AbesBacon
# Génère un fichier comprenant tous les fichiers de la source AbesBacon
# en indiquant quels fichiers doivent être traités (donc modifiés depuis le dernier passage du script)
# le fichier généré est "~/Entree/EntreeAbesBacon.url"
#

# Serveur : Begonia (production), Bordeauxdev (test)
#
# Auteur : SRY
# Date de création : mai 2016
#
# Mises à jour :
#   * 2016-05-20 : SRY : version en production
#   * 2024-05-30 : AHE : nouvelle version
#
###############################################################

# crontab -l
#35 21  * * 0-4  /home/devel/MajEditeurs_ahe/bin/Traite_OwnCloud_ahe.sh "AbesBacon" "1" 2>>/home/devel/MajEditeurs_ahe/rundir/Traite_OwnCloud_ahe/stderr.log
# puis :
#45 21  * * 0-4  /home/devel/MajEditeurs_ahe/bin/CheckMajEditeurs_ahe.sh "AbesBacon" 2>/home/devel/MajEditeurs_ahe/rundir/CheckMajEditeurs_ahe/AbesBacon/stderr.log

##############################################################
#
# Debut des fonctions
#
##############################################################
function fUsage
{
	echo
	echo "  #"
	echo "  #  ATTENTION : appel de $0 incorrect, nombre d'arguments $1 non valable."
	echo "  #"
	echo
	echo "  #"
	echo "  # Appel correct : $0 <Éditeur> <nb de jours depuis le dernier traitement>"
	echo "  #"
	echo
	echo "  #"
	echo '  # Exemple : '$0' "AbesBacon" 1'
	echo "  #"
}

function fVariables
{
	# pour les variables chaîne de caractères
	line=$( sed -e "/^[[:space:]]*${1}[[:space:]]*=[[:space:]]*/!d" $BASH_SOURCE )
	# pour les variables nombre
	[[ -z $line ]] && line=$( grep "^let $1" $BASH_SOURCE )
	if [[ -z $line ]]
	 then
	  comment="VARIABLE INCONNUE"
	  contenu="INCONNU"
	 else
	  comment=$( echo $line | cut -d"#" -f2 );comment=${comment##[[:space:]]}
	  contenu="${!1}"
    [[ "${1}" != "RepInit" ]] && contenu=${contenu/$BASERUNDIR}
	fi

	printf "%-40.40s : %-45.45s : %s\n" "$1" "$contenu" "$comment"
}

function fAfficheVariables
{
	echo
	echo "--AFFICHAGE DES VARIABLES de $BASH_SOURCE ---------"
	echo
	fVariables "RepOwnCloud"
	echo
	echo "Racine des fichiers       : $BASERUNDIR"
	echo "Racine des Archives       : $BASEARCHIVE"
  echo "Racine des configurations : $BASECONF ( fichiers de configuration nécessaires à l'exécution des programmes )"
  fVariables "V00_EditeursATraiter_DefinisParABES"

  fVariables "V02_FichiersNonConformes_EditeursSelectionnesParABES"
}

##############################################################
#
# Fin des fonctions
#
##############################################################

EDITEUR="AbesBacon"
RACINE=/home/devel/MajEditeurs_ahe

SCRIPT=$( basename $BASH_SOURCE );SCRIPT=${SCRIPT%.sh}

. $RACINE/bin/Definition_Env.sh

#echo $SCRIPT
#[devel@begonia ~]$ df -h
#Sys. de fichiers                                 Taille Utilisé Dispo Uti% Monté sur
#erebus.v102.abes.fr:/mnt/EREBUS/zpool_data/bacon   9,0T    7,8T  1,3T  86% /home/devel/bacon

RepOwnCloud="/home/devel/bacon" #
# Fichier commun à tous les traitements AbesBacon : contient la liste des éditeurs à traiter
V00_EditeursATraiter_DefinisParABES="$BASECONF_SCRIPT_EDITEUR/00_EditeursATraiter_DefinisParABES.txt"

V02_FichiersNonConformes_EditeursSelectionnesParABES="$RUNDIR/02_FichiersNonConformes_EditeursSelectionnesParABES" #
V02_FichiersNonConformes_EditeursSelectionnesParABES_Details="$RUNDIR/02_FichiersNonConformes_EditeursSelectionnesParABES_Details" #
###############################################################
# Chargement du paramétrage et initialisation des variables
###############################################################


echo
fAfficheVariables
echo
echo "## ls -al $RepOwnCloud"
#ls -al $RepOwnCloud
echo

###############################################################
#
# gestion de la coupure de lancement du programme les week end ou les éventuelles coupures plus longues
#
###############################################################


fEcho
fEchof "Établit la liste des noms de fichiers non conformes sous les répertoires des Éditeurs sélectionnés par l'ABES $RepOwnCloud"
fEchof

mapfile -t aEditeursATraiter < $V00_EditeursATraiter_DefinisParABES
cEditeursATraiter=${#aEditeursATraiter[*]}
fEcho "$cEditeursATraiter lignes dans le fichier $V00_EditeursATraiter_DefinisParABES"

# La liste des fichiers non conformes sera transmise par mail par CheckMajEditeurs.sh
> $V02_FichiersNonConformes_EditeursSelectionnesParABES
for (( cl=0;cl<$cEditeursATraiter;cl++ ))
 do
  EditeurATraiter="${aEditeursATraiter[$cl]}"
  find ${RepOwnCloud}/${EditeurATraiter} -maxdepth 1 -type f \
  | sed -e "s:${RepOwnCloud}/::" \
  | sed -n "/_20[[:digit:]]\{2\}-\(0[1-9]\|1[0-2]\)-\(0[1-9]\|[1-2][[:digit:]]\|3[0-1]\)/!p" \
  | sort \
  >> $V02_FichiersNonConformes_EditeursSelectionnesParABES
 done

mapfile -t aNonConformes < $V02_FichiersNonConformes_EditeursSelectionnesParABES
cNonConformes=${#aNonConformes[*]}
fEcho "$cNonConformes lignes dans le fichier $V02_FichiersNonConformes_EditeursSelectionnesParABES"
> $V02_FichiersNonConformes_EditeursSelectionnesParABES_Details
for (( cl=0;cl<$cNonConformes;cl++ ))
 do
  #NonConformes="${aNonConformes[$cl]}"
  ls -al --time-style="+%F" "${RepOwnCloud}/${aNonConformes[$cl]}" | awk '{ print $6" "$7" "$5}' >> $V02_FichiersNonConformes_EditeursSelectionnesParABES_Details
 done

cat $V02_FichiersNonConformes_EditeursSelectionnesParABES_Details | sort
