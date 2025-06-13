#!/bin/bash

apt update

# Install nginx without interactive prompts
DEBIAN_FRONTEND=noninteractive apt install -y nginx curl

# Remove existing content and copy new content
rm -rf /var/www/html/*
cp -r ./build/* /var/www/html/

# Start nginx
service nginx start

sleep 5

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)

if [ "$RESPONSE" = "200" ]; then
  echo "Success! Got expected 200 response from local server"
  exit 0
else
  echo "Failed! Expected 200 response, got $RESPONSE"
  exit 1
fi

# Stop nginx
service nginx stop