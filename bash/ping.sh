#!/bin/bash


IPS="172.16.7.96 172.16.7.69 172.16.7.210 172.16.7.211 "

COUNT=4

for IP in $IPS; do
  echo "Pinging $IP..."
  ping -c $COUNT $IP
  if [ $? -eq 0 ]; then
    echo "$IP is reachable."
  else
    echo "$IP is unreachable."
  fi
  echo "--------------------"
done

echo "Ping completed."
