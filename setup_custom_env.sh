#!/usr/bin/env bash
set -e -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# CONFIG_ROOT should be set after running `source /edx/app/edxapp/edxapp_env`
CONFIG_ROOT=${CONFIG_ROOT:-"/edx/app/edxapp"}
ADDED_REQUIREMENT_PREFIX="ADDED_REQ"
REPO_MOUNT_DIR="/edx/app/edxapp/venvs/edxapp/src"

function echohighlight() {
  echo -e "\033[1;92m$@\e[0m"
}

shopt -s nullglob
for filepath in $SCRIPT_DIR/configpatch/*.json; do
  python $SCRIPT_DIR/updatejson.py $filepath
done

# Loop through extra pip requirements specified by env variables
env | awk -F = '$1 ~ /^'$ADDED_REQUIREMENT_PREFIX'_[a-zA-Z_]*$/ { print $1 }' |
while read var; do
  echohighlight "Installing local package: ${!var}"
  pip install -e "$REPO_MOUNT_DIR/${!var}" --ignore-installed --no-deps
done
