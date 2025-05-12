# dtgbotmenu4docker

DTGBOTMENU Telegram Bot for Domoticz on Docker

## History

This version is a continuation of the DTGBOT project originally started by Simon Gibbon [(original DTGBOT Project)](https://github.com/steps39/dtgbot).
It started as a command-line Telegram Bot and I have added the Room Menu functionality to this original version for simple clicking action.  
The whole setup in now converted to run in a Docker container and a Web-frontend to support simple setup and configuration of the DTGBOT was added.

## Requirements

- A running Docker server to host this container.
- A Telegram BOT name and its BotToken. https://core.telegram.org/bots/tutorial
- A working Domoticz installation  https://www.domoticz.com

## Installation steps

- Use the below compose definition and update the settings for:
  - domoticz url
  - TelegramBotToken:
  - The persistent directories to use for your date and modules.
  - optionally change the port you like to use. Default is 8099.

The compose definition:

```yaml
services:
  dtgbotmenu:
    container_name: dtgbotmenu
    restart: on-failure
    image: dtgbotmenu:latest
    environment:
      - TZ=Europe/Amsterdam                                            # Timezone setting
      - DomoticzURL=http://dtgbot:domoticz@domoticz-host:8080          # your domoticz url
      - TelegramBotToken=121212121:Aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  # your bottoken
    ports:
      - 8099:8099                          # External port to use on the host. default 8099
    volumes:
      - /opt/dtgbot/data:/data             # Mapping of local folder data    to /opt/dtgbot/data
      - /opt/dtgbot/modules:/modules       # Mapping of local folder modules to /opt/dtgbot/modules
    healthcheck:  # restart container when dtgbot is hanging in the longpoll
      test: if [[ $(($(date +%s) - $(date -r "/tmp/dtgloop.txt" +%s))) -gt 40 ]]; then echo 0; pkill -f dtgbot__main.lua; exit 1; else echo "Ok"; fi
      interval: 10s
      start_period: 30s
      timeout: 2s
      retries: 0
```

After your container is created and started, check the docker log for errors.
It should look like this:

  ``` txt
########## Docker ############
2025-05-11 11:01:07 :  ####################################################################################
2025-05-11 11:01:07 :  Load DTGBOT configuration files
2025-05-11 11:01:07 :  Start DTGBOT (git release:v0.9.1)
2025-05-11 11:01:07 :  DTGBOT LogFile set to    :/data/logs/dtgbot.log
2025-05-11 11:01:07 :  Starting dtgbot_version   :1.0 202505081503
2025-05-11 11:01:07 :  dtg_main_functions_version:1.0 202505101611
2025-05-11 11:01:07 :  dtg_domoticz_version      :1.0 202505081455
2025-05-11 11:01:07 :  BotLogLevel set to  :1
2025-05-11 11:01:07 :  Persistent table loaded
2025-05-11 11:01:07 :  >> Start Initial connectivity check for Domoticz and Telegram ==
2025-05-11 11:01:07 :  +> Initial test connection to Domoticz successfull.
2025-05-11 11:01:07 :  +> Initial test connection to Telegram successfull.
2025-05-11 11:01:07 :  << All connections working, dtgbot will start.
2025-05-11 11:01:07 :  Domoticz version :2024.7  Revision:16678  BuildDate:20240713
2025-05-11 11:01:07 :  Domoticz url used:http://192.168.0.111:8080
2025-05-11 11:01:08 :  Domoticz language is set to:en
2025-05-11 11:01:08 :  #> Starting message loop with Telegram servers
2025-05-11 11:01:09 :  -> In contact with Telegram servers. Start Longpoll loop every 30 seconds.
2025-05-11 11:01:09 :  ===========================================================================
2025-05-11 11:01:09 :  Further detailed Logging can be found in /data/logs/dtgbot.log
2025-05-11 11:01:09 :  Open http://DTGBOT-Host:8099 to view log and update configuration settings.
2025-05-11 11:01:09 :  ===========================================================================
```

## Installation Configuration

When dtgbotmenu is up and running it is ready to be configured.

- Open the dtgbotmenu URL <http://host-ip:8099> which will show the log
- Now try sending an initial message ***menu*** or ***/start*** to your Telegram BOT
- You will receive a message back from DTGBOT telling you that your ***chatid*** doesn't have access:  
    **⚡️Id *123456789* has no access⚡️**
- DTGBOT will add your ChatId as you will see in the Log:

``` txt
2025-05-04 19:33:10 :  - No bot messages, next longpoll..
2025-05-04 19:33:13 !!! Telegram ChatID ***123456789*** added to ChatIDWhiteList. Open Configuration Menu to unblock the account.
```

- Open the Configuration menu and click the checkbox infront of the ChatID ***123456789*** to enable DTGBOT
- You can also set the Domoticz Rooms you like to show in DTGBOT Keyboard menus for this user or use the default settings.

## After Installation considerations

- logs available in /data/logs are:
  - config_update.log  (Any config update preformed is logged here)
  - dtgbot.log (Active dtgbotmenu log)
  - dtgbot.log.prev  (previous dtgbot.log when the cleanlog button is pressed on the WebPage)
  - dtgbot_webserver.log (Log generated by the php webserver)
  - dtgbot_webserver_errors.log (Errors Log generated by the php webserver)
- Implement Log cleanup with logrotate to prevent the logs from getting too big.
- In case of issues please share the above listed logs (after removing your personal items) with me in a zip file via email, so I can see what is happening. 

## Documentation Wiki


Docker image: https://hub.docker.com/r/jvdzande/dtgbotmenu  
Github: https://github.com/jvanderzande/dtgbotmenu4docker  
Domoticz Forum: (will be added after a new topic is opened)

In case you want to buy me a nice dram of peaty Whisky: :smile:  
[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/jvdzande)