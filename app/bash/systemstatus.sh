#!/bin/bash
# Change the rid values below to match the sensors on your devices page in Domoticz

# Settings

#Send start of gathering msg to telegram
Result=`curl --data 'chat_id='$SendTo --data-urlencode 'text=Please wait, gathering data...' $Telegram_Url'/sendMessage' 2>/dev/null`

#Get Revision to be able to determine the API format to use
CheckforUpdate=`curl -s -i -H "Accept: application/json" "$DomoticzUrl/json.htm?type=command&param=checkforupdate&forced=true"`
InstalledVersion=`curl -s -i -H "Accept: application/json" "$DomoticzUrl/json.htm?type=command&param=getversion"`
# echo "CheckforUpdate:$CheckforUpdate\n"
HaveUpdate=`echo -ne "$CheckforUpdate"|grep "\"HaveUpdate\" :"`
Version=`echo -ne "$InstalledVersion"|grep "\"version\" :"`
Revision=`echo -ne "$InstalledVersion"|grep "\"Revision\" :"`
#~ echo "\$HaveUpdate:$HaveUpdate"
#~ echo "\$Version:$Version"
#~ echo "\$Revision:$Revision"
HaveUpdate=`echo $HaveUpdate | awk -F: '{print $2, $3}' | sed 's/\"//g' | sed 's/,//'`
Version=`echo $Version | awk -F: '{print $2, $3}' | sed 's/\"//g' | sed 's/,//'`
Revision=`echo $Revision | awk -F: '{print $2, $3}' | sed 's/\"//g' | sed 's/,//'`
#~ echo "\$HaveUpdate:$HaveUpdate"
#~ echo "\$Version:$Version"
#~ echo "\$Revision:$Revision"

Apichange=''
# add this to the API call for the new format
if [[ $Revison -ge 15326 ]] ; then
   Apichange='command&param=get'
fi

##############################################################################
ResultString="-CPU temperature: "

ResultString+=`curl $DomoticzUrl'/json.htm?type='$Apichange'devices&rid=15' 2>/dev/null | jq -r .result[]."Temp"`
#~ ResultString+="°C\n"
ResultString+="C\n"

ResultString+="-CPU Usage: "
ResultString+=`curl $DomoticzUrl'/json.htm?type='$Apichange'devices&rid=16' 2>/dev/null | jq -r .result[]."Data"`
ResultString+="\n"

ResultString+="-Memory Usage: "
ResultString+=`curl $DomoticzUrl'/json.htm?type='$Apichange'devices&rid=12' 2>/dev/null | jq -r .result[]."Data"`
ResultString+="\n"

ResultString+="-SD usage: "
ResultString+=`curl $DomoticzUrl'/json.htm?type='$Apichange'devices&rid=13' 2>/dev/null | jq -r .result[]."Data"`
ResultString+="\n"

if [[ "$HaveUpdate" -eq "true" ]] ; then
   ResultString+="-Domoticz update available! current version $Version build $Revision\n"
fi
InstalledFW=`curl $DomoticzUrl'/json.htm?type='$Apichange'hardware&filter=idx=1' 2>/dev/null | jq -r '.result[] | select(.Name=="RFXCOM")| .version'`
InstalledFW=`echo $InstalledFW | sed "s/.*\/\([0-9]*\)[^0-9]*/\1/"`
LatestFW=`curl -s "http://blog.rfxcom.com/?feed=rss2"`
LatestFW=`echo $LatestFW | sed "s/.*version \([^<]*\)<.*/\1/"`

if [[ $InstalledFW -lt $LatestFW ]] ; then
   ResultString+="-RFXtrx update available: $LatestFW"
   ResultString+=" installed: $InstalledFW"
   ResultString+="\n"
fi
#############################################################################
echo -ne "$ResultString"
exit
