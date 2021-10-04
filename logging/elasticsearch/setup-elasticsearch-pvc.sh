#!/bin/bash

cat << EOF | kubectl -n infrastructure apply -f -
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: elasticsearch-master-elasticsearch-master-0
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium
  resources:
    requests:
      storage: 200Gi
---      
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: elasticsearch-master-elasticsearch-master-1
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium
  resources:
    requests:
      storage: 200Gi
EOF
