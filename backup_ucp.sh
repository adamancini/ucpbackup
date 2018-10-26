#!/usr/bin/env bash

# set -x
function error_exit {
  echo "$1" >&2   ## Send message to stderr. Exclude >&2 if you don't want it that way.
  exit "${2:-1}"  ## Return a code specified by $2 or 1 by default.
}

[[ -z $UCP_URL ]] && error_exit "you must specify a UCP URL to backup from"
[[ -z $UCP_USER ]] && error_exit "you must specify a UCP User with admin privileges"
[[ ! -f /run/secrets/password ]] && error_exit "you must mount a docker secret with your admin password in /run/secrets/password; see 'docker secrets' usage."

UCP_PASSWORD="$(cat /run/secrets/password)"
UCP_ID=$(docker inspect $(docker ps -aq --filter=name=ucp-agent | head -n 1) | jq -r '.[].Config.Env[]' | grep UCP_INSTANCE_ID | cut -d "=" -f 2)
UCP_VERSION=$(docker inspect $(docker ps -aq --filter=name=ucp-agent | head -n 1) | jq -r '.[].Config.Env[]' | grep IMAGE_VERSION | cut -d "=" -f 2)


echo "Performing UCP backup against cluster at $UCP_URL with id $UCP_ID."
docker run --rm -i \
  --name ucp \
  --log-driver none \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker/ucp:$UCP_VERSION backup \
  --debug \
  --id $UCP_ID \
  --passphrase $UCP_PASSWORD \
  > "/backup/$(date --iso-8601)-$(hostname)-ucp-backup.tar"

