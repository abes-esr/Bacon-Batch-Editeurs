#!/bin/bash

###############################################################
#
# MajEditeurs.sh
#
# PARAMETRE :
#   - 1 : source (KbPlus, CUFTS, AbesBacon, ...
#
# Fichier de paramétrage pour le script shell CheckMajEditeurs.sh
# Détection des mises à jour des fichiers KBART (KbPlus et Bacon)
# Comparaison via DAFF et visualisation du résultat de la comparaison
#
# Serveur : Begonia (production), Bordeauxdev (test)
#
# Auteur : SRY
# Date de création : mai 2016
#
# Mises à jour :
#   * 2016-01-05 : SRY : version initiale pour KbPlus
#   * 2016-05-20 : SRY : version intégrant le traitement AbesBacon
#   * 2016-07-26 : SRY : version intégrant le traitement CUFTS
#   * 2017-01-16 : SRY : version entégrant un traitement pour des fichiers "Autre" (proche de KbPlus,
#                        mais fichiers issus du site de l'éditeur)
#   * 2024-05-14 : AHE : dépoussiérage , mise en fonction, ...
#
###############################################################

# EXEMPLES d'appel sur begonia
# crontab -l
# 45 20  * * *  /home/devel/MajEditeurs/CheckMajEditeurs.sh ProQuest > /home/devel/MajEditeurs/Erreur/errProQuest.txt 2> /home/devel/MajEditeurs/Erreur/errProQuest2.txt
# 00 20  * * *  /home/devel/MajEditeurs/CheckMajEditeurs.sh EBSCO > /home/devel/MajEditeurs/Erreur/errEBSCO.txt 2> /home/devel/MajEditeurs/Erreur/errEBSCO2.txt
# 30 21  * * 0-4  /home/devel/MajEditeurs/Traite_OwnCloud.sh AbesBacon 1 > /home/devel/MajEditeurs/Erreur/errOwnCloud.txt 2> /home/devel/MajEditeurs/Erreur/errOwnCloud2.txt
# 40 21  * * 0-4  /home/devel/MajEditeurs/CheckMajEditeurs.sh AbesBacon > /home/devel/MajEditeurs/Erreur/errAbesBacon.txt 2> /home/devel/MajEditeurs/Erreur/errAbesBacon2.txt
# 50 23  * * 0-4  /home/devel/MajEditeurs/CheckMajEditeurs.sh Autre > /home/devel/MajEditeurs/Erreur/errAutre.txt 2> /home/devel/MajEditeurs/Erreur/errAutre2.txt
# 00 23  * * 0-4  /home/devel/MajEditeurs/CheckMajEditeurs.sh KbPlus > /home/devel/MajEditeurs/Erreur/errKbPlus.txt 2> /home/devel/MajEditeurs/Erreur/errKbPlus2.txt

function CMajE_Usage
{
	echo
	echo "  #"
	echo "  #  ATTENTION : appel de $0 incorrect, nombre d'arguments $1 non valable."
	echo "  #"
	echo
	echo "  #"
	echo "  # Appel correct : $0 <Éditeur>"
	echo "  #"
	echo
	echo "  #"
	echo '  # Exemple : '$0' "AbesBacon"'
	echo "  #"
}

###############################################################
#
# Fin des fonctions
#
###############################################################

