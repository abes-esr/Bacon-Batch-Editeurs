#
# Fonctions outils
#
# echo "nb de var="${#*}", "$#

[[ -z $LogFile        ]] && { echo "Variable LogFile non définie => sortie du script.";exit 1; }
[[ -z $FicMail        ]] && { echo "Variable FicMail non définie => sortie du script.";exit 1; }
[[ -z $FicMailWarning ]] && { echo "Variable FicMailWarning non définie => sortie du script.";exit 1; }

let baselevel=0
SPACES="                                           "
function fEcho
{
	let level=baselevel+${#FUNCNAME[*]}-2;let level*=2
	spaces=${SPACES:0:$level}
	echo "${spaces}${*}" | tee -a $LogFile ;
}

function fEchom1
{
	let level=baselevel+${#FUNCNAME[*]}-3;let level*=2
	spaces=${SPACES:0:$level}
	echo "${spaces}${*}" | tee -a $LogFile ;
}

function fEchof
{
	let level=baselevel+${#FUNCNAME[*]}-2;let level*=2
	spaces=${SPACES:0:$level}
	echo "${spaces}    | ${*}" | tee -a $LogFile ;
}
function fEchoVarf
{
  let level=baselevel+${#FUNCNAME[*]}-2;let level*=2
	spaces=${SPACES:0:$level}
	echo "${spaces}    | $1=${!1}=" | tee -a $LogFile ;
}

#function fEcho    { 	echo "${*}"      ; }
function fEchoVar
{
	let level=baselevel+${#FUNCNAME[*]}-2;let level*=2
	spaces=${SPACES:0:$level}
	echo "${spaces}$1=${!1}=" | tee -a $LogFile ;
}

function fEchoVars
{
	for var in ${*} ; do fEchoVar $var ; done
}

function fEchoVarsf
{
	for var in ${*} ; do fEchoVarf $var ; done
}

function fEchoVarsOnLine
{
	Line=""
	for var in ${*} ; do Line=$Line", $var=${!var}=" ; done
	fEcho ${Line/, /}
}

function fEchoShell
{
	fEchoVar "BASH_SOURCE"
	fEchoVar "BASH_COMMAND"
	echo "taille de BASH_CMDS="${#BASH_CMDS[*]}  | tee -a $LogFile
	echo "taille de FUNCNAME="${#FUNCNAME[*]}  | tee -a $LogFile
	for i in $( seq 1 ${#FUNCNAME[*]} )
	 do
	  let j=i-1
	  echo "$j : FUNCNAME[$j]="${FUNCNAME[$j]}  | tee -a $LogFile
	 done
}

#
# Fonctions outils
#
function fEchoVarWithCommentsFromScript
{
	#echo "${FUNCNAME[0]} : level ${#FUNCNAME[*]}";echo "${FUNCNAME[*]}"
	SCRIPT="$1"
	VARIABLE="$2"
	BASEDIR="${3:-$RACINE}"
	#fEchoVars "SCRIPT" "VARIABLE"
	# pour les variables chaîne de caractères
	line=$( sed -e "/^[[:space:]]*${VARIABLE}[[:space:]]*=[[:space:]]*/!d" $SCRIPT )
	# pour les variables nombre
	[[ -z $line ]] && line=$( grep "^let $VARIABLE" $SCRIPT )
	if [[ -z $line ]]
	 then
	  comment="VARIABLE INCONNUE"
	  contenu="INCONNU"
	 else
	  comment=$( echo $line | cut -d"#" -f2 );comment=${comment##[[:space:]]}
	  contenu="${!VARIABLE}"
    [[ "${VARIABLE}" != "RACINE" ]] && contenu=${contenu/$BASEDIR}
	fi

	printf "%-25.25s : %-54.54s : %s\n" "$VARIABLE" "$contenu" "$comment" | tee -a $LogFile
}

function fLog
{
	fEchof "${*}"
}

function fMail
{
  echo "${*}" >> $FicMail
}

function fMailWarning
{
  echo "${*}" >> $FicMailWarning
}

function fLogMail
{
	fLog "${*}"
	fMail "${*}"
}

function fLogMailWarning
{
	fLog "${*}"
	fMailWarning "${*}"
}

function fLogVar
{
  fEchoVar "$1"
}

function fMailVar
{
  fEchoVar "$1" | tee -a $FicMail
}

function fMailWarningVar
{
  fEchoVar "$1" | tee -a $FicMailWarning
}

function fLogMailVar
{
	#fLogVar "${*}"
	fMailVar "${*}"
}

function fLogMailWarningVar
{
	#fLogVar "${*}"
	fMailWarningVar "${*}"
}

function fLogVarf
{
  fEchoVarf "$1"
}

function fMailVarf
{
  fEchoVarf "$1" | tee -a $FicMail
}

function fMailWarningVarf
{
  fEchoVarf "$1" | tee -a $FicMailWarning
}

function fLogMailVarf
{
	#fLogVar "${*}"
	fMailVarf "${*}"
}

function fLogMailWarningVarf
{
	#fLogVar "${*}"
	fMailWarningVarf "${*}"
}
