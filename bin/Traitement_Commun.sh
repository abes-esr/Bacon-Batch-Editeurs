###############################################################
#
#  FONCTIONS COMMUNES À TOUS LES ÉDITEURS
#
###############################################################
#
. $RACINE/bin/BOM.sh
. $RACINE/bin/KBart_File_Header.sh
#################################################################
#
#  FONCTIONS OUTILS
#
##################################################################

function TC_EchoFunction
{
	Function=${FUNCNAME[1]}
	fEchom1
	fEchom1 "--> Fonction $Function "
	fEchom1 "    |   "$( sed -e "/^#[[:space:]]*${Function}[[:space:]]\+/!d;s/^#[[:space:]]*${Function}[[:space:]]*//" $BASH_SOURCE )
  fEchom1 "    |"
}

function TC_HtmlOutput
{
	echo "${*}" >> $V07_RepServeurWeb"/"$FichierHtml_Editeur_Recapitulatif_desMAJ
}

function TC_MailConf
{
	TS_EchoFunction
	# Sujet du mail de rapport
  #
  ObjetDuMessage="[BACON] $EDITEUR, $YYYYmmdd_HHMMSS"
  Administrateurs=""
  Fonctionnels=""
  local Ligne=""
  local Variable=""
  while read Ligne
	 do
	   llb=${#Ligne};Ligne=${Ligne##* \#};lla=${#Ligne}
	   [[ $lla -lt $llb ]] && continue # si ok c'est que la ligne est un commentaire
	   Value=${Ligne##*=}
	   [[ ${#Value} -eq 0 ]] && continue

	   Variable=${Ligne%%=*}
	   case $Variable in
	     "Administrateurs") Administrateurs=${Value};;
	     "Fonctionnels") Fonctionnels=${Value};;
	     *) echo "Variable inconnue : seuls sont autorisés Administrateurs et Fonctionnels .";;
	   esac
   done < $BASECONF_SCRIPT/TC_Mail.conf
}

function TC_BOM_HEADER_SEPARATOR
{
	FILE=$1
  BOM_File "$FILE"
	rc=$?
	fEchoVarf "rc"
	BOM_File_EchoRC "$rc" "fEchof"

	# recherche du BOM
	#
	local LANG_ORIG="$LANG"
  LANG="C" # see comment#1
  read -r TC_BHS_Header < "$FILE"

  #hexdump -C <<< $TC_BHS_Header
  case $rc in
		  8) TC_BHS_Header=${TC_BHS_Header:3};;
		161) TC_BHS_Header=${TC_BHS_Header:2};;
		162) TC_BHS_Header=${TC_BHS_Header:2};;
  esac
  #hexdump -C <<< $TC_BHS_Header
  # suppression du caractère \x0D = \r
  TC_BHS_Header=${TC_BHS_Header/$'\x0D'}
  LANG="$LANG_ORIG"

  # KBFH_FindHeaderPatternApprox retourne :
  # ( numéro du pattern trouvé ou zéro sinon )*10
  # + 0 (Pattern inclus dans header )
  # + 1 ( Pattern = header )

  KBFH_FindHeaderPatternApprox "$TC_BHS_Header"
  rc=$?
  rcPattern=$(( rc/10 ));rcExact=$(( rc%10 ))
  if [[ $rcPattern -eq 0 ]]
   then
    fEchof "Pattern not found for file header"
    TC_BHS_Header=${TC_BHS_Header//\"/}
	  #fEchoVarf "TC_BHS_Header"
	  TC_BHS_Separator=${TC_BHS_Header/publication_title/}
	  # before going further we look after if publication_title is present in the header
	  if [[ ${#TC_BHS_Separator} -eq ${#TC_BHS_Header} ]]
	    then
	      fEchoVarf "TC_BHS_Header"
	      fEchof "The file header don't even have publication_title as field !!!"
	      return 255;
	  fi
	  #fEchoVarf "TC_BHS_Separator"
	  TC_BHS_Separator=${TC_BHS_Separator:0:1}
	  fEchoVarf "TC_BHS_Separator"
   else
    case $rcExact in
     0) fEchof "Pattern #$rcPattern : ${Versions[$rcPattern]} is a substring of file header";;
     1) fEchof "Pattern #$rcPattern : ${Versions[$rcPattern]} is exactly file header";;
     *) fEchof "Pattern #$rcPattern : rcExact=$rcExact bad value; only 0 or 1 admitted."
    esac
	  read version release separator quoted <<<${Versions[$rcPattern]//_/ }
	  fEchoVarf "separator"
	  TC_BHS_Separator=${Separators[$separator]}
  fi
  return $rcPattern;
}
#################################################################
#
#  FONCTIONS DU PROCESSUS de traitement
#
##################################################################

#################################################################
#
# TC_02_FichierNonATraiter : Pas de modifications pour ce fichier
#
##################################################################

function TC_02_FichierNonATraiter
{
	TC_EchoFunction

	local NumeroLigne=$1
	###############################################################
	# Traitement du nom du fichier ( on renomme les fichiers au standard Bacon )
	#
	V04_FichierKBART=""
	TS_04_NormalisationDuNomDuFichierAuStandardBacon

	let nb_fic_total++

	# teste la présence ou non du répertoire archive pour le fichier traité
	# et lit le fichier historique Date.txt pour déterminer la date du dernier traitement.
  V05_FichierHistoriqueDesTraitements=$RepArchive"/"$NomFic"/Date.txt"
  #fEchoVar "V05_FichierHistoriqueDesTraitements"
  V05_DateDernierTraitement=""
	V05_DernierFichierEnArchive=""

	TC_05_VerificationPresenceArchivesEtHistorique
  nouveaucorpus=$?
  fEcho
  #URL_DernierDaff=${URLhttps}/${NomFic}_${V05_DateDernierTraitement}_${DateMajEditeur}.html
  URL_DernierDaff=$V05_UrlDernierDaff
  ###############################################################
	# [HTML] Écriture dans le fichier résultat HTML : écriture de la ligne correspondante avec la couleur associée
	#   à la date de dernière modification du fichier
	# Mise en avant des fichiers les plus récents (3 couleurs pour les fichiers les plus récents, 1 couleur pour les erreurs)
	#
	let DateMajEditeur_s=$(date +'%s')  # %s     seconds since 1970-01-01 00:00:00 UTC ( EPOQ )
	let DateDernierTraitement_s=$(date -d $V05_DateDernierTraitement +'%s')
	let DeltaDate=DateMajEditeur_s-DateDernierTraitement_s

	[[ $DeltaDate -le $TempsVisu1 ]] && let PositionDansFichierHTML=2
	[[ $DeltaDate -gt $TempsVisu1 && $DeltaDate -le $TempsVisu2 ]] && let PositionDansFichierHTML=3
	[[ $DeltaDate -gt $TempsVisu2 ]] && let PositionDansFichierHTML=4

	TC_10_HtmlOutputLine "$PositionDansFichierHTML" "$NumeroLigne"
}

###############################################################
#
# TC_03_Conformite_KBART : Vérifie la conformité au format KBART en comparant la 1ère ligne du fichier de référence et avec celle du fichier traité
#
###############################################################

function TC_03_Conformite_KBART
{
	TC_EchoFunction
  local url=$1
	fEchof "Recherche de l'encodage et du format du fichier kbart à traiter."
	TC_BOM_HEADER_SEPARATOR "$V03_FichierKBART"
  local rcTC_BHS=$?
  if [[ ${rcTC_BHS} -eq 255 ]]
   then
    fLogMail "URL du fichier : "$url
    fLogMail "La ligne d'entête du fichier ne contient même pas publication_title comme indicateur de colonne !!!"
    fLogMail "$( head -n 250 $V03_FichierKBART )"
    return 255
  fi
	if [[ $TC_BHS_Separator != $'\t' ]]
	 then
		fLogMail "Le séparateur ${TC_BHS_Separator} est différent de la tabulation: Pattern = ${Versions[$rcTC_BHS]} ."
		fEchof "Le séparateur est différent de la tabulation ==> il est remplacé par \t"
		TC_BHS_Header=${TC_BHS_Header//$TC_BHS_Separator/$'\x09'}
		#fLogMail "Type de fichier : file ${V03_FichierKBART}"
		#fLogMail $( file ${V03_FichierKBART} )
		fEchof "Création d'un fichier ${V03_FichierKBART}.non_conforme et transformation en fichier conforme."
		mv ${V03_FichierKBART} ${V03_FichierKBART}".non_conforme"
		column -t -s "$TC_BHS_Separator" -o $'\t' -x ${V03_FichierKBART}".non_conforme" | sed -e "s/ *\t/\t/g" > ${V03_FichierKBART}
	fi

	declare -a Fields=( $TC_BHS_Header )
	declare -a FieldsKBART=( $( head -n 1 $V00_KBART_Global_Template ) )
	let rc=0
	if [[ ${#FieldsKBART[*]} -ne ${#Fields[*]} ]]
	 then
	  fLogMailWarning
	  fLogMailWarning "👉 $url contient ${#Fields[*]} champs au lieu de ${#FieldsKBART[*]} ."
	  fLogMailWarning
	  local let max=$((${#Fields[*]}>${#FieldsKBART[*]}?${#Fields[*]}:${#FieldsKBART[*]}))
	  #fEchoVarf "max"
	  #echo "24 =${FieldsKBART[24]/$'\x0D'/}="
	  outputformat="%2.2d : %-35.35s - %-35.35s\n"
	  ligne=$(printf "$outputformat" "99" "RÉFÉRENCE" "FICHIER EN COURS" )
	  fEchof "$ligne"
	  for (( i=0;i<$max;i++ ))
	   do
	    ligne=$( printf "$outputformat" "$i" "${FieldsKBART[$i]/$'\x0D'/}" "${Fields[$i]}")
	    #fLogMail
	    fEchof "$ligne"
	   done
	  fEchof
	  let rc=1
	fi
	unset Fields FieldsKBART
	return $rc
}

###############################################################
#
# TC_05_VerificationPresenceArchivesEtHistorique : Présence du répertoire Archive et du fichier Date.txt (historique des traitements) .
#
###############################################################
function TC_05_VerificationPresenceArchivesEtHistorique
{
	TC_EchoFunction

  ###############################################################
	# On teste si le fichier existe déjà ou s'il apparait pour la première fois
	# Si nouveau fichier : Création du répertoire Archive
	#   et création d'un fichier Date.txt qui contiendra l'historique des traitements
	# NouveauCorpus = 1 si nouveau fichier, sinon = 0
	#
  local let NouveauCorpus=0
	# nouveau fichier (corpus)
	if [[ ! -d $RepArchive"/"$NomFic ]]
	 then
	  fEchof "Le répertoire $RepArchive"/"$NomFic n'existe pas => Création"
	  fEchof "mkdir $RepArchive"/"$NomFic"
	  mkdir $RepArchive"/"$NomFic
	  [[ $? -ne 0 ]] && { fEchof;fEchof "PB à la création du répertoire $RepArchive"/"$NomFic => fin du programme."; fEchof;exit; }
	  NouveauCorpus=1
	fi

	V05_FichierHistoriqueDesTraitements=$RepArchive"/"$NomFic"/Date.txt"
	fEchoVarf "V05_FichierHistoriqueDesTraitements"
	if [[ ! -s $V05_FichierHistoriqueDesTraitements ]]
	 then
    fEchof "Création du fichier $V05_FichierHistoriqueDesTraitements"
		echo "${DateInitialisationBouquet}:$Tiret" > $V05_FichierHistoriqueDesTraitements
		[[ $? -ne 0 ]] && { fEchof;fEchof "PB à la création du fichier V05_FichierHistoriqueDesTraitements => fin du programme."; fEchof;exit; }
		NouveauCorpus=1
	fi

	cp $V05_FichierHistoriqueDesTraitements ${RUNDIR}/05/$NomFic"_Date.txt"

	fEchof "Recherche de la dernière date de mise à jour pour le fichier traité."
	fEchof "V05_DateDernierTraitement=\$(tail -n1 $V05_FichierHistoriqueDesTraitements | cut -d\":\" -f1)"
	V05_DateDernierTraitement=$(tail -n1 $V05_FichierHistoriqueDesTraitements | cut -d":" -f1)
	fEchoVarf "V05_DateDernierTraitement"
	fEchof

  local DernierFichierEnArchive=${RepArchive}/${NomFic}/${NomFic}_${V05_DateDernierTraitement}.tsv
  fEchoVarf "DernierFichierEnArchive"
	if [[ ! -s $DernierFichierEnArchive ]]
	 then
	  fEchof
	  fEchof "NOUVEAU CORPUS"
		#avant : fEchof "Création du fichier $NomFic"_"$V05_DateDernierTraitement".tsv" contenant \"NOUVEAU_CORPUS\""
		fEchof "Création du fichier $NomFic"_"$V05_DateDernierTraitement".tsv" contenant la première ligne d'entête KBART."
		fEchof "  dans le répertoire Archive : $RepArchive"/"$NomFic ."
		fEchoVarf "V00_KBART_Global_Template"
		# avant : echo "NOUVEAU_CORPUS" > $DernierFichierEnArchive
		cp $V00_KBART_Global_Template $DernierFichierEnArchive
		NouveauCorpus=1
		fLogMail ""
		fLogMail "ATTENTION : NOUVEAU CORPUS : $NomFic"
	 else
		NouveauCorpus=0
	fi

	fEchof "Vérification du format du dernier fichier en archive : DernierFichierEnArchive"
	fEchof "  à partir de la ligne d'entête."

	TC_BOM_HEADER_SEPARATOR "$DernierFichierEnArchive"
	rcTC_BHS=$?

	V05_DernierFichierEnArchive=${RUNDIR}/05/${NomFic}_${V05_DateDernierTraitement}.tsv
	if [[ $TC_BHS_Separator != $'\t' ]]
	 then
		fLogMail "Le séparateur ${TC_BHS_Separator} est différent de la tabulation: Pattern = ${Versions[$rcTC_BHS]} ."
		fEchof "Le séparateur est différent de la tabulation ==> il est remplacé par \t"
	  column -t -s "$TC_BHS_Separator" -o $'\t' -x $DernierFichierEnArchive | sed -e "s/ *\t/\t/g" > $V05_DernierFichierEnArchive
	 else
		fEchof "Le séparateur est une tabulation ==> OK"
	  cp $DernierFichierEnArchive $V05_DernierFichierEnArchive
	fi
	# PAS SÛR : ahe 2024-06-24 : car les double-quotes sont remplacés avant la comparaison daff
	# À supprimer le 2024-06-30 si pas de pb
	# Il faut aussi éliminer les éventuels double-quotes qui entourent les champs
	#sed -e "s/\"\t/\t/g;s/\t\"/\t/g;s/^\"//;s/\"\r/\r/" --in-place $V05_DernierFichierEnArchive
	fEchoVarf "V05_DernierFichierEnArchive"
	fEchof

	# on récupère dans le fichier Date.txt du répertoire Archive la dernière url du résultat du DAFF
	fEchof "V05_DernierDaffHtml=\$(tail -n1 $V05_FichierHistoriqueDesTraitements | cut -d\":\" -f2)"
	V05_DernierDaffHtml=$( tail -n1 $V05_FichierHistoriqueDesTraitements | cut -d":" -f2 )
	fEchoVarf "V05_DernierDaffHtml"

	if [[ $V05_DernierDaffHtml != "$Tiret" ]]
	 then
		V05_UrlDernierDaff=${URLhttps}/${V05_DernierDaffHtml}
	fi
	fEchof
	fEchoVarf "V05_UrlDernierDaff"

	fEchof
  fEchoVarf "NouveauCorpus"
	return $NouveauCorpus;
}

###############################################################
#
# TC_06_Il_y_a_t_il_DuNouveau_Diff : Diff entre le fichier en cours de traitement et le fichier du chargement précédent en archive
#
###############################################################
function TC_06_Il_y_a_t_il_DuNouveau_Diff
{
	TC_EchoFunction
	fEchof "Comparaison rapide ( diff ) du dernier fichier archivé ( trié )"
	fEchoVarf "VO6_DernierFichierEnArchive_Trie"
	fEchof " avec le fichier en cours de traitement."
	fEchoVarf "VO6_FichierKBART_Trie"
	fEchof
  # vérification de la mise à jour du fichier traité par rapport à la dernière version chargée
	# , trie les fichiers avant passage du Daff à l'étape 07 .
	# Parfois le contenu des fichiers est identique mais l'ordre des lignes est différent d'1 fichier à l'autre
	#
	# FICHIER REÇU et en cours de traitement
	sort $V04_FichierKBART -o $VO6_FichierKBART_Trie
	# FICHIER TRAITEMENT PRÉCÉDENT stocké en archive
	sort "$V05_DernierFichierEnArchive" -o $VO6_DernierFichierEnArchive_Trie
	#
	fEchof "delta=\"\$(diff $VO6_FichierKBART_Trie"
	fEchof "              $VO6_DernierFichierEnArchive_Trie"
	fEchof "          | wc -l)\""
	local delta="$(diff $VO6_FichierKBART_Trie $VO6_DernierFichierEnArchive_Trie | wc -l)"
	fEchoVarf "delta"
	return $delta
}

###############################################################
#
# TC_07_Daff : Comparaison des 2 versions ( avant - maintenant ) du fichier par DAFF.
#
###############################################################
function TC_07_Daff
{
  TC_EchoFunction
  #fEchof "Vérification de l'existence des fichiers à comparer."
  [[ ! -s $V05_DernierFichierEnArchive ]] && { fEchof "Fichier inexistant ou vide"; fEchoVarf "V05_DernierFichierEnArchive"; return 1; }
  [[ ! -s $V04_FichierKBART ]] && { fEchof "Fichier inexistant ou vide"; fEchoVarf "V04_FichierKBART"; return 1; }
  ###############################################################
	# Comparaison des 2 versions du fichier par DAFF.
	# daff diff --output /home/devel/MajEditeurs_ahe/rundir/CheckMajEditeurs/AbesBacon/2024-06-10_08:58:46/07_Diff/ClassiquesGarnier_Global_CG-sgo_2020-12-15_2024-06-06.csv --input-format tsv --output-format csv /home/devel/MajEditeurs_ahe/rundir/CheckMajEditeurs/AbesBacon/2024-06-10_08:58:46/06/ClassiquesGarnier_Global_CG-sgo_2024-06-06.txt_Trie_Archive /home/devel/MajEditeurs_ahe/rundir/CheckMajEditeurs/AbesBacon/2024-06-10_08:58:46/06/ClassiquesGarnier_Global_CG-sgo_2024-06-06.txt_Trie_Encours
  fEchof "Protection des double-quotes : \"=\x22 ==> unicode zone privée panel 1 \u{E022}=\xee\x80\xa2 "
  fEchof "Protection des point-virgules : ;=\x3b ==> unicode zone privée panel 1 \u{E03B}=\xee\x80\xbb "
  #
  #  ATTENTION  : cette méthode est à généraliser si d'autres caractères posent problème.
  #               ==> à passer en fonction.
  #
  # /\xee\x80\xa2/
	#fEchof "sed -e '/\"/ s/\"/\xee\x80\xa2/g' "
	local V07_DernierFichierEnArchive_sansCaracteresSpeciaux=${V05_DernierFichierEnArchive}"_sansCaracteresSpeciaux"
	sed -e 's/"/\xee\x80\xa2/g;s/;/\xee\x80\xbb/g' $V05_DernierFichierEnArchive > $V07_DernierFichierEnArchive_sansCaracteresSpeciaux

	local V07_FichierKBART_sansCaracteresSpeciaux=$V04_FichierKBART"_sansCaracteresSpeciaux"
	sed -e 's/"/\xee\x80\xa2/g;s/;/\xee\x80\xbb/g' $V04_FichierKBART > $V07_FichierKBART_sansCaracteresSpeciaux

	fEchof
  fEchof "Comparaison de "
	fEchof "  V05_DernierFichierEnArchive"
	fEchof "avec"
	fEchof "  V04_FichierKBART ."
	fEchof
	fEchof " fichier résultat de la comparaison : V07_ResultatDaff_csv"
	fEchof
	# pour pouvoir passer la commande daff diff sans reformatage => fEcho et pas fEchof
	fEcho "daff diff --input-format tsv --output-format csv \\"
	fEcho "  --output $V07_ResultatDaff_csv \\"
	fEcho "           $V07_DernierFichierEnArchive_sansCaracteresSpeciaux \\"
	fEcho "           $V07_FichierKBART_sansCaracteresSpeciaux"
	fEchof
	fEchof
	daff diff --input-format tsv --output-format csv \
	          --output $V07_ResultatDaff_csv \
	          $V07_DernierFichierEnArchive_sansCaracteresSpeciaux \
	          $V07_FichierKBART_sansCaracteresSpeciaux 2>>$LogFile
	local DaffRC=$?
	fEchoVarf "DaffRC"

  [[ ! -s $V07_ResultatDaff_csv ]] && { fEchof "Fichier inexistant ou vide"; fEchoVarf "V07_ResultatDaff_csv"; return 1; }

  # Génération d'un fichier csv et html.
  # pour pouvoir passer la commande daff render sans reformatage => fEcho et pas fEchof
  fEcho "daff render --plain ${V07_ResultatDaff_csv} \\"
  fEcho "    --output ${V07_ResultatDaff_html_sansCaracteresSpeciaux}"
  fEchof "Avec fichier en entrée      : V07_ResultatDaff_csv"
  fEchof "      $V07_ResultatDaff_csv"
  fEchof "  et fichier html de sortie : V07_ResultatDaff_html_sansCaracteresSpeciaux"
  fEchof "      $V07_ResultatDaff_html_sansCaracteresSpeciaux"
  fEchof
	daff render --output ${V07_ResultatDaff_html_sansCaracteresSpeciaux} --plain ${V07_ResultatDaff_csv}
	[[ ! -s $V07_ResultatDaff_html_sansCaracteresSpeciaux ]] && { fEchof "Fichier inexistant ou vide"; fEchoVarf "V07_ResultatDaff_html_sansCaracteresSpeciaux"; return 1; }

	fEchof "Déprotection des double-quotes et des point-virgules dans le fichier résultat de daff."
	fEchof "sed -e 's/\xee\x80\xa2/\"/g;s/\xee\x80\xbb/;/g' ${V07_ResultatDaff_html_sansCaracteresSpeciaux} > ${V07_ResultatDaff_html_avecCaracteresSpeciaux}"
  sed -e 's/\xee\x80\xa2/"/g;s/\xee\x80\xbb/;/g' ${V07_ResultatDaff_html_sansCaracteresSpeciaux} > ${V07_ResultatDaff_html_avecCaracteresSpeciaux}
  fEchof
  # Copie du fichier html sur le répertoire HTTP
  fEchof "Copie de"
  fEchoVarf "V07_ResultatDaff_html_avecCaracteresSpeciaux"
  fEchof "sous "
  fEchoVarf "V07_FichierHtmlDaffSurServeurWeb"
	cp ${V07_ResultatDaff_html_avecCaracteresSpeciaux} ${V07_FichierHtmlDaffSurServeurWeb}
	[[ ! -s $V07_FichierHtmlDaffSurServeurWeb ]] && { fEchof "Fichier inexistant ou vide"; fEchoVarf "V07_FichierHtmlDaffSurServeurWeb"; return 1; }
  fEchof
	return 0
}

###############################################################
#
# TC_08_ArchivageFichierEnCours : Archivage du fichier en cours de traitement en Archive et dans DerniereVersion
#
###############################################################
function TC_08_ArchivageFichierEnCours
{
  TC_EchoFunction
  #
  # /!\ Je copie bien le fichier initial V04_FichierKBART et pas le fichier trié VO6_FichierKBART_Trie .
  # Car le tri déplace la ligne d'entête du fichier n'importe où ( à la lettre p ) dans le fichier trié.
  # ligne d'entête : publication_title	print_identifier	online_identifier	date_first_issue_online	num_first_vol_online	...
  #
	fEchof "Copie de"
	fEchoVarf "V04_FichierKBART"
	fEchof "sous"
	fEchoVarf "VO8_FichierKBART_copieEnArchive"
	cp ${V04_FichierKBART} ${VO8_FichierKBART_copieEnArchive}
	[[ ! -s $VO8_FichierKBART_copieEnArchive ]] && { fEchof "Fichier inexistant ou vide"; fEchoVarf "VO8_FichierKBART_copieEnArchive"; return 1; }
	fEchof
	fEchof "Maj de la date de téléchargement du fichier dans le fichier $V05_FichierHistoriqueDesTraitements"
	echo "${DateMajEditeur}:${NomFic}_${V05_DateDernierTraitement}_${DateMajEditeur}.html"  >> $V05_FichierHistoriqueDesTraitements
  fEchof
	# copie du fichier dans le répertoire de référence ( derniere version du KBART ) et renommage du fichier aux standards BACON
	fEchof "copie de V04_FichierKBART"
	fEchof "      ${V04_FichierKBART}"
	fEchof "   sous V08_ConservationDerniereVersion_FichierKBART"
	fEchof "      ${V08_ConservationDerniereVersion_FichierKBART}"
	cp --update ${V04_FichierKBART} ${V08_ConservationDerniereVersion_FichierKBART}
	fEchof
	return 0
}

###############################################################
#
# TC_10_HtmlOutputLine : Écriture d'une ligne relative au traitement du fichier en cours dans le fichier HTML récapitulatif
#
###############################################################
function TC_10_HtmlOutputLine
{
	TC_EchoFunction

	local PositionDansFichierHTML=$1
	local numeroLigne=$2
  local PositionInHtml=$( printf "%d-%06.06d\n" ${PositionDansFichierHTML} ${numeroLigne} )
	###############################################################
	fEcho
	fEcho "Écriture dans le fichier V10_Number_htmlTRTD qui sera intégré en TC_12_SortieHtml_Editeur_Recapitulatif_desMAJ "
	fEcho " le fichier final HTML ( FichierHtml_Editeur_Recapitulatif_desMAJ = $EDITEUR.html ) ."
	fEchoVar "V10_Number_htmlTRTD"
	fEcho
	printf "%s\t%s\n" "${PositionInHtml}-0" " <tr bgcolor=\"#${Colors[$PositionDansFichierHTML]}\">" >> $V10_Number_htmlTRTD
  #
  # ahe : ici pb avec ExtFicInitial que j'ai perdu !!! Je le remplace par Extension mais c'est très surement incorrect !!!
  # ==> à rechercher dans l'ancien code de SRY
  printf "%s\t%s\n" "${PositionInHtml}-1" "  <td>${NomFic1}_${DateMajEditeur}${NomFic2}.${Extension}</td>" >> $V10_Number_htmlTRTD
  printf "%s\t%s\n" "${PositionInHtml}-2" "  <td>$V05_DateDernierTraitement</td>" >> $V10_Number_htmlTRTD
  printf "%s\t%s\n" "${PositionInHtml}-3" "  <td><a href=\"${URL_DernierDaff}\">${URL_DernierDaff}</a></td>" >> $V10_Number_htmlTRTD
  printf "%s\t%s\n" "${PositionInHtml}-4" " </tr>" >> $V10_Number_htmlTRTD
}


###############################################################
#
# TC_11_GestionFichiersArchive : Gestion des fichiers ARCHIVE : nettoyage de 6 mois
#
###############################################################
function TC_11_GestionFichiersArchive
{
  TC_EchoFunction
  ###############################################################
	# GESTION DES FICHIERS ARCHIVE
	#
	# Suppression des fichiers archives si plus de plus de 6 mois (182 jours).
	local i="$( ls ${RepArchive}/${NomFic}/*.tsv | wc -l )"
	fEchof "Dossier : ${RepArchive}/${NomFic}"
	if [[ $i -gt 5 ]]
	 then
	   fEchof "Plus de 5 fichiers"
		 find $RepArchive"/"$NomFic -name "*\.tsv" -mtime +182 -exec echo "Suppression du fichier Archive : "{} \;
		 find $RepArchive"/"$NomFic -name "*\.tsv" -mtime +182 -exec rm {} \;
	fi
	#
	# Suppression des fichiers archives si plus de 10 fichiers dans le répertoire
	if [[ $i -gt 10 ]]
	 then
	  fEchof "Plus de 10 fichiers"
		###############################################################
		# [LOG] Ecriture dans le fichier de LOG
		fEchof "Suppression du fichier : $( ls -t $RepArchive/$NomFic/*.tsv |  tail -n1 )"
		# suppression du fichier
		rm $( ls -t $RepArchive/$NomFic/*.tsv |  tail -n1 )
	fi
}

###############################################################
#
# TC_12_SortieHtml_Editeur_Recapitulatif_desMAJ : Écriture dans le fichier résultat HTML
#
# Chaque ligne correspondant à un fichier traité est préfixé
# par un numéro d'ordre suivi d'une tabulation puis le reste
# de la ligne HTML qui sera copiée dans le fichier HTML final).
#
###############################################################
#
function TC_12_SortieHtml_Editeur_Recapitulatif_desMAJ
{
	TC_EchoFunction
	# Création du fichier vide
	> $V07_RepServeurWeb"/"$FichierHtml_Editeur_Recapitulatif_desMAJ
	# Écriture de l'entête, ouverture des balises
	#
	TC_HtmlOutput "<html>"
	TC_HtmlOutput "<head>"
	TC_HtmlOutput "<title>Mise à Jour ${1}</title>"
	TC_HtmlOutput "</head>"
	TC_HtmlOutput "<body>"
  TC_HtmlOutput '<table border="1" cellspacing="0" cellpadding="3">'
  TC_HtmlOutput ' <tr bgcolor="#cccccc"><th>filename</th><th>date</th><th>url_daff</th></tr>'

	# remplissage et tri du fichier HTML résultat du traitement des fichiers KBART
	#
	# tri du ficher de travail sur le numéro de ligne (1er champ avant le séparateur tabulation )
	sort -n $V10_Number_htmlTRTD -o $V10_Number_htmlTRTD_sorted
  # le 1er champ (numéro) n'est pas inséré dans le fichier final, seul le reste de la ligne est inséré
	cut -f2- $V10_Number_htmlTRTD_sorted >> $V07_RepServeurWeb"/"$FichierHtml_Editeur_Recapitulatif_desMAJ

	# Écriture de la fin du fichier - fermeture des balises
	#
	TC_HtmlOutput "</table>"
	TC_HtmlOutput "</body>"
	TC_HtmlOutput "</html>"

	fEchof "Fichier html résultant : ${V07_RepServeurWeb}/${FichierHtml_Editeur_Recapitulatif_desMAJ}"
	ln -s $V07_RepServeurWeb"/"$FichierHtml_Editeur_Recapitulatif_desMAJ $RUNDIR/10_$FichierHtml_Editeur_Recapitulatif_desMAJ
}

function TC_13_ErreurTraitement
{
	TC_EchoFunction

	###############################################################
	# Traitement commun pour toutes les sources
	###############################################################

	# Initialisation du paragraphe des erreurs dans le fichier de log et de rapport par mail
	j=0
	fLogMail ""
	fLogMail "------------------------------------------------------------"

	# Test sur le nombre de fichier dans le répertoire référence de la source et sur le nombre de fichiers traités
	# S'il existe une différence, on l'indique dans les logs et le rapport par mail.
	i="$(ls $RepDerniereVersion | wc -l)"
	if [[ $i -ne $nb_fic_traite ]]
	 then
		let j++
		fLogMail ""
		if [[ $j -eq 1 ]]
		 then
		  fLogMail "ATTENTION : des erreurs ont été détectées"
		fi
		fLogMail ""
		fLogMail "  ERREUR : le nombre de fichier dans le répertoire de référence "$RepDerniereVersion" ("$i") ne correspond pas au nombre de fichiers traités ("$nb_fic_traite")"
	fi

	# Test sur le nombre de répertoire dans le répertoire Archive de la source et sur le nombre de fichiers traités
	# S'il existe une différence, on l'indique dans les logs et le rapport par mail.
	i="$(ls $RepArchive | wc -l)"
	let i--
	if [[ $i -ne $nb_fic_traite ]]
	 then
		let j++
		fLogMail ""
		if [[ $j -eq 1 ]]
		  then
			  fLogMail "ATTENTION : des erreurs ont été détectées"
		fi
		fLogMail ""
		fLogMail "  ERREUR  : le nombre de fichier dans le répertoire archive "$RepArchive" ("$i") ne correspond pas au nombre de fichiers traités ("$nb_fic_traite")"
	fi

	# Si aucune erreur a été détectée, on l'indique dans les logs et le rapport par mail
	if [[ $j -eq 0 ]]
	 then
		fLogMail "Aucune erreur majeure n'a été détectée"
	fi
	fLogMail ""
	fLogMail "------------------------------------------------------------"
}

###############################################################
# TC_14_VerificationGeneraleDesErreurs : Traitement global des fichiers d'erreur
###############################################################
function TC_14_VerificationGeneraleDesErreurs
{
	TC_EchoFunction

}

###############################################################
#
# TC_15_EnvoiMailRecapitulatif : Envoi du mail résultat
#
###############################################################
function TC_15_EnvoiMailRecapitulatif
{
  TC_EchoFunction
  local ListeMail=$Administrateurs","$Fonctionnels
  fLogMail ""
  fLogMail "########### Fin du traitement le " $(date +'%d-%m-%Y a %H:%M:%S') "###########"
  fEchoVar "LANG"
  fEcho "cat $FicMail $FicMailWarning $StdErrFile \\"
  fEcho "  | sed -e \"s/\x0D/\x0A/g\" \\"
  fEcho "  | mail -s \"$ObjetDuMessage\" \"$ListeMail\""
  cat $FicMail $FicMailWarning $StdErrFile | sed -e "s/\x0D/\x0A/g" | mail -s "$ObjetDuMessage" "$ListeMail"
}

###############################################################
#
# TC_16_GestionRUNDIR : Gestion des dossiers de travail ( RUNDIR ) : nettoyage tous les 3 jours
#
###############################################################
function TC_16_GestionRUNDIR
{
  TC_EchoFunction
  find ${BASERUNDIR_SCRIPT_EDITEUR} -type d -mtime +3 -exec echo "Suppression du dossier d'exécution : "{} \;
	find ${BASERUNDIR_SCRIPT_EDITEUR} -type d -mtime +3 -exec rm -rf {} \;
}
