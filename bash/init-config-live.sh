#!/bin/bash

# Update package list
sudo apt-get update -y && sudo apt-get upgrade -y

# Install ping (usually part of iputils-ping) and telnet
sudo apt-get install -y iputils-ping telnet 

# Set timezone to Asia/HoChiMinh
echo "-----Setting timezone to Asia/Ho_Chi_Minh...--------"
sleep 3
sudo timedatectl set-timezone Asia/Ho_Chi_Minh

# Add user to sudoers function
function add_user_to_sudoers() {
    if grep -q "^$NEW_USER" /etc/sudoers; then
        echo "User '$NEW_USER' is already in the sudoers file."
    else
        echo "Adding user '$NEW_USER' to sudoers."
        echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers > /dev/null
    fi
}

# Enter username want to create
read -p "Enter the username you want to create: " NEW_USER

# Check if the user already exists
if id "$NEW_USER" &>/dev/null; then
    echo "----------User '$NEW_USER' already exists.----------"
    echo "--------Adding user '$NEW_USER' to sudoers.---------"
    add_user_to_sudoers
    exit 0
else 
    echo "Creating user '$NEW_USER'..."
    useradd -m -s /bin/bash "$NEW_USER"
    echo "Setting password for user '$NEW_USER'."
    passwd "$NEW_USER"
fi

# Add user to sudo group
echo "Adding user '$NEW_USER' to sudo group..."
add_user_to_sudoers

# Configure sudo to allow NEW_USER to run commands without password
# export NEW_USER=<your_username>
sudo tee /etc/sudoers.d/$NEW_USER <<EOF
$NEW_USER ALL=(ALL) NOPASSWD:ALL
EOF
&& chmod 0440 /etc/sudoers.d/$NEW_USER

