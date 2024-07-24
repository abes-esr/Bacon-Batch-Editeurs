###############################################################
#
# PARAMETRE :
#   - 1 : source (KbPlus, CUFTS, AbesBacon, ...
#
# sous programme du programme MajEditeurs.sh
#
# Fichier de paramétrage pour le script shell CheckKbPlus.sh
# Détection des mises à jour des fichiers KBART.
#
# Serveur : Begonia (production), Bordeauxdev (test)
#
# Auteur : SRY
# Date de création : décembre 2015
#
# Mises à jour :
#   * 2016-01-05 : SRY : version initiale pour KbPlus
#   * 2016-05-20 : SRY : version intégrant le traitement AbesBacon
#   * 2016-07-26 : SRY : version intégrant le traitement CUFTS
#   * 2017-01-16 : SRY : version entégrant un traitement pour des fichiers "Autre" (proche de KbPlus,
#                        mais fichiers issus du site de l'éditeur)
#   * 2019-02-20 : SRY : ajout du suffixe "$EDITEUR" aux noms des fichiers temporaires
#   * 2024-05-31 : AHE : dépoussiérage , mise en fonction, ...
#
###############################################################
[[ -z $RACINE  ]] && { echo "Variable RACINE  non assignée => sortie du script.";exit 1; }
[[ -z $SCRIPT  ]] && { echo "Variable SCRIPT  non assignée => sortie du script.";exit 1; }
[[ -z $EDITEUR ]] && { echo "Variable EDITEUR non assignée => sortie du script.";exit 1; }


function ENV_EchoVarWithComments
{
	#echo "${FUNCNAME[0]} : level ${#FUNCNAME[*]}";echo "${FUNCNAME[*]}"
	fEchoVarWithCommentsFromScript "$BASH_SOURCE" "$1" "$2"
}

function ENV_AfficheVariables
{
	#echo "${FUNCNAME[0]} : level ${#FUNCNAME[*]}";echo "${FUNCNAME[*]}"
	fEcho
	fEcho "-- AFFICHAGE DES VARIABLES SERVEUR ---------"
	fEcho
  ENV_EchoVarWithComments "Serveur"
  ENV_EchoVarWithComments "URLhttps"
	fEcho
	fEcho "-- AFFICHAGE DES RÉPERTOIRES sous RACINE=$RACINE --"
	fEcho
	ENV_EchoVarWithComments "BASEARCHIVE"
	ENV_EchoVarWithComments "BASECONF"
	ENV_EchoVarWithComments "BASERUNDIR"
	fEcho
	ENV_EchoVarWithComments "BASECONF_SCRIPT"
	ENV_EchoVarWithComments "BASECONF_SCRIPT_EDITEUR"
	ENV_EchoVarWithComments "BASERUNDIR_SCRIPT_EDITEUR"

	ENV_EchoVarWithComments "YYYYmmdd"
	ENV_EchoVarWithComments "YYYYmmdd_HHMMSS"
	ENV_EchoVarWithComments "RUNDIR"
	fEcho
  ENV_EchoVarWithComments "RepDerniereVersion"
  ENV_EchoVarWithComments "RepArchive"
  fEcho
	fEcho "-- AFFICHAGE DES FICHIERS sous $RUNDIR ---------"
	fEcho
  ENV_EchoVarWithComments "LogFile" "$RUNDIR"
  ENV_EchoVarWithComments "FicMail" "$RUNDIR"
  ENV_EchoVarWithComments "FicMailWarning" "$RUNDIR"

  fEcho
  ENV_EchoVarWithComments "FichierHtml_Editeur_Recapitulatif_desMAJ"
  ENV_EchoVarWithComments "TempsVisu1"
  ENV_EchoVarWithComments "TempsVisu2"
  fEcho
}


#
# 6.5. File Name
# File naming convention: [ProviderName]_[Region/Consortium]_[PackageName]_[YYYY-MM-DD].txt
#  Provider Name is the name of the platform where data is hosted (without punctuation).
#  Region/Consortium is where the package is sold or to what consortium it is available. If the file is for a universal list, the term “Global” should be used.
#  Package Name is the name of the collection as customers would expect to see it labeled within the knowledgebase (again without punctuation).
#  Date is the file creation date using the ISO 8601 date format
# File  name examples:
# TaylorandFrancis_Global_AllTitles_2014-03-08.txt
# IOP_CRKN_ElectronicJournals_2015-01-01.txt
# Springer_Asia-Pacific_Medicine_2015-01-28.txt
#

###############################################################
#
# Variables générales liées au serveur (PROD / TEST)
# $EDITEUR correspond à la source (AbesBacon,CUFTS,KbPlus)
#
###############################################################

