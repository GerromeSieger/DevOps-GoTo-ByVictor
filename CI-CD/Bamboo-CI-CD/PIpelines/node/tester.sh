#!/bin/sh
set -e

echo "Installing dependencies..."
apt update && apt install -y nginx curl

echo "Clearing existing Nginx content..."
rm -rf /var/www/html/*
cp -r ./build/* /var/www/html/

echo "Starting Nginx in background..."
nginx -g 'daemon off;' &

NGINX_PID=$!

echo "Sleeping to let Nginx start..."
sleep 5

echo "Testing local server..."
RESPONSE=$(curl -s -I http://localhost)
STATUS_CODE=$(echo "$RESPONSE" | grep HTTP/1.1 | awk '{print $2}')

if [ "$STATUS_CODE" != "200" ]; then
  echo "Failed! Expected 200 response, got $STATUS_CODE"
  exit 1
else
  echo "Success! Got expected 200 response from local server"
fi

echo "Stopping Nginx..."
kill "$NGINX_PID"
wait "$NGINX_PID" 2>/dev/null || true

exit 0