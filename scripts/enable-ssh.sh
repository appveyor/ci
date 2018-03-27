#!/bin/bash -e

LOCK_FILE=$HOME/build.lock

# open 22 port for management network interface
sudo ufw allow OpenSSH

# get external IP address via https://www.appveyor.com/tools/my-ip.aspx
EXT_IP=$(curl -sf https://www.appveyor.com/tools/my-ip.aspx)

# get ip address of management network interface and figure out corresponding port on NAT
INT_IP=$(hostname --ip-address)
IFS='.' read -r -a INT_IP_ARR <<< "$INT_IP"
PORT=$(( 22000 + (${INT_IP_ARR[2]} - 0) * 256 + ${INT_IP_ARR[3]} ))

# add ssh key (if set) to authorized_keys
if [[ -n $APPVEYOR_SSH_KEY ]]; then
    (
        echo "#Added by Appveyor Build Agent"
        echo $APPVEYOR_SSH_KEY
    ) >> $HOME/.ssh/authorized_keys
    chmod 600 $HOME/.ssh/authorized_keys
fi

# print out connection command
echo "connect to ${EXT_IP} port $PORT"

if [[ -n "$APPVEYOR_SSH_BLOCK" ]] && $APPVEYOR_SSH_BLOCK; then
    # create $HOME/build.lock file if we need to block build process.
    touch "${LOCK_FILE}"
    # wait until $HOME/build.lock deleted by user.
    while [ -f "${LOCK_FILE}" ]; do
        sleep 1
    done
fi
