#!/bin/bash

# This script is used to deploy the frontend to a personal dev server 
# using SSH-forwarding.

# Running:
# 1.
# Define these variables in your .env file in the root of this repo:
#  DEV_SERVER_IP=''
#  DEV_SERVER_USER=''
#  DEV_SERVER_KEY='/home/username/.ssh/privatekey.pem'
#  DEV_SERVER_DEPLOY_DIR='/home/username/liligptfront'
#  APP_PUBLIC_URL='http://remoteip:28090/'
#  REACT_APP_KEYCLOAK_URL='https://mykeycloak:8081/auth'
#  REACT_APP_KEYCLOAK_REALM=''
#  REACT_APP_KEYCLOAK_CLIENT_ID='account'
# 
# 2.
# then run:
# bash devops/scripts/deploy-dev.sh

function main() {
  local HERE=$(cd $(dirname "$0") && pwd)
  local ROOT=$(cd "$HERE/../.." && pwd)

  # load env
  set -a
  source "$ROOT/.env"
  set +a

  echo "DEV_SERVER_IP=$DEV_SERVER_IP"
  echo "DEV_SERVER_USER=$DEV_SERVER_USER"
  echo "DEV_SERVER_KEY=$DEV_SERVER_KEY"
  echo "DEV_SERVER_DEPLOY_DIR=$DEV_SERVER_DEPLOY_DIR"
  echo "REACT_APP_PUBLIC_URL=$REACT_APP_PUBLIC_URL"
  echo ""

  # remove remote folder
  run_ssh_command "rm -rf '$DEV_SERVER_DEPLOY_DIR'" 2>/dev/null
  # recreate remote folder
  run_ssh_command "mkdir -p '$DEV_SERVER_DEPLOY_DIR'" || \
    die "Failed to create remote folder $DEV_SERVER_DEPLOY_DIR"
  # copy etc-nginx folder to the server
  copy_folder \
    "$ROOT/etc-nginx" "$DEV_SERVER_DEPLOY_DIR/etc-nginx" || \
    die "Failed to copy etc-nginx folder to $DEV_SERVER_DEPLOY_DIR/etc-nginx"
  # copy docker-compose.yml artifact file
  copy_file \
    "$ROOT/devops/artifacts/docker-compose.yml" "$DEV_SERVER_DEPLOY_DIR" || \
    die "Failed to copy docker-compose.yml to $DEV_SERVER_DEPLOY_DIR"
  # restart the container
  run_ssh_command \
    "cd '$DEV_SERVER_DEPLOY_DIR' && docker compose up -d --force-recreate" || \
    die "Failed to restart the container"
  echo ""
  echo "Done!"
}

function copy_folder() {
  local SRC="$1"
  local DEST="$2"

  echo "Copying $SRC to $DEST"
  scp -i "$DEV_SERVER_KEY" -r "$SRC" "$DEV_SERVER_USER@$DEV_SERVER_IP:$DEST"
  echo ""
}

function copy_file() {
  local SRC="$1"
  local DEST="$2"

  echo "Copying $SRC to $DEST"
  scp -i "$DEV_SERVER_KEY" "$SRC" "$DEV_SERVER_USER@$DEV_SERVER_IP:$DEST"
  echo ""
}

function run_ssh_command() {
  local COMMAND="$1"
  local FULLCOMMAND="ssh -i \"$DEV_SERVER_KEY\" \"$DEV_SERVER_USER@$DEV_SERVER_IP\" \"$COMMAND\""

  echo "Running command:"
  echo "$FULLCOMMAND"
  echo ""
  eval "$FULLCOMMAND"
}

function die() {
  echo ""
  echo "Error: $1"
  exit 1
}

main