Serveur="begonia.abes.fr"                          # Serveur hébergeant le programme

URLhttps="https://beg.abes.fr/MajEditeurs_ahe/"$EDITEUR # Entête de l'URL pour visualiser les fichiers HTML résultat du DAFF

###############################################################
#
# Variables générales du programme : ahe
#
###############################################################
BASEARCHIVE=$RACINE/Archive # Racine du dossier des fichiers archivés
[[ ! -d $BASEARCHIVE ]] && { echo "Dossier $BASEARCHIVE manquant => sortie du script.";exit 1; }

BASECONF=$RACINE/conf     # Racine du dossier des configurations
BASERUNDIR=$RACINE/rundir # Racine du dossier des traces de l'exécution du script

BASECONF_SCRIPT=$BASECONF/$SCRIPT                      # Dossier de configuration du script pour tous les éditeurs
BASECONF_SCRIPT_EDITEUR=$BASECONF/$SCRIPT/$EDITEUR     # Dossier de configuration du script pour cet éditeur
BASERUNDIR_SCRIPT_EDITEUR=$BASERUNDIR/$SCRIPT/$EDITEUR # Dossier des traces des exécutions du script pour cet éditeur

YYYYmmdd=$(date "+%Y-%m-%d" ) # Date de l'exécution du script
YYYYmmdd_HHMMSS=$(date +'%Y-%m-%d_%H:%M:%S') # Date et heure de l'exécution du script
RUNDIR=$BASERUNDIR_SCRIPT_EDITEUR/$YYYYmmdd_HHMMSS # Dossier des traces de l'exécution actuelle du script

mkdir -p $BASECONF_SCRIPT_EDITEUR
mkdir -p $RUNDIR

StdErrFile=$BASERUNDIR_SCRIPT_EDITEUR"/stderr.log" # fichier stderr créé par cron, ce fichier sera envoyé dans le mail final

LogFile=$RUNDIR"/99_log"                # Nom du fichier de Log
> $LogFile
FicMail=$RUNDIR"/99_Mail"                # Nom du fichier pour l'envoi du mail de rapport
> $FicMail
FicMailWarning=$RUNDIR"/99_Mail_Warning" # Nom du fichier des warning pour l'envoi du mail de rapport
> $FicMailWarning
# l'include de echos.sh est fait ici car ses fonctions ont besoin de $LogFile, $FicMail et $FicMailWarning
. $RACINE/bin/echos.sh

fMailWarning "----------------------------------"
fMailWarning "-      A T T E N T I O N         -"
fMailWarning "----------------------------------"
fMailWarning "📜 Les compléments d'information se trouvent dans le fichier de log : "
fMailWarning "$LogFile"
fMailWarning
###############################################################
#
# Variables générales du programme
#
###############################################################

# Variable Tiret : utilisée dans l'initialisation du fichier historique des chargements Date.txt
#
Tiret="-"

# Extension des fichiers résultat = tsv


###############################################################
#
# Nom des répertoires (travail et résultat)
# $EDITEUR correspond à la source (AbesBacon,CUFTS,KbPlus)
#
###############################################################

RepDerniereVersion=$RACINE"/DerniereVersion/"$EDITEUR   # Répertoire contenant la  dernière version des fichiers KBART
RepArchive=$BASEARCHIVE"/"$EDITEUR   # Répertoire contenant les fichiers Archive des KBART

mkdir -p $RepDerniereVersion $RepArchive

###############################################################
#
# Gestion du ficher récapitulatif des mises à jour
#
###############################################################


FichierHtml_Editeur_Recapitulatif_desMAJ=$EDITEUR".html"      # Nom du fichier récapitulatif des mises à jour

declare -a Colors=( "01B001" "01B0F0" "96CA2D" "c1ffc1" "ccffcc" "ff0000" )
#
# Mise à jour en cours                                              : Position 0 : Colors[0]=01B001
# Mise à jour en cours et nouveau corpus                            : Position 1 : Colors[1]=01B0F0
# Pas de mise à jour et dernière maj <=  9 jours =  777600 secondes : Position 2 : Colors[2]=96CA2D
# Pas de mise à jour et dernière maj <= 30 jours = 2592000 secondes : Position 3 : Colors[3]=c1ffc1
# Pas de mise à jour et dernière maj >  30 jours = 2592000 secondes : Position 4 : Colors[4]=ccffcc
# Si fichier en erreur, mise en avant en rouge                      : Position 5 : Colors[5]=ff0000
let TempsVisu1=777600  # Détermine la couleur utilisée dans le fichier html avant et après Tempvisu1
let TempsVisu2=2592000 # Détermine la couleur utilisée dans le fichier html après Tempvisu2
