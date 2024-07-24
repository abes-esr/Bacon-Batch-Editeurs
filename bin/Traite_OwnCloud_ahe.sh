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
#   * 2024-05-30 : AHE :
#
###############################################################

# crontab -l
#30 21  * * 0-4  /home/devel/MajEditeurs/Traite_OwnCloud.sh AbesBacon 1 > /home/devel/MajEditeurs/Erreur/errOwnCloud.txt 2> /home/devel/MajEditeurs/Erreur/errOwnCloud2.txt

#40 21  * * 0-4  /home/devel/MajEditeurs/CheckMajEditeurs.sh AbesBacon > /home/devel/MajEditeurs/Erreur/errAbesBacon.txt 2> /home/devel/MajEditeurs/Erreur/errAbesBacon2.txt

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
  fVariables "V01_FichiersATraiter_TousEditeurs"

  fVariables "V02_FichiersATraiter_EditeursSelectionnesParABES"
  fVariables "V02_DossiersATraiter_EditeursSelectionnesParABES"

  fVariables "V03_FichiersATraiter_Bouquet_TouteslesDates"

  fVariables "V04_FichiersATraiter_Bouquet_DerniereDate"

  fVariables "V05_Fichier_Entree_pourMajEditeur"

  fVariables "V06_Dossiers_Archive"
}

