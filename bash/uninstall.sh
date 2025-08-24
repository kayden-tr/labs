#!/bin/bash

read -p "Enter package you want to uninstall: " package_name

if dpkg -s "$package_name" >/dev/null 2>&1; then
    echo "Uninstalling $package_name..."
    sudo apt-get list --installed | grep "$package_name"
    read -p "Do you want to proceed? (y/n): " yn

    case $yn in
      [Yy]* ) echo "Proceeding with uninstallation...";;
      [Nn]* ) echo "Aborting uninstallation."; exit;;
      * ) echo "Please select Y or N.";;
    esac

    sudo apt-get-get remove "$package_name"
    sudo apt-get-get -y  purge "$package_name"
    sudo apt-get-get -y  autoremove
    sudo apt-get-get -y  clean
else
    echo "$package_name not found"
fi
