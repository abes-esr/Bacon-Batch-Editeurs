###############################################################
#
# PARAMETRE :
#   - 1 : source (KbPlus, CUFTS, AbesBacon, Autre ...
#   - 2 : type de traitement spécifique (Pre_Traitement, Recup_Fichier, Erreur, ...)
#   - 3 : pour "Récup_Fichier et Renommer_Fichier" : nom du fichier ou de l'url à traiter
#   - 4 : ProQuest (indication ou non de nettoyer le fichier et EBSCO (second url pour fichier à concatener au premier)
#
# sous programme du programme MajEditeurs.sh
#
# Fichier des traitements spécifiques pour le script shell CheckMajEditeurs.sh
# Détection des mises à jour des fichiers KBART
#
# Serveur : Begonia (production), Bordeauxdev (test)
#
# Auteur : SRY
# Date de création : mai 2016
#
# Mises à jour :
#   * 2016-05-20 : SRY : version initiale mise en place pour le traitement AbesBacon
#   * 2016-07-26 : SRY : version intégrant le traitement CUFTS
#   * 2017-01-16 : SRY : version entégrant un traitement pour des fichiers "Autre" (proche de KbPlus,
#                        mais fichiers issus du site de l'éditeur)
#   * 2017-03-03 : SRY : fct Renommer_Fichier : pour KbPlus et Autre, intégration du nom renommé
#						 de l'éditeur et de la mention de type (alljournals, alltitles, openaccess)
#						 dans le fichier d'entrée et non plus calcul par programme.
#   * 2024-05-14 : AHE : dépoussiérage , mise en fonction, ...
#
###############################################################

function TS_EchoFunction
{
	Function=${FUNCNAME[1]}
	fEchom1
	fEchom1 "--> Fonction $Function "
	fEchom1 "    |   "$( sed -e "/^#[[:space:]]*${Function}[[:space:]]\+/!d;s/^#[[:space:]]*${Function}[[:space:]]*//" $BASH_SOURCE )
  fEchom1 "    |"
}


###############################################################
#
# TS_00_DateHeure_DuDernier_Traite_OwnCloud : récupère la date et l'heure du dernier traitement effectué par Traite_OwnCloud
#
###############################################################
DateHeure_DuDernier_RUNDIR_DeTraite_OwnCloud=""

function TS_00_DateHeure_DuDernier_Traite_OwnCloud
{
	TS_EchoFunction
	#
	# /!\ grep "/20" => cette fonction ne sera plus valable après 2099-12-31 ;-)
	#
  DateHeure_DuDernier_RUNDIR_DeTraite_OwnCloud="$( ls -1dt $BASERUNDIR/"Traite_OwnCloud_ahe"/$EDITEUR/* | grep "/20" | head -n1 )"
  fEchoVarf "DateHeure_DuDernier_RUNDIR_DeTraite_OwnCloud"
  [[ ! -d $DateHeure_DuDernier_RUNDIR_DeTraite_OwnCloud ]] && { fEchof "ERREUR : DateHeure_DuDernier_RUNDIR_DeTraite_OwnCloud inconnue"; exit 1; }
}
###############################################################
#
# TS_01_Pre_Traitement : Pré traitement avant lancement de l'algorithme de traitement et de comparaison des fichiers
#
###############################################################

function TS_01_Pre_Traitement
{
	TS_EchoFunction
	TS_00_DateHeure_DuDernier_Traite_OwnCloud

	fEchof "Récupération du fichier d'entrée généré par le script Traite_OwnCloud.sh."
  local FicEntree=$DateHeure_DuDernier_RUNDIR_DeTraite_OwnCloud/"05_Fichier_Entree_pourMajEditeur"
  fEchoVarf "FicEntree"
  [[ ! -s $FicEntree ]] && { fEchof "Le fichier d'entrée $FicEntree n'existe pas ou est vide."; return 1; }
  cp $FicEntree $V01_Fichier_Entree_pourMajEditeur
	return $?
}

