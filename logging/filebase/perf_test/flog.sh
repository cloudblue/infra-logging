#!/bin/bash
set -e


if [ -z "$1" ]
  then
    command="delete"
else 
    command=$1
fi

if [ -z "$2" ]
  then
    parallelism=1
else 
    parallelism=$2
fi

echo command: $command - parallelism: $parallelism

id=$(date -u +"%Y%m%d%H%M%S")

cat << EOF | kubectl  $command -n infrastructure -f -
---
apiVersion: batch/v1
kind: Job
metadata: 
  name: flog
spec: 
  parallelism: $parallelism
  template: 
    metadata: 
      name: flog
      labels:
        app: flog-$id
    spec: 
      containers: 
        - 
          args: 
            - '-f'
            - apache_combined
            - '-n'
            - '1000'
            - '-d'
            - '0.05ms'
            - '-s'
            - '0.05ms'
          command: 
            - flog
          image: mingrammer/flog
          name: flog
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchExpressions:
                - key: job-name
                  operator: In
                  values:
                  - "flog"
      restartPolicy: Never       
EOF
