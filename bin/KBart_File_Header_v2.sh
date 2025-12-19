#!/bin/bash
#
# Author : André Hillaire for ABES
# 2024-07-05
#

[[ $# -ne 1 ]] && { echo "fichier des headers manquant"; exit 1;}

function KBFH_Fill
{
	local line="$1"
	# VFH = VersionFormatHeader
  declare -a VFH=( $line )
  local Version=${VFH[0]}
  declare -a aFormat=( ${VFH[1]//,/ } )
  local caFormat=${#aFormat[*]}
  for (( ca=0;ca<$caFormat;ca++ ))
   do
    local SV="${aFormat[$ca]}SV"

    local size=${#Versions[*]}
		Versions[$size]="${Version}_${SV}"
		Patterns[$size]=$( printf "%s" ${VFH[2]};for (( i=3;i<${#VFH[*]};i++ )) ; do printf "${Separators[$SV]}%s" ${VFH[$i]}; done )

		size=${#Versions[*]}
		Versions[$size]="${Version}_${SV}_Quoted"
		Patterns[$size]=$( printf "\"%s\"" ${VFH[2]};for (( i=3;i<${#VFH[*]};i++ )) ; do printf "${Separators[$SV]}\"%s\"" ${VFH[$i]}; done )
   done
}

function KBFH_DisplayHeaders
{
	local fEcho=${1-echo}
	for (( i=0;i<${#Versions[*]};i++ ))
	 do
	  $fEcho "PATTERN_"${Versions[$i]}="${Patterns[$i]}"
	 done
}

function KBFH_FindHeaderPattern
{
	local Header="$1"
	let i=0
	while [[ $i -lt ${#Versions[*]} && "$Header" != "${Patterns[$i]}" ]]; do let i++ ; done
	[[ $i -eq ${#Versions[*]} ]] && return 0
	return $i
}

function KBFH_FindHeaderPatternApprox
{
	local Header="$1"
	local fEcho=${2-echo}
	local i=0
	local HeaderSize=${#Header}
	$fEcho "KBFH_FindHeaderPatternApprox : \$HeaderSize=$HeaderSize"
	local DeltaHeader=""
	local exact=0
	$fEcho
	while [[ $i -lt ${#Versions[*]} ]]
	 do
	  Pattern=${Patterns[$i]}
	  DeltaHeader=${Header/$Pattern}
	  $fEcho "KBFH_FindHeaderPatternApprox : \${Versions[$i]}=${Versions[$i]}=, \${#DeltaHeader}=${#DeltaHeader}"
	  [[ ${#DeltaHeader} -eq 0 ]] && return $(( i*10 + 1 ))
	  # header greater than pattern : is pattern included in header ?
	  [[ ${#DeltaHeader} -lt $HeaderSize ]] && return $(( i*10 + 0 ))
	  let i++
	 done
	$fEcho
	$fEcho "KBFH_FindHeaderPatternApprox : \$i=$i, \${#Versions[*]}=${#Versions[*]}"
	[[ $i -eq ${#Versions[*]} ]] && return 0
	return $i
}

function KBFH_FindHeaderPatternAndExplain
{
	local Header="$1"
	local fEcho=${2-echo}
	local i=0
	while [[ $i -lt ${#Versions[*]} && "$Header" != "${Patterns[$i]}" ]]
	 do
	  $fEcho
	  $fEcho "KO test $i : ${Versions[$i]}"
	  $fEcho "Header :"
	  $fEcho "$Header"
	  $fEcho "vs ${Versions[$i]}"
	  $fEcho "${Patterns[$i]}"
	  $fEcho
	  $fEcho "hexdump -C <<<\${Header}"
	  hexdump -C <<<${Header}
	  $fEcho
	  $fEcho "hexdump -C <<<\${Patterns[$i]}"
	  hexdump -C <<<${Patterns[$i]}
	  $fEcho "---------------"
	  let i++
	 done
	[[ $i -eq ${#Versions[*]} ]] && { $fEcho "Pattern  not found" ; return 1; }
	$fEcho "Pattern : $i : ${Versions[$i]} found"
	return 0
}

function KBFH_FindHeaderPatternApproxAndExplain
{
	local Header="$1"
	local fEcho=${2-echo}
	local i=0
	local HeaderSize=${#Header}
	local DeltaHeader=""
	local exact=0
	while [[ $i -lt ${#Versions[*]} ]]
	 do
	  Pattern=${Patterns[$i]}
	  DeltaHeader=${Header/$Pattern}
	  $fEcho
	  $fEcho "test #$i : ${Versions[$i]}"
	  $fEcho "Header :"
	  $fEcho "  $Header"
	  $fEcho "vs ${Versions[$i]}"
	  $fEcho "  ${Patterns[$i]}"
	  $fEcho
	  $fEcho "DeltaHeader :"
	  $fEcho "  $DeltaHeader"
	  $fEcho
	  $fEcho "hexdump -C <<<\${Header}"
	  hexdump -C <<<${Header}
	  $fEcho
	  $fEcho "hexdump -C <<<\${Patterns[$i]}"
	  hexdump -C <<<${Patterns[$i]}
		$fEcho
	  [[ ${#DeltaHeader} -eq 0 ]] && { $fEcho "IDENTICAL";return $(( i*10 + 1 ));}
	  [[ ${#DeltaHeader} -lt $HeaderSize ]] && { $fEcho "INCLUDED";return $(( i*10 + 0 ));}
	  $fEcho "DIFFERENT"
	  $fEcho "-----------------------------------------------"
	  let i++
	 done
	[[ $i -eq ${#Versions[*]} ]] && return 0
	return $i
}

fEcho "KBart_File_Header_v2.sh : début : àéè"
fEchoVar "LANG"
FileOfHeaders="$1"

declare -A Separators # -A declare an Associative array ; -a declare an indexed array
Separators["TSV"]=$'\x09'
Separators["CSV"]=","
Separators["SCSV"]=";"

declare -a Versions
declare -a Patterns
Versions[0]="NONE"
Patterns[0]="NONE"

mapfile -t aLines < $FileOfHeaders
cLines=${#aLines[*]}
fEcho "$cLines lignes dans le fichier $FileOfHeaders"
for (( cl=0;cl<$cLines;cl++ ))
 do
  line="${aLines[$cl]}"
  [[ -z $line ]] && { fEcho "ligne vide : pas de traitement." ; continue; }
  [[ ${line:0:1} == "#" ]] && { fEcho "ligne en commentaire : pas de traitement." ; continue; }
  echo "$line"
  KBFH_Fill "$line"
 done
fEchoVar "LANG"
fEcho "KBart_File_Header_v2.sh : fin : àéè"
#KBFH_DisplayHeaders
