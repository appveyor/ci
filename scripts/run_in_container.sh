#!/bin/bash -eu
readonly SCRIPT_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
declare DIR_NAME=""

function check_env_vars(){ 
    local AZURE_VARS="azure_client_id azure_client_secret azure_location azure_resource_group_name azure_storage_account azure_subscription_id azure_tenant_id azure_object_id windows_appveyor_password DESCR"

    for v in GITHUB_API_TOKEN TEMPLATE ${AZURE_VARS}; do
        echo "$v"
        # echo "\$$v $(eval echo \$$v)"
        [ -z ${!v+x} ] && { echo "Error: Please define $v variable."; return 10; }
    done
}

function check_dependencies() {
    type curl unzip tar sort uniq head ||
        { echo "One of dependencies missed." 1>&2; return 10; }
}

function install_packer() {
    local VERSION=$1
    local ZIPNAME=packer_${VERSION}_linux_amd64.zip
    curl -fsSL -O https://releases.hashicorp.com/packer/${VERSION}/${ZIPNAME} &&
    unzip -q -o ${ZIPNAME} -d "$SCRIPT_DIR" ||
        { echo "[ERROR] Cannot download and unzip packer." 1>&2; return 10; }
    packer --version
    # cleanup
    [ -f "${ZIPNAME}" ] && rm -f "${ZIPNAME}" || true
}

function download_build_images() {
    local -r OWNER=appveyor
    local -r REPO=build-images

    local VERSION=$1
    local ZIPNAME=${VERSION}.tar.gz
    local AUTH="Authorization: token $GITHUB_API_TOKEN"

    # Validate token.
    curl -o /dev/null -sH "$AUTH" "https://api.github.com/repos/$OWNER/$REPO" || { echo "Error: Invalid repo, token or network issue";  exit 1; }

    curl -vLJ -H 'Accept: application/octet-stream' -H "$AUTH" "https://github.com/${OWNER}/${REPO}/archive/${ZIPNAME}" -o "$ZIPNAME" &&
    tar -zxf "$ZIPNAME" ||
        { echo "[ERROR] Cannot download and untar $REPO." 1>&2; return 10; }

    DIR_NAME=$(tar -ztf ${TAR_FILE} |cut -d'/' -f1|sort|uniq|head -n1)
    cd -- "${DIR_NAME}" ||
        { echo "[ERROR] Cannot change directory to ${DIR_NAME}." 1>&2; return 20; }
    cd -
}

function run_packer() {
    cd -- "${DIR_NAME}" ||
        { echo "[ERROR] Cannot change directory to ${DIR_NAME}." 1>&2; return 20; }

    if [ ! -f "$TEMPLATE.json" ]; then
        echo "[ERROR] There is no '$TEMPLATE.json' template. Aborting build."
        exit 10
    fi

    DATEMARK=$(date +%Y%m%d%H%M%S)
    DESCR="build N ${APPVEYOR_BUILD_NUMBER}, ${APPVEYOR_REPO_COMMIT:0:7}, ${APPVEYOR_REPO_COMMIT_MESSAGE}"

    PACKER_LOG_PATH=./packer-${DATEMARK}.log PACKER_LOG=1 "$SCRIPT_DIR/packer" build --only= \
        -var "azure_client_id=${azure_client_id}" \
        -var "azure_client_secret=${azure_client_secret}" \
        -var "azure_location=${azure_location}" \
        -var "azure_resource_group_name=${azure_resource_group_name}" \
        -var "azure_storage_account=${azure_storage_account}" \
        -var "azure_subscription_id=${azure_subscription_id}" \
        -var "azure_tenant_id=${azure_tenant_id}" \
        -var "azure_object_id=${azure_object_id}" \
        -var "windows_appveyor_password=${windows_appveyor_password}" \
        -var "image_description=${DESCR}" \
        "$TEMPLATE.json"
}

# main
check_env_vars
check_dependencies
install_packer 1.3.3
download_build_images 0.1
run_packer