###############################################################
#
# Chargement du fichier de paramétrage
# Initialisation des variables et des fichiers
#
###############################################################
[[ $# -ne 1 ]] && { CMajE_Usage "$#"; exit 1;}

EDITEUR=$1
RACINE=/home/devel/MajEditeurs_ahe

SCRIPT=$( basename $BASH_SOURCE );SCRIPT=${SCRIPT%.sh}
###############################################################
# Chargement du fichier de paramétrage
#
. $RACINE/bin/Definition_Env.sh

# Inclusion des fonctions de traitements communes ( à placer après l'appel de Definition_Env.sh )
. $RACINE/bin/Traitement_Commun.sh

# Inclusion des fonctions de traitements spécifiques ( à placer après l'appel de Definition_Env.sh )
. $RACINE/bin/Traitement_Specifique_${EDITEUR}.sh

ENV_AfficheVariables

###############################################################
# Initialisation des variables
#
# nombre de fichiers présent dans le fichier d'entrée
let nb_fic_total=0

# Nombre de fichiers traité
let nb_fic_traite=0

# Nombre de fichier traité et sur lequel ont été détectés une mise à jour
let nb_fic_maj=0

# Indicateur de nouveau Corpus (valeur=1), nécessite l'initialisation du répertoire d'archive
let nouveaucorpus=0

###############################################################
# [LOG] Initialisation des fichiers de LOG et de Mail
#
fLogMail "########### Début du traitement  le $YYYYmmdd_HHMMSS ###########"
fLogMail

###############################################################
#
# ALGORITHME DE TRAITEMENT DES FICHIERS KBART
#
###############################################################

###############################################################
# lecture de chaque ligne du fichier d'entrée qui contient
# les fichiers kbart ( AbesBacon ) ou l'URL KBART à traiter
###############################################################
DateInitialisationBouquet="2015-01-01"
V00_KBART_Global_Template=${BASECONF}/KBART_Global_Template_2016-04-26.tsv
V01_Fichier_Entree_pourMajEditeur=$RUNDIR/01_Fichier_Entree_pourMajEditeur
V03_FichierKBART=$RUNDIR/03_FichierKBART
V04_FichierKBART=""
V05_FichierHistoriqueDesTraitements=""
VO6_DernierFichierEnArchive_Trie=""
VO6_FichierKBART_Trie=""
V07_ResultatDaff_csv=""
V07_RepServeurWeb="/var/www/html/bacon/MajEditeurs_ahe/"$EDITEUR # Répertoire contenant les fichiers HTML résultats du DAFF (serveur web de la machine)
V07_FichierHtmlDaffSurServeurWeb=""
VO8_FichierKBART_copieEnArchive=""
V09_DuplicationDerniereVersion_FichierKBART=""

V10_Number_htmlTRTD="$RUNDIR/10_Number_htmlTRTD.html"
> $V10_Number_htmlTRTD
V10_Number_htmlTRTD_sorted="$RUNDIR/10_Number_htmlTRTD_sorted.html"
> $V10_Number_htmlTRTD_sorted

mkdir -p ${RUNDIR}/03 # Dossier pour les fichiers de l'étape 3
mkdir -p ${RUNDIR}/04 # Dossier pour les fichiers de l'étape 4
mkdir -p ${RUNDIR}/05 # Dossier pour les fichiers de l'étape 5
mkdir -p ${RUNDIR}/06 # Dossier pour les fichiers de l'étape 6
mkdir -p ${RUNDIR}/07_Diff # Dossier pour les fichiers de l'étape 7

###############################################################
#
# PRE TRAITEMENT AVANT LE DEBUT DE L'ALGORITHME
#
###############################################################

# Constitution du fichier d'entrée contenant les URL à traiter.
#

TS_01_Pre_Traitement
case $? in
  0) fEcho "Pré traitement OK";;
  *) fEcho "Abandon du traitement pour $EDITEUR : sortie du script.";exit 1;;
esac

# Traitement du fichier d'entrée contenant les URL à traiter.
#
# V01_Fichier_Entree_pourMajEditeur pour AbesBacon
# 1       2                   3                                   4     5           6 7
#CIEPS	CIEPS_GLOBAL_ROAD	CIEPS/CIEPS_GLOBAL_ROAD_2024-05-29.txt	.txt	2024-05-29		O
#dalloz	Dalloz_Global_Dalloz-bibliotheque-fr	dalloz/Dalloz_Global_Dalloz-bibliotheque-fr_2024-05-30.txt	.txt	2024-05-30		O
# ...
# EDITEUR	Book_Coverage_KBART	Book_Coverage_KBART_2017-01-29.tsv	.tsv	2017-01-29		N
# EDITEUR	Cairn_Couperin_Revues-EcoSocPol	Cairn_Couperin_Revues-EcoSocPol_2017-01-15.tsv	.tsv	2017-01-15		N
# ...
fEcho
fEcho "################################################"
fEcho "#  Boucle de traitement des lignes du fichier V01_Fichier_Entree_pourMajEditeur :"
fEcho "#  $V01_Fichier_Entree_pourMajEditeur"
fEcho "################################################"
let baselevel++
# ahe : au lieu du while read j'ai remplacé par un mapfile puis une boucle for
# exemple :
# Fichier=/home/devel/MajEditeurs_ahe/rundir/Traite_OwnCloud_ahe/AbesBacon/2024-06-02/05_Fichier_Entree_pourMajEditeur
# mapfile -t aLines < $Fichier
# echo ${#aLines[*]};for line in "${aLines[*]}"; do echo "$line"; done

