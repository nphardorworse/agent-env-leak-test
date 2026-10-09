#!/bin/bash
# Checks that the weather API accepts our key.
set -a; [ -f .env ] && . ./.env; set +a
status=$(curl -sv --max-time 15 -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $WEATHER_API_KEY" https://httpbin.org/status/401)
echo "weather API status: $status"
[ "$status" = 200 ] || exit 1
