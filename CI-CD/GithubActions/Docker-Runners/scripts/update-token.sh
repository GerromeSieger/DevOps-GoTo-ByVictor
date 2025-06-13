#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <runner-number> <new-token>"
  exit 1
fi

RUNNER_NUM=$1
NEW_TOKEN=$2
RUNNER_ENV_FILE="runner-envs/runner-${RUNNER_NUM}.env"

if [ ! -f "$RUNNER_ENV_FILE" ]; then
  echo "Error: Runner env file $RUNNER_ENV_FILE not found"
  exit 1
fi

sed -i "s/^RUNNER_TOKEN=.*/RUNNER_TOKEN=${NEW_TOKEN}/" "$RUNNER_ENV_FILE"
echo "Token updated in $RUNNER_ENV_FILE"

docker-compose restart "runner-${RUNNER_NUM}"
echo "Runner ${RUNNER_NUM} restarted with new token"