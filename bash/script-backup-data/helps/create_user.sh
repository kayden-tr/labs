#!/bin/bash

# run with sudo

USERNAME=$1
USERHOME=${2:-/home/$USERNAME}
UID=${UID:-1000}
GID=${GID:-1000}

addgroup --gid $GID $USERNAME

adduser \
  --home $USERHOME --shell /bin/bash \
  --disabled-password --uid $UID \
  --gid $GID $USERNAME && passwd -d $USERNAME
