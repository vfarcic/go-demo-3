#!/usr/bin/env bash

# Commands
readonly SCRIPT_NAME="build_docker.sh"
readonly TAG_ARG="-t tag (tag as 'tag')"
readonly TAG_TIMESTAMP_ARG="-d (tag as yyyymmdd-hhmm)"
readonly TAG_LATEST_ARG="-l (tag as latest)"
readonly IMAGE_DIR_ARG="-i (image directory to build)"
readonly PUSH="-p (push the image)"
readonly IMAGE_NAME_ARG="-n imagename (e.g. 'vfabric/go-demo')"
readonly TIMESTAMP=$(date +%Y%m%d%H%M)

usage() {
    log_console "Usage:"
    log_console "    $SCRIPT_NAME $IMAGE_NAME_ARG $TAG_ARG $TAG_TIMESTAMP_ARG $TAG_LATEST_ARG $PUSH $IMAGE_DIR_ARG -  build, tag and push the docker image to the docker registry"
    exit 1
}

function log_console
{
    if [[ ${#1} != 0 ]]; then
        echo "$1"
    fi
}


TAG=
TIMESTAMP_TAG=
LATEST_TAG=
PUSH_FLAG=
IMAGE_DIR=
IMAGE_NAME=

function docker_push
{
    if [[ ${PUSH_FLAG} = true ]]; then
        if [[ ! -z $1 ]]; then
            log_console "pushing as $1"
            sudo docker push $1
        else
            echo "no tag been provided to push "
            exit 1
        fi
    fi
}

TAG_COMMAND=
# Main
while getopts "n:t:ldpi:" opt; do
  case $opt in
    n) IMAGE_NAME="${OPTARG}" ;;
	t) TAG="$IMAGE_NAME:${OPTARG}"
	   TAGS+=("$TAG")
	   ;;
    d) TIMESTAMP_TAG="$IMAGE_NAME:$TIMESTAMP"
       TAGS+=("$TIMESTAMP_TAG")
	   ;;
	l) LATEST_TAG="$IMAGE_NAME:latest"
	   TAGS+=("$LATEST_TAG")
	   ;;
	p) PUSH_FLAG=true ;;
	i) IMAGE_DIR="${OPTARG}" ;;
    \?) usage; exit 0 ;;
  esac
done

if [[ -z $TAGS && -z $TIMESTAMP_TAG && -z $LATEST_TAG ]]; then
    usage;
fi
if [[ -z $IMAGE_DIR || -z $IMAGE_NAME ]]; then
    usage;
fi

for val in "${TAGS[@]}"; do
    log_console "Tagging as $val"
	TAG_COMMAND="$TAG_COMMAND -t $val"
done

sudo docker build $TAG_COMMAND $IMAGE_DIR

for val in "${TAGS[@]}"; do
	docker_push $val
done



