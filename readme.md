### Usage

- Load UCP client bundle
    ```
    cd ucp-admin-bundle
    source env.sh
    ```

- Create Docker Secret containing password for backup user
    ```
    echo "mySuperSecretPassPhrase" | docker secret create backuppass -
    # secret "backuppass" created
    ```

- Schedule service
    ```
    docker service create -d \
      --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
      --mount source=dtrbackup,target=/tmp/backup \
      --restart-condition=any \
      --restart-delay 24h \
      --constraint=node.role==manager \
      adamancini/ucpbackup:3.2
    ```

- full Docker Compose example
```
version: '3.7'
services:
  dtr:
    deploy:
      restart_policy:
        condition: any
        delay: 24h
      placement:
        constraints:
          - node.role == worker
          - node.labels.com.docker.ucp.collection.system == true
    image: adamancini/dtrbackup:2.7
    environment:
      UCP_USER: admin
      UCP_URL: ucp.test.mira.annarchy.net
    secrets:
      - source: backuppass
        target: password
    volumes:
      - source: dtrbackup
        target: /backup
        type: volume
      - source: /var/run/docker.sock
        target: /var/run/docker.sock
        type: bind
  ucp:
    deploy:
      restart_policy:
        condition: any
        delay: 24h
      placement:
        constraints:
          - node.role == manager
    image: adamancini/ucpbackup:3.2
    environment:
      UCP_USER: admin
    secrets:
      - source: backuppass
        target: password
    volumes:
      - source: ucpbackup
        target: /backup
        type: volume
      - source: /var/run/docker.sock
        target: /var/run/docker.sock
        type: bind
volumes:
  ucpbackup:
  dtrbackup:
secrets:
  backuppass:
    external: true
```

