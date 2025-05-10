#!/bin/sh
VideoFile="/var/tmp/video_note.mp4"
wget -O $VideoFile "https://api.telegram.org/file/bot$TelegramBotToken/$2"
