#!/bin/bash -e

USER_NAME=appveyor
LOCK_FILE="${HOME}/build.lock"
HOSTKEY=/etc/ssh/ssh_host_ecdsa_key.pub

YELLOW='\033[0;33m'
NC='\033[0m'

if [[ -z "${APPVEYOR_SSH_KEY}" ]]; then
    echo "APPVEYOR_SSH_KEY variable is not defined!"
    echo "Please read https://www.appveyor.com/docs/getting-started-with-appveyor-for-linux/"
    exit 1
fi

if ! ssh-keygen -E md5 -lf /dev/stdin <<< "${APPVEYOR_SSH_KEY}"; then
    echo "APPVEYOR_SSH_KEY contain invalid key!"
    exit 2
fi

trap 'sudo ufw deny OpenSSH >/dev/null' EXIT SIGHUP SIGINT SIGQUIT SIGTERM ERR

# open 22 port for management network interface
sudo ufw allow OpenSSH > /dev/null 2>&1

# get external IP address via https://www.appveyor.com/tools/my-ip.aspx
EXT_IP=$(curl -sf https://www.appveyor.com/tools/my-ip.aspx)

# get ip address of management network interface and figure out corresponding port on NAT
INT_IP=$(hostname --ip-address)
IFS='.' read -r -a INT_IP_ARR <<< "$INT_IP"
PORT=$(( 22000 + (${INT_IP_ARR[2]} - 0) * 256 + ${INT_IP_ARR[3]} ))

# add ssh key (if set) to authorized_keys
(
    echo "#Added by Appveyor Build Agent"
    echo "${APPVEYOR_SSH_KEY}"
) >> "${HOME}/.ssh/authorized_keys"
chmod 600 "${HOME}/.ssh/authorized_keys"
USERKEY_MD5=$(ssh-keygen -E md5 -lf /dev/stdin <<<"${APPVEYOR_SSH_KEY}" | cut -f 2 -d" ")
USERKEY_SHA256=$(ssh-keygen -lf /dev/stdin <<< "${APPVEYOR_SSH_KEY}" | cut -f 2 -d" ")

# print out connection command
echo "Connect to ${EXT_IP} port $PORT with ${USER_NAME} user:"
echo -e "${YELLOW}    ssh ${USER_NAME}@${EXT_IP} -p ${PORT}${NC}"
if [[ -n "${USERKEY_MD5}" ]]; then
    echo ""
    echo "RSA key fingerprint:"
    echo "    ${USERKEY_SHA256}"
    echo "    ${USERKEY_MD5}"
fi
if [[ -f "${HOSTKEY}" ]]; then
    echo ""
    echo "Server host key fingerprint:"
    HOSTKEY_SHA256=$(ssh-keygen -lf ${HOSTKEY} | cut -f 2 -d" ")
    echo "    ${HOSTKEY_SHA256}"
fi

if [[ -n "${APPVEYOR_SSH_BLOCK}" ]] && ${APPVEYOR_SSH_BLOCK}; then
    # create $HOME/build.lock file if we need to block build process.
    touch "${LOCK_FILE}"
    # wait until $HOME/build.lock deleted by user.
    while [ -f "${LOCK_FILE}" ]; do
        sleep 1
    done
    echo "SSH session has been finished."
fi
