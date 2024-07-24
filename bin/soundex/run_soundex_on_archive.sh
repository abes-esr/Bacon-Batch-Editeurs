#for filepath in $( ls ../Archive/AbesBacon/* | grep "Vie-politique-fran" )
for filepath in $( ls -d ../Archive/AbesBacon/* )
 do
   filename=$( basename $filepath )
   read p1 p2 p3 <<< ${filename//_/ }
   #echo "$p1 $p2 $p3"
   fnsize=${#filename}   
   p3size=${#p3}   
   #echo "filename size="${#filename}   
   printf "${p1}_${p2}_%-30s %-2d %-40s\n" $( ./soundex.sh  "$p3" ) $p3size "$filename"
 done
