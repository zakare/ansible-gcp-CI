#!/bin/bash
set -e

COLOR_END='\e[0m'
COLOR_RED='\e[0;31m'

## SET PATHS
MY_PATH="$(dirname "$0")"
DIR="$( (cd "$MY_PATH" && pwd))" # absolutized and normalized
ROOT_DIR=$(cd "${DIR}/../" && pwd)
EXTERNAL_ROLE_DIR="$ROOT_DIR/roles/external"
ROLES_REQUIREMENTS_FILE="$DIR/roles_requirements.yml"

# Exit msg
msg_exit() {
    printf "$COLOR_RED$@$COLOR_END"
    printf "\n"
    printf "Exiting...\n"
    exit 1
}

# Trap if ansible-galaxy failed and warn user
cleanup() {
    msg_exit "Update failed. Please don't commit or push roles till you fix the issue"
}
trap "cleanup" 1 2 9 15

# Check ansible-galaxy
[ -z "$(which ansible-galaxy)" ] && msg_exit "Ansible is not installed or not in your path."

# Check roles req file
[ ! -f "$ROLES_REQUIREMENTS_FILE" ] && msg_exit "roles_requirements '$ROLES_REQUIREMENTS_FILE' does not exist or permssion issue.\nPlease check and rerun."

# Remove
mkdir -p "$EXTERNAL_ROLE_DIR"
cd "$EXTERNAL_ROLE_DIR"
if [ "$(pwd)" = "$EXTERNAL_ROLE_DIR" ]; then
    echo "Removing current roles in '$EXTERNAL_ROLE_DIR/*'"
    rm -rf *
else
    msg_exit "Path error could not change dir to $EXTERNAL_ROLE_DIR"
fi

# Install roles
ansible-galaxy install -r "$ROLES_REQUIREMENTS_FILE" --force -p "$EXTERNAL_ROLE_DIR"

exit 0