if [[ $# -ne 2 ]]
 then
  fUsage "$#"
  exit 1
fi

EDITEUR=$1
RACINE=/home/devel/MajEditeurs_ahe

SCRIPT=$( basename $BASH_SOURCE );SCRIPT=${SCRIPT%.sh}

. $RACINE/bin/Definition_Env.sh

#echo $SCRIPT

RepOwnCloud="/home/devel/bacon" #
V00_EditeursATraiter_DefinisParABES="$BASECONF_SCRIPT_EDITEUR/00_EditeursATraiter_DefinisParABES.txt" # Fichier commun à tous les traitements AbesBacon : contient la liste des éditeurs à traiter
V01_FichiersATraiter_TousEditeurs="$RUNDIR/01_FichiersATraiter_TousEditeurs" # contient la liste des fichiers à traiter

V02_FichiersATraiter_EditeursSelectionnesParABES="$RUNDIR/02_FichiersATraiter_EditeursSelectionnesParABES" #
V02_DossiersATraiter_EditeursSelectionnesParABES="$RUNDIR/02_DossiersATraiter_EditeursSelectionnesParABES" #
V02_FichiersATraiter_EditeursNONSelectionnesParABES="$RUNDIR/02_FichiersATraiter_EditeursNONSelectionnesParABES" #

V03_FichiersATraiter_Bouquet_TouteslesDates="$RUNDIR/03_FichiersATraiter_Bouquet_TouteslesDates" #

V04_FichiersATraiter_Bouquet_DerniereDate="$RUNDIR/04_FichiersATraiter_Bouquet_DerniereDate" #

V05_Fichier_Entree_pourMajEditeur="$RUNDIR/05_Fichier_Entree_pourMajEditeur" #

V06_Dossiers_Archive="$RUNDIR/06_Dossiers_Archive" #

###############################################################
# Chargement du paramétrage et initialisation des variables
###############################################################


echo
fAfficheVariables
echo
echo "## ls -al $RepOwnCloud"
ls -al $RepOwnCloud
echo

let i=0
let j=0
let nbjour=0
let jourdate=0

###############################################################
#
# gestion de la coupure de lancement du programme les week end ou les éventuelles coupures plus longues
#
###############################################################

if [[ $2 -eq 1 ]]
 then
  # mode normal avec arrêt le vendredi et samedi
	let jourdate=$(date +'%u')
	let nbjour=jourdate==7?3:1
 else
  # coupure exceptionnelle. Le nombre de jour d'arrêt doit être passé en paramètre
	let nbjour=$2
fi
fEchof
fEchoVar "jourdate"
fEchoVar "nbjour"
fEcho
fEchof "PHASE 1 : Établit la liste des fichiers, sous le répertoire $RepOwnCloud, mis à jour depuis le dernier traitement"
fEchof "        ; prend en compte les coupures du week end ou les coupures exceptionnelles."
fEchof
fEchof "find $RepOwnCloud -type f -mtime -$nbjour \ "
fEchof "  | cut -d/ -f5,6 \ "
fEchof "  | sed -n \"/_20[[:digit:]]\{2\}-\(0[1-9]\|1[0-2]\)-\(0[1-9]\|[1-2][[:digit:]]\|3[0-1]\)/p\" \ "
fEchof "  | sort -r \ "
fEchof "  > $V01_FichiersATraiter_TousEditeurs"
find $RepOwnCloud -type f -mtime -$nbjour \
  | cut -d/ -f5,6 \
  | sed -n "/_20[[:digit:]]\{2\}-\(0[1-9]\|1[0-2]\)-\(0[1-9]\|[1-2][[:digit:]]\|3[0-1]\)/p" \
  | sort -r \
  > $V01_FichiersATraiter_TousEditeurs
# find          => /home/devel/bacon/openedition/OpenEdition_Global_Ebooks-OpenAccess_2024-05-24.txt
# cut -d/ -f5,6 => openedition/OpenEdition_Global_Ebooks-OpenAccess_2024-05-24.txt

if [[ ! -s $V01_FichiersATraiter_TousEditeurs ]]
 then
  fEchof "Fichier $V01_FichiersATraiter_TousEditeurs inexistant ou vide => arrêt du script"
  fEchof
  exit 1
fi
#cat $V01_FichiersATraiter_TousEditeurs
fEchof
fEchof "PHASE 2 : Suppression des éditeurs qui n'appartiennent pas à la liste des éditeurs à traiter contenus dans le fichier :"
fEchof
fEchoVarf "V00_EditeursATraiter_DefinisParABES"
fEchof
# J'ajoute dans la sedline les éditeurs autorisés par l'ABES
SEDLINE=""
while read line
 do
	SEDLINE=$SEDLINE"\|"$line
 done < $V00_EditeursATraiter_DefinisParABES
# élimination des 2 premiers caractères \|
SEDLINE=${SEDLINE:2}
SEDLINE="^\(${SEDLINE}\)\/"
#fEchoVar "SEDLINE"
#echo "sed -e \"$SEDLINE\" $V01_FichiersATraiter_TousEditeurs > $V02_FichiersATraiter_EditeursSelectionnesParABES"
sed -e "/${SEDLINE}/!d" $V01_FichiersATraiter_TousEditeurs | sort > $V02_FichiersATraiter_EditeursSelectionnesParABES

# La liste des fichiers à traiter non sélectionnés sera transmise par mail par CheckMajEditeurs.sh
sed -e "/${SEDLINE}/d" $V01_FichiersATraiter_TousEditeurs | sort | uniq > $V02_FichiersATraiter_EditeursNONSelectionnesParABES

# on ne garde que les répertoires pas les fichiers
cut -d"/" -f1 $V02_FichiersATraiter_EditeursSelectionnesParABES | uniq > $V02_DossiersATraiter_EditeursSelectionnesParABES

fEchof
fEchof "PHASE 3 : Traitement des coupures"
fEchof "        ; prend en compte toutes les versions des fichiers"
fEchof

fEchoVarf "V03_FichiersATraiter_Bouquet_TouteslesDates"
cat /dev/null >  $V03_FichiersATraiter_Bouquet_TouteslesDates

sed -e "1,$ s/\(.*\)_\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\).*/\0\t\1\t\2/" $V02_FichiersATraiter_EditeursSelectionnesParABES \
  >> $V03_FichiersATraiter_Bouquet_TouteslesDates

fEchof
fEchof "PHASE 4 : Traitement des coupures ( suite )"
fEchof "        ; ne prend en compte que la dernière version de chacun des fichiers"
fEchof
if [[ $nbjour -ne 1 ]] # nbjour est différent de 1 => il y a potentiellement plusieurs maj
 then
	# on ne garde que la date la plus récente de chaque bouquet
	cat /dev/null >  $V04_FichiersATraiter_Bouquet_DerniereDate
	FicOld="";LineOld=""
	i=0
	while read line
	do
		Temp=$( cut -f2 <<< "$line" )
		[[ $i -eq 0 ]] && FicOld=$Temp
		[[ "$Temp" != "$FicOld" ]] && { echo "$LineOld" >> $V04_FichiersATraiter_Bouquet_DerniereDate ; }
		FicOld=$Temp
		LineOld="$line"
		let i++
	done < $V03_FichiersATraiter_Bouquet_TouteslesDates
	[[ -n $LineOld ]] && { echo "$LineOld" >> $V04_FichiersATraiter_Bouquet_DerniereDate ; }
 else # nbjour -eq 1
  cp $V03_FichiersATraiter_Bouquet_TouteslesDates $V04_FichiersATraiter_Bouquet_DerniereDate
fi

#
fEchof
fEchof "À ce niveau le fichier V04_FichiersATraiter_Bouquet_DerniereDate ne contient que les dernières versions de chacun des fichiers de la source."
fEchoVarf "V04_FichiersATraiter_Bouquet_DerniereDate"
fEchof
#

fEchof
fEchof "PHASE 5 : Construction du fichier d'entrée du programme principal MajEditeurs.sh"
fEchoVarf "V05_Fichier_Entree_pourMajEditeur"
fEchof "        ; ne prend en compte que la dernière version de chacun des fichiers"
fEchof "        ; ils seront marqués O."
fEchof

cat /dev/null >  $V05_Fichier_Entree_pourMajEditeur

while read Editeur_Fichier Editeur_Bouquet DateCourte
do
  fEchof
  #fEchoVarf "Editeur_Fichier"
  #fEchoVarf "Editeur_Bouquet"
  #fEchoVarf "DateCourte"

  Editeur=${Editeur_Fichier%%/*}
	fEchoVarf "Editeur"

  Bouquet=${Editeur_Bouquet##$Editeur/}
  fEchoVarf "Bouquet"

	Fichier=${Editeur_Fichier##*/}
	fEchoVarf "Fichier"

	Extension="."${Fichier##*.}
	fEchoVarf "Extension"

	NomFic2="" # ????

	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$Editeur" "$Bouquet" "$Editeur_Fichier" "$Extension" "$DateCourte" "$NomFic2" "O" >> $V05_Fichier_Entree_pourMajEditeur

done < $V04_FichiersATraiter_Bouquet_DerniereDate # CIEPS/CIEPS_GLOBAL_ROAD_2024-05-20.txt CIEPS/CIEPS_GLOBAL_ROAD 2024-05-20

#
# Format de sortie attendu dans $V05_Fichier_Entree_pourMajEditeur
#
# CIEPS	CIEPS_GLOBAL_ROAD	CIEPS/CIEPS_GLOBAL_ROAD_2024-05-28.txt	.txt	2024-05-28		O
# dalloz	Dalloz_Global_Dalloz-fr	dalloz/Dalloz_Global_Dalloz-fr_2024-05-29.txt	.txt	2024-05-29		O
#


fEchof
fEchof "PHASE 6 : Construction du fichier d'entrée du programme principal MajEditeurs.sh (suite Phase 5 )"
fEchoVarf "V05_Fichier_Entree_pourMajEditeur"
fEchof "        ; prend aussi en compte les dernières versions des fichiers déjà traités."
fEchof "        ; ils seront marqués N."
fEchof
#
# On liste dans V06_Dossiers_Archive tous les dossiers existant dans l'archive Abes pour AbesBacon.
#
fEchof "find $RepArchive -type d -print | cut -d/ -f7 | sort"
fEchof "  > $V06_Dossiers_Archive"
find $RepArchive -type d -print | cut -d/ -f7 | sort | sed -e '/^$/d'  > $V06_Dossiers_Archive

# ahe : reconstitution de tout l'historique des dépots
###############################################################
#
# À la fin de la boucle, le fichier d'entrée V05_Fichier_Entree_pourMajEditeur est construit
# les fichiers ajoutés à V05_Fichier_Entree_pourMajEditeur par cette boucle ne seront pas traités par CheckMajEditeurs.sh
# le nom des fichier est mis à la norme Bacon
#
while read linefind
do
	Editeur="EDITEUR"
	#fEchoVarf "linefind"
	#fEchof "grep -c $linefind $V05_Fichier_Entree_pourMajEditeur"
	i=$( grep -c $linefind $V05_Fichier_Entree_pourMajEditeur )
	#fEchoVarf "RepArchive"
	#fEchof "$RepArchive"/"$linefind"
	if [[ $i -eq 0 ]]
	 then
	  # grep sur "_" car les noms de fichiers contiennent _<date>
		Fichier_Date_Extension=$( ls -1tr $RepArchive"/"$linefind | grep "_" | tail -n1 )

		[[ -z $Fichier_Date_Extension ]] && { fEcho "Dossier $RepArchive"/"$linefind VIDE"; continue; }

		Extension=${Fichier_Date_Extension##*.}
		Fichier_Date=${Fichier_Date_Extension%.$Extension}
		Fichier=${Fichier_Date%_*}
		DateCourte=${Fichier_Date#${Fichier}_}
		#Extension=$Extension

		#fEchoVarsf "Fichier_Date" "Fichier" "DateCourte" "Extension"

		# la convention KBART est <champ1>_<champ2>_<champ3>
		# Surtout que les fins de fichiers _Ebooks et _Journals n'existent pas ( plus ) dans le dossier archive ???
		#
		i="$( grep -c 'ClassiquesGarnier_Global_' <<< $Fichier )"
		if [[ $i -eq 1 ]]
		 then
			i="$( grep -c '_Ebooks' <<< $Fichier )"
			j="$( grep -c '_Journals' <<< $Fichier )"
			if [[ $i -eq 1 || $j -eq 1 ]]
			 then
				NomFic2=$( cut -f4 -d"_" <<< $Fichier ) # Le 4ième champ est rejeté dans NomFic2
				NomFic2="_"$NomFic2
				NomFic=$( cut -f1,2,3 -d"_" <<< $Fichier) # norme KBART 3 champs séparés par _
			 else
				NomFic2=""
			fi
		 else
			NomFic2=""
		fi
		printf "%s\t%s\t%s\t.%s\t%s\t%s\t%s\n" "$Editeur" "$Fichier" "$Fichier_Date_Extension" "$Extension" "$DateCourte" "$NomFic2" "N" >> $V05_Fichier_Entree_pourMajEditeur
	fi

done < $V06_Dossiers_Archive


# Suppression des fichiers temporaires
#
find ${BASERUNDIR_SCRIPT_EDITEUR} -type d -mtime +3 -exec echo "Suppression du dossier : "{} \;
find ${BASERUNDIR_SCRIPT_EDITEUR} -type d -mtime +3 -exec rm -rf {} \;

