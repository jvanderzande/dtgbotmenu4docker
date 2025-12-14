#!/bin/bash
####################################################################################
# xxxChange the rid values below to match the sensors on your devices page in Domoticz
####################################################################################
#Get Revision to be able to determine the API format to use
CheckforUpdate=`curl $DomoticzURL'/json.htm?type=command&param=checkforupdate&forced=true' 2>/dev/null`
HaveUpdate=`echo -ne "$CheckforUpdate"|grep "\"HaveUpdate\" :"`
HaveUpdate=`echo $HaveUpdate | awk -F: '{print $2, $3}' | sed 's/\"//g' | sed 's/,//'`

InstalledVersion=$DomoticzVersion
Version=$DomoticzVersion
Revision=$DomoticzRevision
Apichange=''
# add this to the API call for the new format
if [[ Revision -ge 15326 ]] ; then
   Apichange='command&param=get'
   # echo "use new API"
fi
##############################################################################
ResultString="-CPU temperature: "

ResultString+=`curl $DomoticzURL'/json.htm?type='$Apichange'devices&rid=40' 2>/dev/null | jq -r .result[]."Temp"`
ResultString+="°C\n"
#~ ResultString+="C\n"

ResultString+="-CPU Usage: "
ResultString+=`curl $DomoticzURL'/json.htm?type='$Apichange'devices&rid=56' 2>/dev/null | jq -r .result[]."Data"`
ResultString+="\n"

ResultString+="-Memory Usage: "
ResultString+=`curl $DomoticzURL'/json.htm?type='$Apichange'devices&rid=53' 2>/dev/null | jq -r .result[]."Data"`
ResultString+="\n"

ResultString+="-SD usage: "
ResultString+=`curl $DomoticzURL'/json.htm?type='$Apichange'devices&rid=55' 2>/dev/null | jq -r .result[]."Data"`
ResultString+="\n"

if [[ "$HaveUpdate" -eq "true" ]] ; then
   ResultString+="-Domoticz update available! current version $Version build $Revision\n"
fi
#############################################################################
echo -ne "$ResultString"
exit
