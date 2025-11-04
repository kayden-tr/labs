#!/bin/bash

tou1ch haha.txt
if [ $? -ne 0 ]; then
    echo "Failed to create file"
else
    echo "File created successfully"
fi
echo "hello" > haha.txtmcmc