#!/bin/bash
###############################################################
#
# Chargement du fichier de paramétrage
# Initialisation des variables et des fichiers
#
###############################################################
#[[ $# -ne 1 ]] && { CMajE_Usage "$#"; exit 1;}
EDITEUR="Autre"
RACINE=/home/devel/MajEditeurs_ahe

SCRIPT=$( basename $BASH_SOURCE );SCRIPT=${SCRIPT%.sh}
###############################################################
# Chargement du fichier de paramétrage
#
. $RACINE/bin/Definition_Env.sh

# Inclusion des fonctions de traitements communes ( à placer après l'appel de Definition_Env.sh )
. $RACINE/bin/Traitement_Commun.sh


V00_KBART_Global_Template=${BASECONF}/KBART_Global_Template_2016-04-26.tsv

[[ -z $V03_FichierKBART  ]] && { echo "Variable V03_FichierKBART  non assignée => sortie du script."; echo "Faites export V03_FichierKBART=\"...\"";exit 1; }



#hexdump -C $V00_KBART_Global_Template
#echo "FicMail=$FicMail"
TC_03_Conformite_KBART "zz"
