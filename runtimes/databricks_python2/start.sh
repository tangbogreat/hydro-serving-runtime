#!/bin/sh

SERVICE_ID=$1

chmod +x /app/src/main.py
sync

cd /app/src
exec python /app/src/main.py