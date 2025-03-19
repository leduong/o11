#!/bin/bash
while true; do
  if ! pgrep -f "/home/o11/server" > /dev/null; then
    echo "Process not found, starting server..."
    nohup /home/o11/server > /var/log/server.log 2>&1 &
    sleep 10
  else
    echo "Process is running."
  fi
  sleep 20
done

