#!/bin/bash

sleep 3

# create php.ini and set timezone to the defined env var in docker_compose.yml
cd /dtgbot/web
echo "date.timezone = $TZ" > /dtgbot/web/php.ini
echo "error_reporting = E_ALL" >> php.ini
echo "log_errors = On" >> php.ini
echo "error_log = /data/logs/dtgbot_webserver_errors.log" >> php.ini
echo "display_errors = Off" >> php.ini

# Add session configuration required for security pin
echo "session.save_path = \"/tmp\"" >> php.ini
echo "session.use_cookies = 1" >> php.ini
echo "session.use_only_cookies = 1" >> php.ini
echo "session.auto_start = 0" >> php.ini

# Clean old session files older than 5 days. pin is required again when enabled.
find /tmp/sess_* -type f -mtime +5 -delete
while :
do
	rdate=`date`
	echo "$rdate start php server"
	php -c /dtgbot/web/php.ini -S 0.0.0.0:8099
	echo "Returncode: $?"
  sleep 5
done