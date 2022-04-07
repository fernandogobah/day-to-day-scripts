#!/bin/bash
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#
# Script youtube downloader musics
# with aplication gain
#
### BEGIN INIT INFO
#Baixar a playlist em mp3
cd /media/STR/MUSICS
youtube-dl -o "%(title)s.%(ext)s" -x --audio-format mp3 --audio-quality 192K -a /opt/doclimus/playlist.musics --download-archive /opt/doclimus/downloaded_musics.db
mp3gain -crakf *.mp3

#Baixar a playlist em 720p (os que estão disponivéis)
cd /media/STR/CLIPS
youtube-dl -ci -f 22 -o '%(title)s.%(ext)s' --embed-thumbnail --add-metadata --metadata-from-title "%(artist)s - %(title)s" --write-auto-sub --sub-format "srt" --sub-lang "pt,en" -a /opt/doclimus/playlist.720 --download-archive /opt/doclimus/downloaded_720.db
python /opt/doclimus/kodimvnfo.py

#Baixar a playlist em 1080p (os que estão disponivéis em tal formato)
cd /media/STR/CLIPS
youtube-dl -ci 137+140 -o '%(title)s.%(ext)s' --write-thumbnail --add-metadata --write-auto-sub --sub-lang "pt,en" -a /opt/doclimus/playlist.1080 --download-archive /opt/doclimus/downloaded_1080.db
python /opt/doclimus/kodimvnfo.py

#Update YouTube-dl
youtube-dl -U
