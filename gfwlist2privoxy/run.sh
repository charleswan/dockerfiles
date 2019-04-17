#!/bin/sh
# Modified from: https://github.com/docker/compose/releases/download/1.24.0/run.sh

# example:

# cd /tmp
# wget https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt
# ~/.local/bin/gfwlist2privoxy -i gfwlist.txt -f gfwlist.action -p 127.0.0.1:1080 -t socks5
# sudo cp gfwlist.action /etc/privoxy/

set -e

VERSION="1.0.3"
IMAGE="charleswan/gfwlist2privoxy:$VERSION"


# Setup options for connecting to docker host
if [ -z "$DOCKER_HOST" ]; then
    DOCKER_HOST="/var/run/docker.sock"
fi
if [ -S "$DOCKER_HOST" ]; then
    DOCKER_ADDR="-v $DOCKER_HOST:$DOCKER_HOST -e DOCKER_HOST"
else
    DOCKER_ADDR="-e DOCKER_HOST -e DOCKER_TLS_VERIFY -e DOCKER_CERT_PATH"
fi


# Setup volume mounts for gfwlist2privoxy config and context
if [ "$(pwd)" != '/' ]; then
    VOLUMES="-v $(pwd):$(pwd)"
fi
if [ -n "$GFWLIST2PRIVOXY_FILE" ]; then
    GFWLIST2PRIVOXY_OPTIONS="$GFWLIST2PRIVOXY_OPTIONS -e GFWLIST2PRIVOXY_FILE=$GFWLIST2PRIVOXY_FILE"
    gfwlist2privoxy_dir=$(realpath $(dirname $GFWLIST2PRIVOXY_FILE))
fi
# TODO: also check --file argument
if [ -n "$gfwlist2privoxy_dir" ]; then
    VOLUMES="$VOLUMES -v $gfwlist2privoxy_dir:$gfwlist2privoxy_dir"
fi
if [ -n "$HOME" ]; then
    VOLUMES="$VOLUMES -v $HOME:$HOME -v $HOME:/root" # mount $HOME in /root to share docker.config
fi

# Only allocate tty if we detect one
if [ -t 0 -a -t 1 ]; then
        DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

# Always set -i to support piped and terminal input in run/exec
DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -i"


# Handle userns security
if [ ! -z "$(docker info 2>/dev/null | grep userns)" ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS --userns=host"
fi

exec docker run --rm $DOCKER_RUN_OPTIONS $DOCKER_ADDR $GFWLIST2PRIVOXY_OPTIONS $VOLUMES -w "$(pwd)" $IMAGE "$@"
