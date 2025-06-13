#!/bin/bash

sudo apt update
sudo apt install -y nginx

sudo rm -rf /var/www/html/*
sudo cp -r ./build/* /var/www/html/

sudo systemctl start nginx

sleep 5 

RESPONSE=$(curl -s http://localhost)

STATUS_CODE=$(echo $RESPONSE | grep -i http | awk '{print $2}')
if [ $STATUS_CODE -ne 200 ]; then
  echo "Failed! Expected 200 response, got $STATUS_CODE"
  exit 1
fi
else
  echo "Success! Got expected response from local server"
  exit 0  
fi

sudo systemctl stop nginx