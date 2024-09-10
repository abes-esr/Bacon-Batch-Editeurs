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
#   * 2024-06-18 : AHE : dépoussiérage , mise en fonction, ...
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
# TS_MailConf -> Envoi par mail du rapport du traitement
#
###############################################################
#
# liste des destinataires du mail et variable spécifique pour chaque source
#
function TS_MailConf
{
	TS_EchoFunction
	local Variable=""
	local Value=""
	local Separator=""

	while read Ligne
	 do
	   llb=${#Ligne};Ligne=${Ligne##* \#};lla=${#Ligne}
	   [[ $lla -lt $llb ]] && continue # si ok c'est que la ligne est un commentaire
	   Value=${Ligne##*=}
	   [[ ${#Value} -eq 0 ]] && continue

	   Variable=${Ligne%%=*}
	   Separator=""
	   case $Variable in
	     "Administrateurs")
	       [[ ${#Administrateurs} -gt 0 ]] && Separator=","
	       Administrateurs=${Administrateurs}${Separator}${Value}
	       ;;
	     "Fonctionnels")
	       [[ ${#Fonctionnels} -gt 0 ]] && Separator=","
	       Fonctionnels=${Fonctionnels}${Separator}${Value}
	       ;;
	     *) echo "Variable inconnue : seuls sont autorisés Administrateurs et Fonctionnels .";;
	   esac
   done < $BASECONF_SCRIPT_EDITEUR/TS_Mail.conf
}

###############################################################
#
# TS_01_Pre_Traitement -> Pré-traitement avant lancement de l'algorithme de traitement et de comparaison des fichiers
#
###############################################################
# format du fichier : FicEntree=${BASECONF_SCRIPT_EDITEUR}/TS_01_URLsATraiter.tsv
# 1                                     	2                     	3                                         	4
# APS:Physical Review journal KBART file	APS_GLOBAL_ALLJOURNALS	https://harvest.aps.org/holdings/kbart.tsv	APS_AllTitles_2024_05_17
# JSTOR:Arts & Sciences I	JSTOR_COUPERIN_ARTS-AND-SCIENCES-I	https://www.jstor.org/kbart/collections/as	JSTOR_Global_Arts&SciencesICollection_2023-02-17

function TS_01_Pre_Traitement
{
	TS_EchoFunction

  fEchof "Récupération du fichier d'entrée géré par l'ABES."


  local FicEntree=${BASECONF_SCRIPT_EDITEUR}/TS_01_URLsATraiter.tsv
  fEchoVarf "FicEntree"
  [[ ! -s $FicEntree ]] && { fEchof "Le fichier d'entrée $FicEntree n'existe pas ou est vide."; return 1; }
  cp $FicEntree $V01_Fichier_Entree_pourMajEditeur
  fEchof
  fEchof "La ligne complete devrait contenir les champs suivants :"
  fEchof "1       2       3   4         5              6       7"
  fEchof "Editeur NomFic1 URL Extension DateMajEditeur NomFic2 ATraiterOuiNon"
  fEchof "Or elle ne contient que les 4 premiers ; il manque donc : DateMajEditeur NomFic2 ATraiterOuiNon"
  fEchof "Rajout des champs manquants."
  sed -e "s/.*/&\t"$(date +'%Y-%m-%d')"\t\tO/" --in-place $V01_Fichier_Entree_pourMajEditeur
	return $?
}

###############################################################
#
# TS_02_AtraiterOuiNon -> Retourne 0 si le fichier doit être traité , 1 s'il ne doit pas l'être.
#
###############################################################
#
function TS_02_AtraiterOuiNon
{
	TS_EchoFunction
	# tous les fichiers doivent être traités
	return 0
}

###############################################################
#
# TS_03_RecuperationDuFichierKBART -> <URL> : Récupération du fichier KBART à traiter
#
###############################################################
function TS_03_RecuperationDuFichierKBART
{
	TS_EchoFunction
	local lURL="$1"
	# les commandes curl pouvant générer des erreurs ; je conserve les fichiers d'erreurs de chaque commande dans un fichier séparé
	# ==> je transforme l'url en nom de fichier :
	# https://dl.acm.org/feeds/acm_kbart_books.txt devient dl.acm.org_feeds_acm_kbart_books.txt
	local fichier=${lURL#*:\/\/}
	fichier=${fichier//\//_}
	V03_FichierKBART=${RUNDIR}/03/${fichier}
	V03_FichierKBART_stderr=${V03_FichierKBART}"_stderr"
	fEchoVarf "V03_FichierKBART"
	fEchoVarf "V03_FichierKBART_stderr"
	###############################################################
	# Exécution de l'url et récupération du fichier correspondant
	fEcho "curl -L -v --max-redirs 10 \\"
	fEcho "   $lURL \\"
	fEcho "  -o $V03_FichierKBART \\"
	fEcho "  --stderr $V03_FichierKBART_stderr"
	curl -L -v --silent --show-error --max-redirs 10 $lURL -o $V03_FichierKBART --stderr $V03_FichierKBART_stderr
	local rcCURL=$?
	fEchoVarf "rcCURL"
	[[ $rcCURL -ne 0 ]] && { man curl | grep "EXIT CODES" -A 200 | grep -e "[[:space:]]\+${rcCURL}[[:space:]]\+" -A 1 ; }
  return $rcCURL
}

###############################################################
#
# TS_03_ErreurDansLaRecuperationDuFichierKBART : Gestion de l'erreur de récupération du fichier KBART
#
# Détection d'éventuelles erreurs de chargement par CURL
#
###############################################################
#
function TS_03_ErreurDansLaRecuperationDuFichierKBART
{
	TS_EchoFunction
	local lURL="$1"
  i=0
	# Vérification que le fichier d'erreur de CURL ne contienne pas une indication d'erreur.
	# Il faut récupérer le dernier code http car en cas de redirect il est d'abord égal à 302
	HTTPLine=$( grep "< HTTP/1.1 " $V03_FichierKBART_stderr | tail -n 1 )
	HTTPLine=${HTTPLine/$'\x0D'}
	HTTPCode=${HTTPLine#< HTTP/1.1 };HTTPCode=${HTTPCode%% *}
	[[ $HTTPCode -ne 200 ]] && i=1

	#local i=$(grep  "HTTP/1.1 404 Not Found" $V03_FichierKBART_stderr| wc -l)

	# Vérification que le fichier chargé par CURL ne contienne pas une indication d'erreur (...error...)
	let i+=$(grep  "404: Page not found" $V03_FichierKBART  | wc -l)

	# Si une des deux conditions ci-dessus est satisfaite, on ne traite pas le fichier chargé et
	# on indique l'erreur dans le fichier de log et dans le mail de rapport
	if [[ $i -ne 0 ]]
	 then
		fLogMail
		fLogMail "🌵 ATTENTION : le fichier $lURL n'a pas pu être chargé."
		fLogMail "🌵 ATTENTION : des erreurs ont été détectées."
		fLogMailVarf "HTTPLine"
		fLogMailVarf "HTTPCode"
		fLogMail
		return 1
	fi
	# Protection de l'écriture dans le fichier de mail car des \x0D sont récupérés de la trace d'erreur curl
	# et il faut absolûment les éliminer/remplacer sinon le mail expedie les traces en fichier attaché
	# et pas dans le corps du message, car le fichier est considéré comme binaire et pas comme texte.
	fEchof
	fEchof "Analyse des entêtes de la réponse pour détecter d'éventuels redirects."
	fEchof

	i=$(grep  "HTTP/1.1 301" $V03_FichierKBART_stderr | wc -l)
	if [[ $i -ne 0 ]]
	 then
		fLogMailWarning_URL
		fLogMailWarning_URL " -> $lURL"
	  fLogMailWarning_URL "👁 ATTENTION : demande de redirection de l'url de : "
	  fLogMailWarning_URL $( grep  -B 10 "HTTP/1.1 301" $V03_FichierKBART_stderr | grep "> GET " $V03_FichierKBART_stderr | head -n 1 | sed -e "s/\x0D/\x0A/g" )
	  fLogMailWarning_URL " vers :"
    fLogMailWarning_URL $( grep "< Location:" $V03_FichierKBART_stderr )
	fi
	i=$(grep  "HTTP/1.1 302" $V03_FichierKBART_stderr | wc -l)
	if [[ $i -ne 0 ]]
	 then
		fLogMailWarning_URL
		fLogMailWarning_URL " -> $lURL"
	  fLogMailWarning_URL "👁 ATTENTION : demande de redirection de l'url de : "

	  fLogMailWarning_URL $( grep  -B 10 "HTTP/1.1 302" $V03_FichierKBART_stderr | grep "> GET " $V03_FichierKBART_stderr | head -n 1 | sed -e "s/\x0D/\x0A/g" )
	  fLogMailWarning_URL " vers :"
    fLogMailWarning_URL $( grep "< Location:" $V03_FichierKBART_stderr )
	fi
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

	# alimentation des variables à partir du fichier d'entrée
	#
	# 1       2                                     3                                                           4     5           6       7
	# Editeur	NomFic1                               url #non utilisé pour AbesBacon                        Extension  DateMajEditeur NomFic2 ATraiterOuiNon
  # EDITEUR	Book_Coverage_KBART	                  Book_Coverage_KBART_2017-01-29.tsv	                        .tsv	2017-01-29		      N
  # EDITEUR	ClassiquesGarnier_Global_ColAcademie2	ClassiquesGarnier_Global_ColAcademie2_Ebooks_2015-11-04.tsv	.tsv	2015-11-04	_Ebooks	N

	# Renommage du fichier Editeur aux standards Bacon
	#

  # Construction du nom des fichiers
	#
	NomFic=${NomFic1}${NomFic2}
  DateMajEditeur=$(date +'%Y-%m-%d')
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

###############################################################
#
# TS_09_DupliquerFichierDansDerniereVersion : Duplication de certains fichiers dans le dossier derniere version.
#
###############################################################
function TS_09_DupliquerFichierDansDerniereVersion
{
	TS_EchoFunction

	fEchof "PAS POUR AUTRE"
}

###############################################################
#
# TS_13_ErreurTraitement : Détection d'éventuelles erreurs lors du traitement
#
###############################################################

function TS_13_ErreurTraitement
{
	TS_EchoFunction
	fEchof "PAS POUR AUTRE"
}
