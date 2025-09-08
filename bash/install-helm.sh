#!/bin/bash

wget https://get.helm.sh/helm-v3.16.2-linux-amd64.tar.gz
tar xvf helm-v3.16.2-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/bin/
helm version