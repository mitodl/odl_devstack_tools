#!/usr/bin/env bash
set -e -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ADDED_REQUIREMENT_PREFIX="ADDED_REQ"
ADDED_PYPI_REQUIREMENT_PREFIX="ADDED_PYPI_REQ"
REPO_MOUNT_DIR="/edx/app/edxapp/venvs/edxapp/src"

function echohighlight() {
  echo -e "\033[1;92m$@\e[0m"
}

# Apply changes to the relevant config files based on the patch files that were mounted into the container
shopt -s nullglob
for filepath in $SCRIPT_DIR/configpatch/*.json; do
  python $SCRIPT_DIR/updateconfig.py $filepath
done

# Loop through packages that were mounted to the file system in the container and should be installed via pip 
# (These packages are specified by env variables with a certain prefix)
repopath=
env | awk -F = '$1 ~ /^'$ADDED_REQUIREMENT_PREFIX'_[a-zA-Z0-9_]*$/ { print $1 }' |
while read var; do
  echohighlight "Installing local package: ${!var}"
  repopath="$REPO_MOUNT_DIR/${!var}"
  if [[ -f "$repopath/pyproject.toml" ]] ; then
    # This package uses a pyproject.toml file. Install from a built archive if one exists with
    # the correct version. Otherwise, upgrade pip (since the old pip version in devstack can't
    # install non-setuptools packages) then install it.
    APP_NAME=$(cat $repopath/pyproject.toml | perl -nle '/^name = "(.*)"$/ && print "$1";')
    APP_VERSION=$(cat $repopath/pyproject.toml | perl -nle '/^version = "(.*)"$/ && print "$1";')
    CURRENT_VERSION_ARCHIVE="$repopath/dist/$APP_NAME-$APP_VERSION.tar.gz"
    echohighlight "  NOTE: This is not being installed in 'editable' mode. Local updates to the package will not trigger a server restart."
    if [[ -f $CURRENT_VERSION_ARCHIVE ]] ; then
      echohighlight "  A built archive with the correct version was found ($(basename $CURRENT_VERSION_ARCHIVE))"
      echohighlight "  Installing via archive..."
      pip install $CURRENT_VERSION_ARCHIVE
    else
      pip install --upgrade pip
      pip install $repopath --ignore-installed --no-deps
    fi
  else
    # This package uses setuptools. Install in editable mode.
    pip install -e $repopath --ignore-installed --no-deps
  fi
done

# Loop through extra pip dependencies and install them (also indicated by env variables with a certain prefix)
env | awk -F = '$1 ~ /^'$ADDED_PYPI_REQUIREMENT_PREFIX'_[a-zA-Z0-9_]*$/ { print $1 }' |
while read var; do
  echohighlight "Installing external package: ${!var}"
  pip install ${!var}
done
