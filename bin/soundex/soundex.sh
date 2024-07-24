#!/bin/bash
function soundex
{
  shopt -s extglob
  z=$1
  #echo "z=$z"
  #echo
  #echo " 1 ) suppression des espaces initiaux"
  z=${z##+([[:space:]])}
  #echo "z=$z"
  #echo
  #echo " 2 ) passage en majuscule"
  z=${z^^}
  #echo "z=$z"
  #echo
  #echo " 3 ) 1ere lettre de la chaîne"
  zg=${z:0:1}
  zd=${z:1}
  #echo "zg=$zg, zd=$zd"
  #echo
  #echo " 4 ) Élimination des voyelles"
  zd=${zd//[Çç]/C}
  zd=${zd//[!BCDFGJKLMNPQRSTVXZ]/}
  #echo "zg=$zg, zd=$zd"
  #echo
  #echo " 5 ) attribution d'une valeur numérique aux lettres"
  zd=${zd//[BP]/1}
  zd=${zd//[CKQ]/2}
  zd=${zd//[DT]/3}
  zd=${zd//[L]/4}
  zd=${zd//[MN]/5}
  zd=${zd//[R]/6}
  zd=${zd//[GJ]/7}
  zd=${zd//[XZS]/8}
  zd=${zd//[FV]/9}
  #echo "zg=$zg, zd=$zd"
  #echo
  #echo "6 ) Élimination des chiffres adjacents"
  for (( i=1;i<=9;i++ ))
   do
     zd=${zd//$i$i$i$i/$i} 
     zd=${zd//$i$i$i/$i} 
     zd=${zd//$i$i/$i} 
   done
  #echo "zg=$zg, zd=$zd"
  #echo
  #echo " 7 ) troncage à 4 caractères"
  z=$zg$zd"0000000000"
  z=${z:0:10}
  #printf "%-30s %4s\n" "$1" "$z"
  echo "$z"
}

soundex "$1"

