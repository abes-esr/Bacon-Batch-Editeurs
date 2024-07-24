#!/bin/bash

function BOM_String
{
	local string="$1"
	#echo "in ${FUNCNAME[0]} : LANG=$LANG"
	#[[ $LANG != "C" ]] && { echo "${FUNCNAME[0]} : This function is only valid for LANG=C" ; return 0 ;} # see comment#1
	local LANG_ORIG="$LANG"
  LANG="C" # see comment#1
  BYTE1=${string:0:1}
  BYTE2=${string:1:1}
  BYTE23=${string:1:2}
  LANG="$LANG_ORIG"
	case $BYTE1 in
		$'\xEF') [[ $BYTE23 == $'\xBB\xBF' ]] && return   8;;
		$'\xFE') [[ $BYTE2  == $'\xFF' ]]     && return 161;;
		$'\xFF') [[ $BYTE2  == $'\xFE' ]]     && return 162;;
		*) return 1;;
	esac

	return 0
}

function BOM_String_EchoRC
{
	local fEcho=${2-echo}
  local rcBOM_String=$1
  $fEcho "rcBOM_String=$rcBOM_String"
  case $rcBOM_String in
			0) $fEcho "function BOM_String should not return this way !!!";;
			1) $fEcho "Neither BOM UTF-8 nor BOM UTF-16 found.";;
		  8) $fEcho "BOM UTF-8 found";;
		161) $fEcho "BOM UTF-16 Big    Endian found";;
		162) $fEcho "BOM UTF-16 Little Endian found";;
		  *) $fEcho "Unknown return code from BOM_String";;
  esac
  return $rcBOM_String
}

function BOM_File
{
	#[[ $LANG != "C" ]] && { echo "${FUNCNAME[0]}  : This function is only valid for LANG=C" ; return 0 ;} # see comment#1
  File="$1"
  local LANG_ORIG="$LANG"
  LANG="C" # see comment#1

  read -r FirstLine < "$File"
  #echo "Avant";hexdump -n 16 -C <<<${FirstLine}
  LANG="$LANG_ORIG"

  # suppression du caractère \x0D = \r
  local FirstLine=${FirstLine/$'\x0D'}

  BOM_String "$FirstLine"
  local rcBOM_String=$?

  return $rcBOM_String
}

function BOM_File_EchoRC
{
  local rcBOM_String=$1
  BOM_String_EchoRC "$rcBOM_String"

  #echo "/usr/local/bin/uchardet "$File
  #/usr/local/bin/uchardet "$File"
  #file $File
  return $rcBOM_String
}

function BOM_SystemEncoding
{
	echo "SystemEncoding : localectl status"
	localectl status
}

function BOM_SessionEncoding
{
	echo "SessionEncoding : locale charmap"
	locale charmap
}

#comment #1
# ATTENTION LANG=C est très important car ainsi les chaînes de caractères sont traitées octet par octet sans interprétation
#   de l'encodage UTF-8 ou autre.
#
# Si LANG=FR_fr.UTF-8 par exemple le traitement utf-8 des chaînes considère , à raison en utf-8,
#  les 3 octets de BOM_utf-8 ( $'\xEF\xBB\xBF' ) comme un seul caractère ( ${st:0:1} == $'\xEF\xBB\xBF' ) ;
#  tandis que les 2 octets de BOM utf-16 (  $'\xFE\xFF') BOM UTF-16 Big Endian et $'\xFF\xFE') BOM UTF-16 Little Endian )
#  sont considérés, à raison en utf-8, comme 2 caractères "not conforme utf-8".

# ATTENTION LANG=C is very important because the character strings are processed byte by byte without interpretation
#  of UTF-8 or other encoding.
#
# If LANG=FR_fr.UTF-8 for example the utf-8 processing of strings considers, correctly in utf-8,
#  the 3 bytes of BOM_utf-8 ( $'\xEF\xBB\xBF' ) as a single character ( $ {st:0:1} == $'\xEF\xBB\xBF' );
#  while the 2 bytes of BOM utf-16 ( $'\xFE\xFF') BOM UTF-16 Big Endian and $'\xFF\xFE') BOM UTF-16 Little Endian )
#  are considered, rightly in UTF-8, as 2 “not UTF-8 compliant” characters.

#comment#2
# Le tableau FUNCNAME contient la pile des fonctions appelées en 0 se trouve la dernière fonction appelée
#  ( celle dans laquelle on se trouve ).
#echo "\${#FUNCNAME[*]}=${#FUNCNAME[*]}"
#echo "${FUNCNAME[*]}" => BOM_File main
