# ODL Devstack Tools

This repo provides some helpful tools for configuring and running [devstack](https://github.com/edx/devstack) (edX's Docker-based solution for running Open edX services).

### Features

- Create a custom docker image (which is really just a layer on top of edX's 
  devstack image) with some helpful packages already installed (e.g.: `pdbpp`)
- Automatically apply changes to the JSON config files in devstack when running the containers
  (`lms.env.json`, `cms.env.json`, `lms.auth.json`, `cms.auth.json`).
- Via docker-compose configuration, specify local repos that you want mounted 
  into the devstack containers and installed. 
  This is useful for testing changes in repos that devstack depends on (e.g.: `XBlock`, 
  `xblock-utils`, `edx-sga`). Since they are installed via pip with the `-e` flag, the 
  server restarts automatically when you make changes.
- Create any number of docker-compose files to take advantage of the features above for different
  purposes (e.g.: one compose file for testing changes to `XBlock`, another one for testing changes to `edx-sga`, 
  another one for testing some LMS feature that requires a bunch of config changes). You can also combine them as 
  desired.
- If desired, sets up your container to enable exporting courses to Github (specifically the 
  github.mit.edu private repos) so you don't need to create SSH keys and add them to Github
  every single time you restart your containers. 
 

### Configuring and using the custom devstack image

These environment variables will need to be set in your host machine (most likely in `~/.bash_profile`, et. al.):

```bash
# The name of the custom devstack image that will be built as a layer on top of the devstack image.
CUSTOM_DEVSTACK_IMG_NAME='edxops/edxapp:odlcustom'
# Path to this repo on your machine.
CUSTOM_DEVSTACK_PATH="/path/to/odl_devstack_tools"
# The path to helper files in the container. ***Do not change this value***
DEVSTACK_CONTAINER_HELPER_DIR="/edx/app/edxapp/helper"
# The path to the directory in the container where local repos will be mounted. ***Do not change this value***
DEVSTACK_CONTAINER_MOUNT_DIR="/edx/app/edxapp/venvs/edxapp/src"
```

When you have the latest images from edX (via `make pull` - more details 
[here](https://github.com/edx/devstack#using-the-latest-images)), you can run the following command to 
create the new image based on edX's image.
 
```bash
docker build $CUSTOM_DEVSTACK_PATH -t $CUSTOM_DEVSTACK_IMG_NAME --no-cache
```

To spin up the containers using the custom image and take advantage of the features described above,
run `docker-compose up` like the commands below. For the sake of familiarity and consistency, these 
commands mimic the ['make dev.up' command in devstack](https://github.com/edx/devstack/blob/master/Makefile).

```bash
# Run LMS with the basic custom docker-compose file
docker-compose -f docker-compose.yml -f docker-compose-host.yml -f $CUSTOM_DEVSTACK_PATH/docker-compose-custom.yml up -d lms
# Run LMS with the basic custom docker-compose file and an additional one that you created
docker-compose -f docker-compose.yml -f docker-compose-host.yml \
  -f $CUSTOM_DEVSTACK_PATH/docker-compose-custom.yml -f $CUSTOM_DEVSTACK_PATH/docker-compose-mine.yml up -d lms
```

### Applying JSON config changes

##### Summary

Changes to JSON config values can be automatically applied when the container starts by doing the following:

- Create a JSON patch file on your host machine in `./configpatch`
- In your custom docker-compose file, mount the JSON patch file into the 
  `${DEVSTACK_CONTAINER_HELPER_DIR}/configpatch/` directory in the container

##### Detail

You can automatically apply changes to any of the devstack JSON config files 
(`lms.env.json`, `cms.env.json`, `lms.auth.json`, `cms.auth.json`) by creating a patch file 
in the `./configpatch` directory. These patch files should be `.json` type and in 
[jsonpatch](http://jsonpatch.com/) format. The file name doesn't matter. See `./configpatch/patch.json.example` 
for example usage.

After the patch file is created, the patch file needs to be mounted into the container by adding to the `volume`
section of your docker-compose file.

```yml
services:
  lms:
    volumes:
      - ${CUSTOM_DEVSTACK_PATH}/configpatch/my_patch.json:${DEVSTACK_CONTAINER_HELPER_DIR}/configpatch/my_patch.json
```

### Specifying local repos to be mounted and installed automatically

##### Summary

Local repos can be mounted and installed in devstack containers by doing the following:

- In your docker-compose file, add a environment variable with a name that starts with `ADDED_REQ_`, with the value
  being the package name (e.g.: `ADDED_REQ_XBLOCK=XBlock`) 
- In your docker-compose file, mount your local repo directory alongside the `edx-platform` virtualenv packages 
  (e.g.: /path/to/repo/XBlock:${DEVSTACK_CONTAINER_MOUNT_DIR}/XBlock)

##### Detail

When hacking on or testing changes to some package that edX depends on, it's very helpful to mount and install your 
local repo into the devstack containers. Among the benefits: (1) changes you make to those repos trigger a server
restart automatically for LMS/Studio; (2) when you create a migration for one of those repos in the devstack container, 
the migration files are immediately available in your local repo.

Running `docker-compose up` with the example docker-compose file below would automatically mount the `XBlock` repo 
and install it as a local package in the `lms` container.
   
```yml
services:
  lms:
    environment:
      - ADDED_REQ_XBLOCK=XBlock
    volumes:
      - /path/to/repo/XBlock:${DEVSTACK_CONTAINER_MOUNT_DIR}/XBlock
```


### Enabling course content exporting to Github in Studio

If you want to be able to export course content to github.mit.edu, follow these steps:

1. On your **host machine**, generate an SSH key ([Github guide](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#generating-a-new-ssh-key))
  and move the keys (`id_rsa` and `id_rsa.pub`) to `path/to/odl_devstack_tools/ssh`.
  **NOTE**: Use your github.mit.edu email address and NO PASSPHRASE.
1. Add that SSH key to your Github account ([guide](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/)).
1. Apply all the necessary JSON settings values and advanced course settings related
  to course content exporting.

### Extras

It's helpful to have a shorthand for running the containers using certain compose files explicitly or by default.
The variables and bash function below provide that.  

```bash
export USE_CUSTOM_DEVSTACK=true
export DEFAULT_CUSTOM_DEVSTACK_COMPOSE_FILE="docker-compose-custom.yml"

function dedxup() {
  local compose_file_args=()
  
  # Add custom compose file(s) to docker-compose params if it's set and the file exists
  if [ "$USE_CUSTOM_DEVSTACK" = true ]; then
    compose_file_args+=( '-f' "$CUSTOM_DEVSTACK_PATH/$DEFAULT_CUSTOM_DEVSTACK_COMPOSE_FILE" )
    if [ ! -z $ADDED_DEVSTACK_COMPOSE_FILE ]; then
      compose_file_args+=( '-f' "$CUSTOM_DEVSTACK_PATH/$ADDED_DEVSTACK_COMPOSE_FILE" )
    fi
    for compose_file_arg in "${compose_file_args[@]}"
    do
      if [ $compose_file_arg != '-f' ]; then
        echo -e "Using additional compose file (\033[1;92m$compose_file_arg\e[0m) ..."
      fi
    done
    echo ''
  fi
  
  docker-compose -f docker-compose.yml -f docker-compose-host.yml ${compose_file_args[@]} up -d $@
}
```

Example usages:
```bash
# Run LMS using the default custom compose file (docker-compose-custom.yml)
dedxup lms
# Run LMS without any custom compose files
USE_CUSTOM_DEVSTACK=false dedxup lms
# Run LMS using the default custom compose file AND an additional custom compose file
ADDED_DEVSTACK_COMPOSE_FILE='docker-compose-xblock-dev.yml' dedxup lms
```
