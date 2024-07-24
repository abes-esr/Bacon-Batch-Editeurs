#!/bin/bash

###############################################################
#
# Chargement du fichier de paramétrage
# Initialisation des variables et des fichiers
#
###############################################################
#[[ $# -ne 1 ]] && { CMajE_Usage "$#"; exit 1;}

EDITEUR="Autre"
RACINE=/home/devel/MajEditeurs_ahe

SCRIPT=$( basename $BASH_SOURCE );SCRIPT=${SCRIPT%.sh}
###############################################################
# Chargement du fichier de paramétrage
#
. $RACINE/bin/Definition_Env.sh

for dir in $( ls -1d "$RepArchive/"* )
 do
  #fEchoVar "dir"
  LastCharacter=${dir: -1:1}
  #printf "LastCharacter in decimal=%d\n" "'$LastCharacter"
  #fEchoVar "LastCharacter"
  printf -v EndChar "%d" "'$LastCharacter"
  #fEchoVar "EndChar"
  [[ $EndChar -ne 13 ]] && continue
  echo "Go on"
  #ls -1 "$dir/"* | sed -e "s/\r//g"| hexdump -C

  for file in $( ls -1 "$dir/"* )
   do
    fileOK=${file//$'\x0D'}
    echo
    echo "file=$file="
    echo
    echo "fileOK=$fileOK="
    echo
    BASENAME=$( basename $fileOK )
    [[ $BASENAME == "Date.txt" ]] && { rm -f "$file" ; continue; }
    mv "$file" "$fileOK"
   done
  rmdir "$dir"
 done
