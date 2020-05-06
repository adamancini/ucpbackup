#!/usr/bin/env bash

# set -x
function error_exit {
  echo "$1" >&2   ## Send message to stderr. Exclude >&2 if you don't want it that way.
  exit "${2:-1}"  ## Return a code specified by $2 or 1 by default.
}

# [[ -z $UCP_URL ]] && error_exit "you must specify a UCP URL to backup from"
[[ -z $UCP_USER ]] && error_exit "you must specify a UCP User with admin privileges"
[[ ! -f /run/secrets/password ]] && error_exit "you must mount a docker secret with your admin password in /run/secrets/password; see 'docker secrets' usage."


UCP_PASSWORD="$(cat /run/secrets/password)"
UCP_CLUSTER_ID=$(docker info --format '{{ .Swarm.Cluster.ID }}')
UCP_VERSION=$(docker inspect --format='{{ index .Config.Labels "com.docker.ucp.version"}}' ucp-controller)

echo "Performing UCP backup against cluster at $UCP_URL with id $UCP_CLUSTER_ID."
docker container run --rm -i\
  --name ucp \
  --log-driver none \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker/ucp:"${UCP_VERSION}" backup \
  --debug \
  --passphrase "${UCP_PASSWORD}" \
  > "/backup/$(date --iso-8601)-$(hostname)-ucp-backup.tar"

echo "Rotate backups"
find /backup/*-ucp-backup.tar -exec ls -lh {} +;
echo "Checking for backup tarballs older than ${MAX_AGE} days"
find /backup/*-ucp-backup.tar -mtime +"${MAX_AGE}" -exec ls -lh {} +;
find /backup/*-ucp-backup.tar -mtime +"${MAX_AGE}" -delete
echo "Done"
