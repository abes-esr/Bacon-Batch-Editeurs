#!/bin/bash

	# on ne garde que la date la plus récente de chaque bouquet
V03_FichiersATraiter_Bouquet_TouteslesDates="/home/devel/MajEditeurs_ahe/rundir/Traite_OwnCloud_ahe/AbesBacon/2024-07-14_21:35:01/03_FichiersATraiter_Bouquet_TouteslesDates"

	FicOld=""
	i=0
	> titi.txt
	while read line
	do
		echo "read line=$line"
		Temp=$( cut -f2 <<< "$line" )
		echo "cut -f2 : Temp=$Temp"
		[[ $i -eq 0 ]] && FicOld=$Temp
		[[ "$Temp" != "$FicOld" ]] && { echo "$LineOld" >> titi.txt ; }
		FicOld=$Temp
		LineOld="$line"
		let i++
	done < $V03_FichiersATraiter_Bouquet_TouteslesDates
  #echo "--> DERNIERE DATE : $LineOld"
  [[ -n $LineOld ]] && { echo "$LineOld" >> titi.txt ; }


