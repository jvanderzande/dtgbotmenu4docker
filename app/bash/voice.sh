#!/bin/sh
VoiceFile="/var/tmp/voice.oga"
wget -O $VoiceFile "https://api.telegram.org/file/bot$TelegramBotToken/$2"
