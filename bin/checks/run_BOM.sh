#!/bin/bash


. ../BOM.sh
LogFile=/dev/null
FicMail=/dev/null
FicMailWarning=/dev/null
. ../echos.sh


BOM_String_EchoRC 8
BOM_String_EchoRC 8 "fEchof"

exit
BOM_File "$1"
rc=$?
BOM_File_EchoRC "$rc"
#echo "----------------"


exit
echo "in $0 : LANG=$LANG"

F=utf16.test
string=$'\xFF\xFE'"<bom utf-16 Little Endian>"; echo $string > $F
#hexdump -n 16 -C <<<$string
BOM_File "$F"
rc=$?
echo "in $0 : LANG=$LANG"
BOM_File_EchoRC "$rc"
echo "----------------"


F=utf-8
string=$'\xEF\xBB\xBF'"<bom utf-8>"; echo $string > $F
BOM_File "$F"
BOM_File_EchoRC "$?"

#hexdump -n 16 -C <<<$string
echo "----------------"
echo "in $0 : LANG=$LANG"
echo
