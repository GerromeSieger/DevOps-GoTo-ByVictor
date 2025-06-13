#!/bin/bash

echo "===== Runner Status ====="
docker-compose ps

echo -e "\n===== Runner Logs (last 5 lines each) ====="
for runner in runner-1 runner-2 runner-3; do
  echo -e "\n--- $runner ---"
  docker-compose logs --tail=5 $runner
done