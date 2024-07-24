#!/bin/bash
#
# Author : André Hillaire for ABES
# 2024-07-05
#

function KBFH_FillV1
{
	local SV="$2"

	local size=${#Versions[*]}
	Versions[$size]="${1}_${SV}"
	Patterns[$size]=$( printf "%s" ${HeadersV1[0]};for (( i=1;i<${#HeadersV1[*]};i++ )) ; do printf "${Separators[$SV]}%s" ${HeadersV1[$i]}; done )

	size=${#Versions[*]}
	Versions[$size]="${1}_${SV}_Quoted"
	Patterns[$size]=$( printf "\"%s\"" ${HeadersV1[0]};for (( i=1;i<${#HeadersV1[*]};i++ )) ; do printf "${Separators[$SV]}\"%s\"" ${HeadersV1[$i]}; done )
}

function KBFH_FillV2
{
	local SV="$2"

	local size=${#Versions[*]}
	Versions[$size]="${1}_${SV}"
	Patterns[$size]=$( printf "%s" ${HeadersV2[0]};for (( i=1;i<${#HeadersV2[*]};i++ )) ; do printf "${Separators[$SV]}%s" ${HeadersV2[$i]}; done )

	size=${#Versions[*]}
	Versions[$size]="${1}_${SV}_Quoted"
	Patterns[$size]=$( printf "\"%s\"" ${HeadersV2[0]};for (( i=1;i<${#HeadersV2[*]};i++ )) ; do printf "${Separators[$SV]}\"%s\"" ${HeadersV2[$i]}; done )
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
	local i=0
	local HeaderSize=${#Header}
	local DeltaHeader=""
	local exact=0
	while [[ $i -lt ${#Versions[*]} ]]
	 do
	  Pattern=${Patterns[$i]}
	  DeltaHeader=${Header/$Pattern}
	  [[ ${#DeltaHeader} -eq 0 ]] && return $(( i*10 + 1 ))
	  [[ ${#DeltaHeader} -lt $HeaderSize ]] && return $(( i*10 + 0 ))
	  let i++
	 done
	[[ $i -eq ${#Versions[*]} ]] && return 0
	return $i
}

function KBFH_DisplayHeaders
{
	local fEcho=${1-echo}
	for (( i=0;i<${#Versions[*]};i++ ))
	 do
	  $fEcho "PATTERN_"${Versions[$i]}="${Patterns[$i]}"
	 done
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

declare -a HeadersV1=( publication_title	print_identifier	online_identifier	date_first_issue_online	num_first_vol_online	num_first_issue_online	date_last_issue_online	num_last_vol_online	num_last_issue_online	title_url	first_author	title_id	embargo_info	coverage_depth	coverage_notes	publisher_name )
#echo "nbV1=${#HeadersV1[*]}"
# si la v2 était un ajout à la V1 j'aurais alors pu concaténer headersV1 avec les entêtes supplémentaires
#declare -a HeadersV2=( ${HeadersV1[*]} publication_type	date_monograph_published_print	date_monograph_published_online	monograph_volume	monograph_edition	first_editor	parent_publication_title_id	preceding_publication_title_id	access_type )
declare -a HeadersV2=( publication_title	print_identifier	online_identifier	date_first_issue_online	num_first_vol_online	num_first_issue_online	date_last_issue_online	num_last_vol_online	num_last_issue_online	title_url	first_author	title_id	embargo_info	coverage_depth	notes	publisher_name	publication_type	date_monograph_published_print	date_monograph_published_online	monograph_volume	monograph_edition	first_editor	parent_publication_title_id	preceding_publication_title_id	access_type )
#echo "nbV2=${#HeadersV2[*]}"

declare -A Separators # -A declare an Associative array ; -a declare an indexed array
Separators["TSV"]=$'\x09'
Separators["CSV"]=","
Separators["SCSV"]=";"

declare -a Versions
declare -a Patterns
Versions[0]="NONE"
Patterns[0]="NONE"

KBFH_FillV1 1_0 "TSV"
KBFH_FillV1 1_0 "CSV"  # , = Comma
KBFH_FillV1 1_0 "SCSV"  # ; = Semi Colon = SC , := Colon

KBFH_FillV2 2_0 "TSV"
KBFH_FillV2 2_0 "CSV"
KBFH_FillV2 2_0 "SCSV"