###############################################################
#
# TS_02_AtraiterOuiNon : retourne 0 si le fichier doit être traité , 1 s'il ne doit pas l'être.
#
###############################################################
#
function TS_02_AtraiterOuiNon
{
	TS_EchoFunction
	local ATraiterOuiNon=$1 # 7ieme champ : O / N
	# On récupère dans le fichier d'entrée généré dans une phase précédente ( Traite_OwnCloud ) si le fichier doit être traité ou non (O/N)
	# V01_Fichier_Entree_pourMajEditeur pour AbesBacon
  # 1			2									3                                   		4     5           6 7
  # CIEPS	CIEPS_GLOBAL_ROAD	CIEPS/CIEPS_GLOBAL_ROAD_2024-05-19.txt	.txt	2024-05-19		O
  # 1				2																			3																														4			5						6	7
  # dalloz	Dalloz_Global_Dalloz-bibliotheque-fr	dalloz/Dalloz_Global_Dalloz-bibliotheque-fr_2024-05-20.txt	.txt	2024-05-20		N

	[[ $ATraiterOuiNon == "N" ]] && return 1
	return 0
}

# Opération commune à tous les éditeurs
# TC_02_FichierNonATraiter

###############################################################
#
# TS_03_RecuperationDuFichierKBART : <Fichier> : Récupération du fichier KBART à traiter
#
###############################################################
# Explications de Delphine :
# CIEPS est le fournisseur
# CIEPS_GLOBAL_ROAD est un bouquet du CIEPS (Centre international de l'ISSN).
# CIEPS_GLOBAL_ROAD_2024-05-19.txt est le fichier KBART correspondant au bouquet.
# /home/devel/bacon/CIEPS/ est le chemin du dossier pour chaque fournisseur
#  , copie du cloud où les fournisseurs déposent eux-mêmes leurs fichiers KBART.
#
function TS_03_RecuperationDuFichierKBART
{
	TS_EchoFunction
	local fichier="$1" # fichier dans le cas d'AbesBacon, url sinon
	local commande="$2" # SANS INTÉRÊT ici => voir Autre
	# Pour "AbesBacon" : récupération dans le répertoire OwnCloud de l'éditeur
	#
	###############################################################
	# copie du fichier correspondant dans le répertoire OwnCloud
	# Répertoire OwnCloud contenant les fichier des éditeurs (pour AbesBacon uniquement)
	#
	# RepOwnCloud=/home/devel/bacon est un point de montage sur begonia d'un dossier d'erebus
	# erebus.v102.abes.fr:/mnt/EREBUS/zpool_data/KatProd/bacon   8,0T    6,8T  1,3T  85% /home/devel/bacon
	RepOwnCloud="/home/devel/bacon"
	fEchof "\$RepOwnCloud/\$fichier=$RepOwnCloud"/"$fichier"
	fEchoVarf "V03_FichierKBART"
	fEchof
	fEchof "Identification du séparateur ( censé être tabulation )."
	fEchof
	if [[ -s $RepOwnCloud"/"$fichier ]]
	 then
	  local LigneDEntete=$( head -n 1 $RepOwnCloud"/"$fichier  )
	  LigneDEntete=${LigneDEntete//\"/}
	  #fEchoVarf "LigneDEntete"
	  local Separateur=${LigneDEntete/publication_title/}
	  #fEchoVarf "Separateur"
	  Separateur=${Separateur:0:1}
	  fEchof "Separateur=${Separateur}="

	  if [[ $Separateur != $'\t' ]]
	   then
		  fEchof "Le séparateur est différent de la tabulation ==> il est remplacé par \t"
		  # la commande columns crée des blancs entre la fin de donnée et la tabulation => il faut les supprimer
	    column -t -s "$Separateur" -o $'\t' -x  $RepOwnCloud"/"$fichier | sed -e "s/ *\t/\t/g" > $V03_FichierKBART
	   else
	    fEchof "Le séparateur est la tabulation"
	    cp  $RepOwnCloud"/"$fichier $V03_FichierKBART
	  fi

	  # PAS SÛR : ahe 2024-06-24 : car les double-quotes sont remplacés avant la comparaison daff
	  # À supprimer le 2024-06-30 si pas de pb
	  # fEchof "Élimination des éventuels double-quotes qui entourent les champs"
	  # sed -e "s/^\"//;s/\"\t/\t/g;s/\t\"/\t/g;s/\"\r/\r/" --in-place $V03_FichierKBART
	  # il faut faire pareillement sur le dernier fichier archivé pour que la comparaison soit correcte.
	  #sed -e "s/^\"//;s/\"\t/\t/g;s/\t\"/\t/g;s/\"\r/\r/" --in-place $V05_DernierFichierEnArchive
	 else
	  fEchof "le fichier $RepOwnCloud"/"$fichier n'existe pas"
	  return 1
	fi
	return 0
}
###############################################################
#
# TS_03_ErreurDansLaRecuperationDuFichierKBART : Gestion de l'erreur de traitement du fichier KBART
#
###############################################################
#
function TS_03_ErreurDansLaRecuperationDuFichierKBART
{
	TS_EchoFunction
	fEchof "Pas de gestion d'erreur de Recup Fichier KBART"
  return 0
}

###############################################################
#
# TS_04_NormalisationDuNomDuFichierAuStandardBacon : Les fichiers récupérés par le traitement précédent sont renommés au standard BACON ( <BOUQUET>_<DATE>.tsv )
#
#
# Contenu des variables :
#    - Date du fichier
#    - NomFic : Concaténation des parties avant et après la date dans le nom originel du fichier
#		Cette variable est utilisée comme nom de répertoire et de fichier pour les Archives et les fichier de Diff
#    - NomFic1 : Partie avant la date dans le nom renommé du fichier (sert dans un 1er temps de variable de travail)
#    - NomFic2 : Partie après la date dans le nom renommé du fichier (sert dans un 1er temps de variable de travail)
#    - ExtFicInitial : extension du fichier originel : ahe : non utilisé pour AbesBAcon
#
###############################################################
#
function TS_04_NormalisationDuNomDuFichierAuStandardBacon
{
	TS_EchoFunction
	# Rappel du fichier d'entrée
	#
	# 1       2                                     3                                                           4     5           6       7
	# Editeur	NomFic1                               url #non utilisé pour AbesBacon                        Extension  DateMajEditeur NomFic2 ATraiterOuiNon
  # EDITEUR	Book_Coverage_KBART	                  Book_Coverage_KBART_2017-01-29.tsv	                        .tsv	2017-01-29		      N
  # EDITEUR	ClassiquesGarnier_Global_ColAcademie2	ClassiquesGarnier_Global_ColAcademie2_Ebooks_2015-11-04.tsv	.tsv	2015-11-04	_Ebooks	N

	# Renommage du fichier Editeur aux standards Bacon
	#
	# Corrections de qqs noms de fichiers : [ProviderName]_[Region/Consortium]_[PackageName]_[YYYY-MM-DD].txt
	#
	local NomFicAvant=$NomFic1
	while read NomAvant NomApres
	 do
	   NomAvant=${NomAvant##[[:space:]]} # Normalement pas utile !! L'injection dans le read par bash supprimant les premiers espaces
	   [[ ${NomAvant:0:1} == "#" ]] && continue
	   NomFic1=${NomFic1/$NomAvant/$NomApres}
   done < $BASECONF_SCRIPT_EDITEUR/TS_04_CorrectionsDuNomDuFichier.tsv

   [[ $NomFicAvant != $NomFic1 ]] && { fEchof "ATTENTION $NomFicAvant"; fEchof "devient $NomFic1"; }
	# Nomfic2 est vide, sauf pour ClassicGarnier_Global_Garnier cf ligne suivante :
	# EDITEUR	ClassiquesGarnier_Global_ColAcademie2	ClassiquesGarnier_Global_ColAcademie2_Ebooks_2015-11-04.tsv	.tsv	2015-11-04	_Ebooks	N
	#
	# ahe : pas bien pigé ce qu'il fallait faire ici avec NomFic2
	#
	[[ $( grep -c 'ClassiquesGarnier_Global_.*_' <<< $NomFic1 ) -eq 1 ]] && NomFic2=""

  # Construction du nom des fichiers
	#
	NomFic=${NomFic1}${NomFic2}

	fEchoVarf "NomFic1"
	fEchoVarf "NomFic2"
	fEchoVarf "DateMajEditeur"
	fEchoVarf "NomFic"
  if [[ -z $DateMajEditeur ]]
   then
    V04_FichierKBART="${RUNDIR}/04/${NomFic}.${Extension}"
   else
    V04_FichierKBART="${RUNDIR}/04/${NomFic}_${DateMajEditeur}.${Extension}"
  fi

}

# Opérations communes à tous les éditeurs
# TC_05_VerificationPresenceArchivesEtHistorique
# TC_06_Il_y_a_t_il_DuNouveau_Diff
# TC_07_Daff

###############################################################
#
# TS_09_DupliquerFichierDansDerniereVersion : Duplication de certains fichiers dans le dossier derniere version.
#
###############################################################
function TS_09_DupliquerFichierDansDerniereVersion
{
  TS_EchoFunction
  local FichiersADupliquer=${BASECONF_SCRIPT_EDITEUR}/TS_08_FichiersADupliquerDansDerniereVersion.txt
  fEchof "Le fichier ${FichiersADupliquer}"
  fEchof " si il est présent indique si le fichier traité est à dupliquer."

  [[ ! -s $FichiersADupliquer ]] && { fEchof "Pas de fichiers à dupliquer : $FichiersADupliquer est absent"; return 0;}

	local NomFicDup="$(grep \"$NomFic\" $FichiersADupliquer | cut -f2)"
	fEchoVarf NomFicDup
	if [[ -n $NomFicDup ]]
	 then
	  rm -f ${RepDerniereVersion}/${NomFicDup}_*.tsv
	  V09_DuplicationDerniereVersion_FichierKBART=${RepDerniereVersion}/${NomFicDup}_${DateMajEditeur}${NomFic2}.tsv
	  fEchof "Duplication du fichier V08_ConservationDerniereVersion_FichierKBART"
	  fEchof "      $V08_ConservationDerniereVersion_FichierKBART"
	  fEchof "     en V09_DuplicationDerniereVersion_FichierKBART"
	  fEchof "      $V09_DuplicationDerniereVersion_FichierKBART"
		cp ${V08_ConservationDerniereVersion_FichierKBART} ${V09_DuplicationDerniereVersion_FichierKBART}
	 else
	  fEchof "Le fichier V08_ConservationDerniereVersion_FichierKBART n'est pas à dupliquer."
	  fEchof "      $V08_ConservationDerniereVersion_FichierKBART"
  fi
}

###############################################################
#
# TS_13_ErreurTraitement : Détection d'éventuelles erreurs lors du traitement
#
###############################################################
#
function TS_13_ErreurTraitement
{
	TS_EchoFunction
	# on envoie en mail le delta entre les éditeurs autorisés par l'ABES et ceux présents dans owncloud.
	# Ce delta a été généré par le script Traite_OwnCloud qui passe avant le script MajEditeurs

	# $V02_FichiersATraiter_EditeursNONSelectionnesParABES de Traite_OwnCloud.sh # cette liste sera transmise par mail par CheckMajEditeurs.sh
  local FichierDesNonSelectionnesParABES=$DateHeure_DuDernier_RUNDIR_DeTraite_OwnCloud/"02_FichiersATraiter_EditeursNONSelectionnesParABES"

  fEchoVarf "FichierDesNonSelectionnesParABES"
  if [[ -s $FichierDesNonSelectionnesParABES ]]
   then
		fLogMail ""
		fLogMail "------------------------------------------------------------"
		fLogMail "AUTRES MODIFICATIONS SUR OWNCLOUD : "
		cat $FichierDesNonSelectionnesParABES | uniq >> $FicMail
		fLogMail "------------------------------------------------------------"
		fLogMail ""
	 else
		fLogMail "------------------------------------------------------------"
		fLogMail "  Pas d'éditeurs nouveaux sur OWNCLOUD"
		fLogMail "------------------------------------------------------------"
		fEchof "Le fichier FichierDesNonSelectionnesParABES n'existe pas ou est vide."
		fEchoVarf "FichierDesNonSelectionnesParABES"
	fi

	nb_fic_traite=$nb_fic_total
}

###############################################################
#
# TS_15_MailConf : MAIL rapport du traitement
#
###############################################################
#
# liste des destinataires du mail et variable spécifique pour chaque source
#
function TS_15_MailConf
{
	TS_EchoFunction

	local Ligne=""
	local Commentaire=""
	local Variable=""
	local Valeur=""
	local Separateur=""

	shopt -s extglob    # pour interdire : shopt -u extglob : -u = unset

	while read Ligne
	 do
     Ligne=${Ligne##+([[:space:]])} # Élimination des espaces en début de chaîne
	   Commentaire=${Ligne:0:1}
	   [[ $Commentaire == "#" ]] && continue # la ligne est un commentaire => on passe à la ligne suivante
	   Valeur=${Ligne##*=};Valeur=${Valeur//\"}
	   [[ ${#Valeur} -eq 0 ]] && continue

	   Variable=${Ligne%%=*}
	   Separateur=""
	   case $Variable in
	     "Administrateurs")
	       [[ ${#Administrateurs} -gt 0 ]] && Separateur=","
	       Administrateurs=${Administrateurs}${Separateur}${Valeur}
	       ;;
	     "Fonctionnels")
	       [[ ${#Fonctionnels} -gt 0 ]] && Separateur=","
	       Fonctionnels=${Fonctionnels}${Separateur}${Valeur}
	       ;;
	     *) echo "Variable inconnue : seuls sont autorisés Administrateurs et Fonctionnels .";;
	   esac
   done < $BASECONF_SCRIPT_EDITEUR/TS_15_Mail.conf
}
