Date="$1" # date format YYYY-mm-dd
Criterium="$2"
Editeur="AbesBacon"
BaseDir=/home/devel/MajEditeurs_ahe
ArchiveDir=$BaseDir/Archive/$Editeur
DerniereVersionDir=$BaseDir/DerniereVersion/$Editeur

for dir in $( ls -al $ArchiveDir/*/*_${Date}* | grep "$Criterium" | sed -e "s/[[:space:]]\+/ /g" | cut -d" " -f9 | cut -d"/" -f1 )
 do
  echo $dir
  fileDate=$(ls -1 $dir/Date.txt)
  #sed --in-place -e "/2024-09-01/d" $fileDate
 done

exit

for dir in $( ls -al $DerniereVersionDir/*/*_${Date}* | grep "$Criterium" | sed -e "s/[[:space:]]\+/ /g" | cut -d" " -f9 | cut -d"/" -f1 )
 do
  echo $dir
  fileDate=$(ls -1 $dir/Date.txt)
  #sed --in-place -e "/2024-09-01/d" $fileDate
 done
