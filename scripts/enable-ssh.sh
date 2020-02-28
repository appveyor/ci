#!/bin/bash -e

USER_NAME=appveyor
LOCK_FILE="${HOME}/build.lock"
HOSTKEY=/etc/ssh/ssh_host_ecdsa_key.pub
PLATFORM=$(uname -s)
YELLOW='\033[0;33m'
NC='\033[0m'

if [[ -z "${APPVEYOR_SSH_KEY}" ]]; then
    echo "APPVEYOR_SSH_KEY variable is not defined!"
    echo "Please read https://www.appveyor.com/docs/how-to/ssh-to-build-worker/"
    exit 1
fi

if ! ssh-keygen -E md5 -lf /dev/stdin <<< "${APPVEYOR_SSH_KEY}" >/dev/null; then
    echo "APPVEYOR_SSH_KEY contain invalid key!"
    exit 2
fi

if [ "$PLATFORM" = "Linux" ] && command -v ufw >/dev/null; then
    trap 'sudo ufw deny OpenSSH >/dev/null' EXIT SIGHUP SIGINT SIGQUIT SIGTERM ERR

    # open 22 port for management network interface
    sudo ufw allow OpenSSH > /dev/null 2>&1
fi

# get external IP address via https://www.appveyor.com/tools/my-ip.aspx
EXT_IP=$(curl -sf https://www.appveyor.com/tools/my-ip.aspx)

# get ip address of management network interface and figure out corresponding port on NAT
case "$PLATFORM" in
    "Linux")
        INT_IP=$(ip -o -4 addr show up primary scope global | ( read -r num dev fam addr rest; echo ${addr%/*}; ))
        IFS='.' read -r -a INT_IP_ARR <<< "$INT_IP"
        PORT=$(( 22000 + (${INT_IP_ARR[2]} - 0) * 256 + ${INT_IP_ARR[3]} ))
        ;;
    "Darwin")
        INT_IP=$(ipconfig getifaddr en0)
        IFS='.' read -r -a INT_IP_ARR <<< "$INT_IP"
        PORT=$(( 22000 + INT_IP_ARR[3] ))
        ;;
esac

# add ssh key (if set) to authorized_keys
mkdir -p ${HOME}/.ssh
(
    echo "#Added by Appveyor Build Agent"
    echo "${APPVEYOR_SSH_KEY}"
) >> "${HOME}/.ssh/authorized_keys"
chmod 600 "${HOME}/.ssh/authorized_keys"
USERKEY_MD5=$(ssh-keygen -E md5 -lf /dev/stdin <<<"${APPVEYOR_SSH_KEY}" | cut -f 2 -d" ")
USERKEY_SHA256=$(ssh-keygen -lf /dev/stdin <<< "${APPVEYOR_SSH_KEY}" | cut -f 2 -d" ")

# modify MOTD
if [ -d /etc/update-motd.d ]; then
  (
    echo '#!/bin/sh'
    echo "echo '"
    echo "Project:       ${APPVEYOR_PROJECT_NAME}"
    echo "Build Version: ${APPVEYOR_BUILD_VERSION}"
    echo "URL:           ${APPVEYOR_URL}/project/${APPVEYOR_ACCOUNT_NAME}/${APPVEYOR_PROJECT_SLUG}/build/job/${APPVEYOR_JOB_ID}"
    echo "'"
  ) | sudo tee /etc/update-motd.d/01-appveyor >/dev/null
  sudo chmod +x /etc/update-motd.d/01-appveyor
fi 
if [ "$PLATFORM" = "Darwin" ]; then
  (
    echo "Project:       ${APPVEYOR_PROJECT_NAME}"
    echo "Build Version: ${APPVEYOR_BUILD_VERSION}"
    echo "URL:           ${APPVEYOR_URL}/project/${APPVEYOR_ACCOUNT_NAME}/${APPVEYOR_PROJECT_SLUG}/build/job/${APPVEYOR_JOB_ID}"
  ) |sudo tee /etc/motd >/dev/null
fi

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
    # create "lock" file.
    touch "${LOCK_FILE}"
    echo -e "Build paused. To resume it, open a SSH session to run '${YELLOW}rm \"${LOCK_FILE}\"${NC}' command."
    # export all APPVEYOR_* variables to .appveyorrc file so it could be available to ssh session
    export -p|grep -E '^declare -x APPVEYOR_' > "$HOME/.appveyorrc"
    # this might fail if there is multiline values
    echo "source $HOME/.appveyorrc" >> "$HOME/.profile"
    # wait until "lock" file is deleted by user.
    while [ -f "${LOCK_FILE}" ]; do
        sleep 1
    done
    echo "Build lock file has been deleted. Resuming build."
    if [ -f "$HOME/.appveyorrc" ]; then
      rm "$HOME/.appveyorrc"
    fi
fi
