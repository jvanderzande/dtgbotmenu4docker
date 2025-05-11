# dtgbotmenu4docker

DTGBOTMENU Telegram Bot for Domoticz on Docker

## Installation steps

- Use the below compose definition and update the settings for:
  - domoticz url
  - TelegramBotToken:
  - persistent directories

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
    healthcheck:  # restart container when dtgbotmenu is hanging in the longpoll
      test: if [[ $(($(date +%s) - $(date -r "/tmp/dtgloop.txt" +%s))) -gt 40 ]]; then echo 0; pkill -f dtgbot__main.lua; exit 1; else echo "Ok"; fi
      interval: 10s
      start_period: 30s
      timeout: 2s
      retries: 0
```

After your container is created and started, check the docker log for errors.
When it is running you can:

- open the dtgbotmenu URL <http://host-ip:8099>.
- After this is correct it will return to the Main page showing the log.
- Now try sending an initial message ***menu*** or ***/start*** to your Telegram BOT.
- You will receive a message back from DTGBOT telling you that your ***chatid*** doesn't have access:  
    **⚡️Id *123456789* has no access⚡️**
- DTGBOT will add your ChatId as you will see in the Log:

  ``` txt
  2025-05-04 19:33:10 :  - No bot messages, next longpoll..
  2025-05-04 19:33:13 !!! Telegram ChatID ***123456789*** added to ChatIDWhiteList. Open Configuration Menu to unblock the account.
  ```
- Open the Configuration menu and click the checkbox infront of the ChatID ***123456789*** to enable DTGBOT.
- You can also set the Room you like to show in DTGMENU for this user.


Docker image: https://hub.docker.com/r/jvdzande/dtgbotmenu  
Github: https://github.com/jvanderzande/dtgbotmenu4docker  
Domoticz Forum: 

In case you want to buy me a nice dram of peaty Whisky: :smile:  
[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/jvdzande)