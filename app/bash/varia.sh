#!/bin/bash
#
# Ewald 20190728
#
# this script allows to read all the user variables set in Domoticz (In Domoticz => Setup => More Options => User Variables)
# and to change them, syntax: varia VariableName Value
#
SendMsgTo=$1

if [ -z "$2" ]; then
	mapfile -t varia  < <(curl --silent 'http://$DomoticzUrl/json.htm?type=command&param=getuservariables' | jq -r -c '.result[]| {Name, Value}' | perl -ne '/Name\":\"(\S+?)\".*Value\":\"(\S+?)\"/ && print "$1 $2\n"')

	for v in "${varia[@]}"
		do
		    if [[ $v != Telegram* ]]; then		# leave out the dtgbot variables that start with Telegram
		# another option to display only the variables ending in Alert is:  [[ $v == *Alert ]]
   			curl --silent --data 'chat_id='$SendMsgTo --data-urlencode 'text='"$v" 'https://api.telegram.org/bot'$TelegramBotToken'/sendMessage'
		    fi
		done
	else
		if [[ "$#" -ne 3 ]]; then
			echo "Sorry, i need TWO arguments, VariableName and Value"
			# curl --silent --data 'chat_id='$SendMsgTo --data-urlencode 'text='"Sorry, i need TWO arguments, VariableName and Value" 'https://api.telegram.org/bot'$TelegramBotToken'/sendMessage'
			exit 0
		fi
		VAR=$2; VAL=$3
		if [[ $VAR == Telegram* ]]; then
			echo "Sorry, no changing Telegram variables"
			# curl --silent --data 'chat_id='$SendMsgTo --data-urlencode 'text='"Sorry, no changing Telegram variables" 'https://api.telegram.org/bot'$TelegramBotToken'/sendMessage'
			exit 0
		fi
		CHECK=$(curl --silent ""$DomoticzUrl"/json.htm?type=command&param=updateuservariable&vname="$2"&vtype=2&vvalue="$3 | jq -r '.status')
		if [[ $CHECK == "OK" ]]; then
			echo "Variable $VAR set to $VAL"
			# curl --silent --data 'chat_id='$SendMsgTo --data-urlencode 'text='"$VAR = $VAL" 'https://api.telegram.org/bot'$TelegramBotToken'/sendMessage'
		else
			echo "Oops, that didn't work: $CHECK"
			# curl --silent --data 'chat_id='$SendMsgTo --data-urlencode 'text='"Oops, that didn't work" 'https://api.telegram.org/bot'$TelegramBotToken'/sendMessage'
		fi
	fi