mapfile -t aLines < $V01_Fichier_Entree_pourMajEditeur
cLines=${#aLines[*]}
fEcho "$cLines lignes dans le fichier $V01_Fichier_Entree_pourMajEditeur"
for (( cl=0;cl<$cLines;cl++ ))
 do
  line="${aLines[$cl]}"
  fEcho
  fEcho
  fEcho
  fEcho
  fEcho "*************************************"
  fEcho "*                                   *"
  fEcho "*   Numéro de ligne : $(( cl+1 )) / $cLines "
  fEcho "*                                   *"
  fEcho "*************************************"
  fEchoVars "line"
  [[ -z $line ]] && { fEcho "ligne vide : pas de traitement." ; continue; }
  # Récupération des champs de line
	# 1       2                   3                                   4     5           6 7
  # EDITEUR	Book_Coverage_KBART	Book_Coverage_KBART_2017-01-29.tsv	.tsv	2017-01-29		N
  #
  # La commande read transforme les \t\t en simple \t => on perd 1 champ par double \t
  # Attention : ce n'est pas un bug mais un comportement défini par POSIX pour sa gestion des séparateurs :
  #      1 ou plusieurs "espaces" consécutifs = 1 "espace"
  #
  # La commande read éclate les données dans les variables en fonction des espaces et des tabulations
  #   ==> il faut gérer les blancs car dans notre usage ce ne sont pas des séparateurs.

  fEchof "1 ) Transformation des champs au contenu vide ( rien entre 2 tabulations ) par le mot \"vide\" => <tab><tab> devient <tab>vide<tab>"
  #
  # remarque : la règle est appliquée 2 fois car le pointeur sur la chaîne avance après la première substitution et dépasse le deuxième \t ,
  #     puisqu'il est inclus dans la première substitution - cette façon de faire évite les boucles infinies ;
  #     il faut donc faire une deuxième passe sur les \t délaissés.
  #             dans \t\t\t seuls les 2 premiers \t seraient traités.
  LigneSansVides=$( sed -e "s/\t\t/\tvide\t/g;s/\t\t/\tvide\t/g" <<<  "$line" )

  fEchof "2 ) Protection des espaces blancs : \" \"=32=\x20 ==> unicode zone privée panel 1 (E000 + 0020) = \u{E020}=\xee\x80\xa0 "
  LigneSansBlancs=$( sed -e "s/ /\xee\x80\xa0/g" <<<  "$LigneSansVides" )

  read Editeur NomFic1 URL Extension DateMajEditeur NomFic2 ATraiterOuiNon <<< $LigneSansBlancs
  #echo $Editeur | hexdump -C
  Editeur=${Editeur//$'\xEE\x80\xA0'/ }
  NomFic1=${NomFic1//$'\xEE\x80\xA0'/ }

  fEchoVars "Editeur" "NomFic1" "URL" "Extension" "DateMajEditeur" "NomFic2" "ATraiterOuiNon"

  [[ $NomFic2 == "vide" ]] && NomFic2=""
  [[ $DateMajEditeur == "vide" ]] && { fEcho "DateMajEditeur est vide ==> abandon du traitement"; continue; }
  [[ ${Extension:0:1} == "." ]] && Extension=${Extension:1}

	TS_02_AtraiterOuiNon "$ATraiterOuiNon"
  if [[ $? -ne 0 ]]
   then
    fEcho "Cette ligne n'est pas à traiter ==> Traitement  partiel pour alimenter le fichier résultat HTML."
    TC_02_FichierNonATraiter "$cl"
    continue
   else
	  let nb_fic_traite++
  fi

	V03_FichierKBART="$RUNDIR/03_FichierKBART"
	V03_FichierKBART_erreurs="$RUNDIR/03_FichierKBART_erreurs"

	TS_03_RecuperationDuFichierKBART "$URL"
	# même en cas de 404 NOT FOUND rcCurl=0 : en effet la réponse est bien revenue.
	TS_03_ErreurDansLaRecuperationDuFichierKBART "$URL"
	if [[ $? -ne 0 ]]
	 then
	  fEcho
		fEcho "Abandon du traitement"
		fEcho
		continue
	fi
  TC_03_Conformite_KBART "$URL"
  if [[ $? -eq 255 ]]
	 then
	  fEcho
		fEcho "Abandon du traitement"
		fEcho
		continue
	fi
  #
	###############################################################
	# Traitement du nom du fichier ( on renomme les fichiers au standard Bacon )
	#
	V04_FichierKBART=""

	TS_04_NormalisationDuNomDuFichierAuStandardBacon

	fEcho "cp $V03_FichierKBART \\"
	fEcho "   $V04_FichierKBART"
	cp $V03_FichierKBART $V04_FichierKBART

  fEcho

	let nb_fic_total++

	# teste la présence ou non du répertoire archive pour le fichier traité
	# et lit le fichier historique Date.txt pour déterminer la date du dernier traitement.
  V05_FichierHistoriqueDesTraitements=$RepArchive"/"$NomFic"/Date.txt"
  #fEchoVar "V05_FichierHistoriqueDesTraitements"
  V05_DateDernierTraitement=""
	V05_DernierFichierEnArchive=""
	V05_DernierDaffHtml=""
	V05_UrlDernierDaff=""

	TC_05_VerificationPresenceArchivesEtHistorique
  nouveaucorpus=$?

  fEcho

  VO6_FichierKBART_Trie="${RUNDIR}/06/${NomFic}_${DateMajEditeur}.${Extension}_Trie_Encours"
  VO6_DernierFichierEnArchive_Trie="${RUNDIR}/06/${NomFic}_${DateMajEditeur}.${Extension}_Trie_Archive"

  TC_06_Il_y_a_t_il_DuNouveau_Diff
  delta=$?

	fLog "------------------------------------------------------------"
	fLog  $(date +'%Y-%m-%d_%H:%M:%S')
	fLog "Num ligne : " $nb_fic_traite
	fLog "Nouveau Corpus : " $nouveaucorpus
	fLog "LINE : " $line
	fLog "URL: " $URL
	fLog "NomFic: " $NomFic
	fLog "NumFic: " $NumFic
	fLog "DateMajEditeur " $DateMajEditeur
	fLog "DateDernierTraitement " $V05_DateDernierTraitement
	fLog "NomFicRen: " $NomFic1"_"$DateMajEditeur$NomFic2
	fLog "Diff : " $RepArchive"/"$NomFic"/"$NomFic"_"$V05_DateDernierTraitement".tsv"
	fLog "Res Diff : " $delta

	PositionDansFichierHTML=0;
	if [[ $delta -gt 0 ]]
	 then # le fichier a été mis à jour
		V07_ResultatDaff_csv=${RUNDIR}/07_Diff/${NomFic}_${V05_DateDernierTraitement}_${DateMajEditeur}.csv
	  V07_ResultatDaff_html_sansCaracteresSpeciaux=${RUNDIR}/07_Diff/${NomFic}_${V05_DateDernierTraitement}_${DateMajEditeur}_sansCaracteresSpeciaux.html
	  V07_ResultatDaff_html_avecCaracteresSpeciaux=${RUNDIR}/07_Diff/${NomFic}_${V05_DateDernierTraitement}_${DateMajEditeur}_avecCaracteresSpeciaux.html
	  V07_FichierHtmlDaffSurServeurWeb=${V07_RepServeurWeb}/${NomFic}_${V05_DateDernierTraitement}_${DateMajEditeur}.html
	  VO8_FichierKBART_copieEnArchive=${RepArchive}/${NomFic}/${NomFic}_${DateMajEditeur}.tsv
    V08_ConservationDerniereVersion_FichierKBART=${RepDerniereVersion}/${NomFic1}_${DateMajEditeur}${NomFic2}.tsv

		TC_07_Daff
		if [[ $? -ne 0 ]]
	   then
      fEcho "Abandon du traitement pour :"
      fEchoVar "line"
      continue
		fi
		TC_08_ArchivageFichierEnCours

		# On duplique certains fichiers
		V09_DuplicationDerniereVersion_FichierKBART=""
		TS_09_DupliquerFichierDansDerniereVersion

		# incrémentation du compteur des fichiers mis à jour
		let nb_fic_maj++

		[[ $V05_DateDernierTraitement == "$DateInitialisationBouquet" ]] && let PositionDansFichierHTML=1
    ###############################################################
	  # [HTML] Écriture dans le fichier résultat HTML: écriture de la ligne correspondante avec la couleur associée à la date de dernière modification du fichier
	  # C'est un nouveau fichier : il faut donc générer une url pour le nouveau daff html.
	  URL_DernierDaff=${URLhttps}/${NomFic}_${V05_DateDernierTraitement}_${DateMajEditeur}.html

		###############################################################
		# [LOG] Ecriture dans le fichier de LOG
		fLogMail "------------------------------------------------------------"
		fLogMail "Numéro fichier mis à jour : " $nb_fic_maj
		fLogMail "Corpus: " $NomFic
		fLogMail "LE FICHIER A ÉTÉ MIS À JOUR PAR "$EDITEUR
		fLogMail "Dates des fichiers comparés :  " $V05_DateDernierTraitement "et " $DateMajEditeur
		fLogMail "URL du fichier "$EDITEUR" : "$URL
		fLogMail "Voir le fichier HTML du résultat de la comparaison : " $URLhttps"/"$NomFic"_"$V05_DateDernierTraitement"_"$DateMajEditeur'.html'
		fLogMail "------------------------------------------------------------"
		fLogMail ""
	 else # le fichier N'a PAS été mis à jour
	  URL_DernierDaff=$V05_UrlDernierDaff

		let DateMajEditeur_s=$(date -d $DateMajEditeur  +'%s')  # %s     seconds since 1970-01-01 00:00:00 UTC ( EPOQ )
		let DateDernierTraitement_s=$(date -d $V05_DateDernierTraitement +'%s')
		let DeltaDate=DateMajEditeur_s-DateDernierTraitement_s
		# Mise en avant des fichiers les plus récents (3 couleurs pour les fichiers les plus récents, 1 couleur pour les erreurs)
		#
		[[ $DeltaDate -le $TempsVisu1 ]] && let PositionDansFichierHTML=2
		[[ $DeltaDate -gt $TempsVisu1 && $DeltaDate -le $TempsVisu2 ]] && let PositionDansFichierHTML=3
		[[ $DeltaDate -gt $TempsVisu2 ]] && let PositionDansFichierHTML=4
		fLog
		fLog "PAS DE MODIFICATION"
		fLog
	fi

	# [HTML] Écriture dans le fichier résultat HTML : écriture de la ligne correspondante avec la couleur associée
	TC_10_HtmlOutputLine "$PositionDansFichierHTML" "$cl"

	fLog "------------------------------------------------------------"

  TC_11_GestionFichiersArchive

 done # du for

let baselevel--
###############################################################
# FIN DE L'ALGORITHME
###############################################################


###############################################################
#
# ALIMENTATION DES FICHIERS DE MAIL, DE LOGS, D'ERREUR
# Envoi du mail de rapport
###############################################################

###############################################################
# Création du fichier HTML résult
#
TC_12_SortieHtml_Editeur_Recapitulatif_desMAJ

###############################################################
# [LOG] Écriture dans les fichiers de LOG et de Mail (récapitulatif)
fLogMail ""
fLogMail "------------------------------------------------------------"
fLogMail "Nombre total de fichiers      : " $nb_fic_total
fLogMail "Nombre de fichiers traités    : " $nb_fic_traite
fLogMail "Nombre de fichiers mis à jour : " $nb_fic_maj
fLogMail "------------------------------------------------------------"


###############################################################
# [MAIL] Écriture dans le fichier MAIL (récapitulatif)
fLogMail "Voir le fichier de LOG  ("$LogFile") sur le serveur "$Serveur
fLogMail "Voir le fichier HTML des derniers résultats : " $URLhttps"/"$FichierHtml_Editeur_Recapitulatif_desMAJ
fLogMail "------------------------------------------------------------"

###############################################################
# Recherche d'éventuelles erreurs dans le traitement des fichiers
#
TS_13_ErreurTraitement
TC_13_ErreurTraitement

#TC_14_VerificationGeneraleDesErreurs
###############################################################

TC_15_MailConf
###############################################################
# Ajout du nombre de maj au sujet du message mail si des modifications
# ont été détectées sur un ou plusieurs fichiers
#
MAJ=""
case $nb_fic_maj in
 0) MAJ="pas de mises à jour.";;
 1) MAJ="1 mise à jour.";;
 *) MAJ="$nb_fic_maj mises à jour.";;
esac
ObjetDuMessage=$ObjetDuMessage" : "$MAJ
TS_15_MailConf
TC_15_EnvoiMailRecapitulatif

#
# Suppression des dossiers rundir de plus de 3 jours
#

TC_16_GestionRUNDIR
