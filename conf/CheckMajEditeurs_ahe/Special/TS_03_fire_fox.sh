#!/usr/bin/bash
URL="$1"
V03_FichierKBART="$2"

#ls -al /home/devel/Téléchargements/
rm -f /home/devel/Téléchargements/*
#ls -al /home/devel/Téléchargements/
echo
echo "URL=\"$URL\""
firefox --headless "$URL" &
echo "-------sleep 15s ---------"
#ffPID=$!
#echo "ffPID=$ffPID"
#ps -ef | grep firefox
sleep 15s
#ps -ef | grep firefox
pkill firefox
ls -al /home/devel/Téléchargements/
mv /home/devel/Téléchargements/* $V03_FichierKBART
date
