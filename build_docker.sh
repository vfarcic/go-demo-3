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
    log_console "    $SCRIPT_NAME $IMAGE_NAME_ARG $TAG_ARG $TAG_TIMESTAMP_ARG $TAG_LATEST_ARG $PUSH $IMAGE_DIR_ARG -  build, tag and push the jenkins image to the docker registry"
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

TAGS=
# Main
while getopts "n:t:ldpi:" opt; do
  case $opt in
    n) IMAGE_NAME="${OPTARG}" ;;
	t) TAG="$IMAGE_NAME:${OPTARG}"
	   TAGS="$TAGS -t $TAG"
	   ;;
    d) TIMESTAMP_TAG="$IMAGE_NAME:$TIMESTAMP"
       TAGS="$TAGS -t $TIMESTAMP_TAG"
	   ;;
	l) LATEST_TAG="$IMAGE_NAME:latest"
	   TAGS="$TAGS -t $LATEST_TAG"
	   ;;
	p) PUSH_FLAG=true ;;
	i) IMAGE_DIR="${OPTARG}" ;;
    \?) usage; exit 0 ;;
  esac
done

if [[ -z $TAG && -z $TIMESTAMP_TAG && -z $LATEST_TAG ]]; then
    usage;
fi
if [[ -z $IMAGE_DIR || -z $IMAGE_NAME ]]; then
    usage;
fi

log_console "Tagging as $TAGS"
sudo docker build $TAGS $IMAGE_DIR

if [[ ! -z $LATEST_TAG ]]; then
    docker_push ${LATEST_TAG}
fi
if [[ ! -z $TIMESTAMP_TAG ]]; then
    docker_push ${TIMESTAMP_TAG}
fi
if [[ ! -z $TAG ]]; then
    docker_push ${TAG}
fi