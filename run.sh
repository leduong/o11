#!/bin/bash
while true; do
  if ! pgrep -f "/home/o11/o11" > /dev/null; then
    echo "Process not found, starting o11..."
    nohup /home/o11/o11 -p 8283 -noramfs > /var/log/o11.log 2>&1 &
    sleep 10
  else
    echo "Process is running."
  fi
  sleep 20
done

