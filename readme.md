### Usage

1) Load UCP client bundle


2) Create Docker Secret containing password for backup user

    ```
    echo "password" | docker secret create backuppass -
    ```

3) Schedule service
    ```
    docker service create -d \
      --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
      --mount source=dtrbackup,target=/tmp/backup \
      --restart-condition=any \
      --restart-delay 24h \
      --constraint=node.role==manager \
      support/ucpbackup:latest
    ```

```
version: '3.7'
services:
  dtr:
    deploy:
      restart_policy:
        condition: any
        delay: 24h
      replicas: 1
      placement:
        constraints:
          - node.role == worker
          - node.labels.dtr == true 
    image: support/dtrbackup
    environment:
      UCP_USER: admin
      UCP_URL: ucp.example.org
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
      replicas: 1
      placement:
        constraints:
          - node.role == manager
    image: support/ucpbackup
    environment:
      UCP_USER: admin
      UCP_URL: ucp.example.org
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

