#!/bin/bash

kill_child_processes() {
  kill -TERM "$lambda"
  wait "$lambda"
  kill -TERM "$xvfb"
}

# Kill child processes on SIGINT or SIGTERM
trap kill_child_processes SIGINT SIGTERM

XVFB_WHD="${XVFB_WHD:-1280x720x16}"

# Start Xvfb
Xvfb :99 -ac -screen 0 "$XVFB_WHD" -nolisten tcp &
xvfb=$!

# Set DISPLAY environment variable
export DISPLAY=:99

# Start runtime interface client
/lambda-entrypoint.sh "$@" &
lambda=$!

wait "$lambda"
wait "$xvfb"
