#!/bin/bash
#
# Author : André Hillaire for ABES
# 2024-07-05
#
EDITEUR="Autre"
RACINE=/home/devel/MajEditeurs_ahe

SCRIPT=$( basename $BASH_SOURCE );SCRIPT=${SCRIPT%.sh}

. $RACINE/bin/BOM.sh
. $RACINE/bin/KBart_File_Header.sh

function KBFH_Run
{
  FILE=$1
  BOM_File "$FILE"
	rc=$?
	echo "rcBOM_File=$rc"
	BOM_File_EchoRC "$rc" "echo"

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

  #KBFH_DisplayHeaders

  # KBFH_FindHeaderPattern retourne le numéro du pattern found ou zéro sinon
  KBFH_FindHeaderPatternApproxAndExplain "$TC_BHS_Header"
  rc=$?
  if [[ $rc -eq 0 ]]
   then
    echo "Pattern not found for file header"
   else
	  echo "Pattern ${Versions[$rc]} found for file header"
  fi
  #[[ $rc -eq 0 ]] && KBFH_FindHeaderPatternAndExplain "$FirstLine"
}

KBFH_Run "/home/devel/MajEditeurs_ahe/rundir/CheckMajEditeurs_ahe/Autre/2024-07-21_23:00:01/03/harvest.aps.org_holdings_kbart.tsv"
