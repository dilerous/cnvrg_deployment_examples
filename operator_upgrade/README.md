# Upgrade Operator from 4.2.x to 4.3.x

1. Backup the current environment in case there are issues during the upgrade

# Cnvrg v4 Postgresql database migration

## PostgreSQL Backup

Perform the following steps on the v4.2.x environment.

Scale down the cnvrg control plane:

```
kubectl -n cnvrg scale deploy/cnvrg-operator --replicas 0;
kubectl -n cnvrg scale deploy/searchkiq --replicas 0;
kubectl -n cnvrg scale deploy/app --replicas 0; 
kubectl -n cnvrg scale deploy/istiod --replicas 0;
kubectl -n cnvrg scale deploy/redis --replicas 0;
kubectl -n cnvrg scale deploy/cnvrg-ingressgateway --replicas 0;
kubectl -n cnvrg scale deploy/systemkiq --replicas 0
```

---

Connect to the PostgreSQL pod if Postgres is running in Kubernetes

```
kubectl -n cnvrg exec -it deploy/postgres -- bash
```

---

Connect to the PostgreSQL Virtual machine using SSH for an external deployment of Postgres

```jsx
ssh -i "<rsa-key>" <username>@<machine-name-or-ip>
```

Export Postgresql password

```jsx
export PGPASSWORD=$POSTGRESQL_PASSWORD
```

---

Backup Postgresql database using the pg_dump command

```jsx
pg_dump -h postgres -U cnvrg -d cnvrg_production -Fc > cnvrg-db-backup.sql
```

---

Save the database dump locally from the Kubernetes pod:

```jsx
POSTGRES_POD=$(kubectl get pods -l=app=postgres -ncnvrg -o jsonpath='{.items[0].metadata.name}');
kubectl -n cnvrg cp ${POSTGRES_POD}:/opt/app-root/src/cnvrg-db-backup.sql cnvrg-db-backup.sql
```

---

Save the database dump file locally from the Virtual Machine for external deployments

```jsx
scp -i "<rsa-key>" <username>@<machine-name-or-ip>:/opt/app-root/src/cnvrg-db-backup.sql ./cnvrg-db-backup.sql
```

## Redis Backup

Get redis password from redis-creds secret:

```jsx
kubectl -n cnvrg get secret redis-creds -o yaml |grep CNVRG_REDIS_PASSWORD| awk '{print $2}'
```

---

Use kubectl exec command to connect to Redis pod shell

```jsx
kubectl -n cnvrg exec -it deploy/redis -- bash
```

---

Use redis-cli command to dump redis database

```jsx
redis-cli -a <redis-password> save;
```

---

Copy redis dump

```jsx
REDIS_POD=$(kubectl get pods -l=app=redis -ncnvrg -o jsonpath='{.items[0].metadata.name}');
```

---

Now that we backed up both databases we can scale the applications up.

```jsx
kubectl -n cnvrg scale deploy/cnvrg-operator --replicas 1;
kubectl -n cnvrg scale deploy/searchkiq --replicas 1;
kubectl -n cnvrg scale deploy/app --replicas 1
```

---

1. Upgrade the operator image - Check the Operator GitHub page for the latest version.
[https://github.com/AccessibleAI/cnvrg-operator](https://github.com/AccessibleAI/cnvrg-operator)

op-patch.yaml

```jsx
---
spec:
  template:
    spec:
      containers:
      - name: cnvrg-operator
        image: docker.io/cnvrg/cnvrg-operator:4.3.26
```

```jsx
kubectl -n cnvrg patch deploy/cnvrg-operator --patch-file op-patch.yaml
```

1. Wait for all pods to return to normal running state. Log into ui and verify functionality.

```jsx
kubectl -n cnvrg get pods
```

1. An additional capsule or other pods may be stuck in creating container state. If this is the case run the following:

```jsx
kubectl -n cnvrg scale deploy/capsule --replicas=0;
kubectl -n cnvrg scale deploy/capsule --replicas=1
```

1. Perform K8s cluster upgrade:

## GCP GKE Cluster Upgrade

To see the available versions for your cluster's control plane, run the following command:

```jsx
gcloud container get-server-config --region <region-cluster-is-located>
```

To upgrade to the default cluster version, run the following command:

```jsx
gcloud container clusters upgrade CLUSTER_NAME --master \
--region <region-cluster-is-located> \
--cluster-version=<k8s-version>
```

**Note**: During this time, I was unable to reach the K8s API, however cnvrg continued to work.

Upgrade a node pool:

```
gcloud container clusters upgrade CLUSTER_NAME \
--node-pool=<node-pool-name> \
--region <region-cluster-nodepool-is-located>
```

1. For GCP you need to scale down all of the pods or delete the pods on the old nodes for the operation to complete. Errors will occur due to the fact GKE is unable to terminate running pods on the old nodes.

```jsx
kubectl -n cnvrg get deploy | awk '{cmd="kubectl -n cnvrg scale deploy/" $1" --replicas=0"; system(cmd)}';
kubectl -n cnvrg get sts | awk '{cmd="kubectl -n cnvrg scale sts/" $1" --replicas=0"; system(cmd)}'
```

## AWS EKS Cluster Upgrade

Eksctl commands to upgrade an AWS EKS cluster

```jsx
eksctl upgrade cluster --name brad-cnvrg-test-install --version 1.22 --approve
```

```jsx
eksctl upgrade nodegroup \
  --name=cnvrg-app-core \
  --cluster=brad-cnvrg-test-install \
  --region=us-east-2 \
  --kubernetes-version=1.22
```

1. For AWS EKS you need to scale down all of the pods or delete the pods on the old nodes for the operation to complete. Errors will occur due to the fact EKS is unable to terminate running pods on the old nodes.

```jsx
kubectl -n cnvrg get deploy | awk '{cmd="kubectl -n cnvrg scale deploy/" $1" --replicas=0"; system(cmd)}'
kubectl -n cnvrg get sts | awk '{cmd="kubectl -n cnvrg scale sts/" $1" --replicas=0"; system(cmd)}'
```

1. Now that all the pods are scaled down you should see the old nodes going into a SchedulingDisabled state and are removed from the cluster. Once the new 1.22+ nodes are added to the cluster you can then scale cnvrg back up.
**Note**: Ensure the old nodes are set to SchedulingDisabled so cnvrg pods don’t spin back up on old nodes.

```jsx
kubectl -n cnvrg get deploy | awk '{cmd="kubectl -n cnvrg scale deploy/" $1" --replicas=1"; system(cmd)}'
kubectl -n cnvrg get sts | awk '{cmd="kubectl -n cnvrg scale sts/" $1" --replicas=1"; system(cmd)}'
```

1. Verify all pods restart onto the new 1.22+ nodes

```jsx
kubectl -n get pods -owide
```

## Additional Notes:

If there are issues and cnvrg needs to be reinstalled. The following steps outline restoring PG and Redis from backup.

## PostgreSQL Restore

Perform the following steps on the v4 environment.

Scale down app and sidekiq pods

```jsx
kubectl -n cnvrg scale deploy/cnvrg-operator --replicas 0;
kubectl -n cnvrg scale deploy/searchkiq --replicas 0;
kubectl -n cnvrg scale deploy/app --replicas 0
```

---

Copy the database backup to PostgreSQL pod

```jsx
POSTGRES=$(kubectl get pods -l=app=postgres -ncnvrg -o jsonpath='{.items[0].metadata.name}')
```

---

In the following steps we will connect to PostgreSQL pod, terminate all connection, delete and recreate the cnvrg_production database

```jsx
kubectl -n cnvrg exec -it deploy/postgres -- bash
psql
ALTER DATABASE cnvrg_production CONNECTION LIMIT 0;
DROP DATABASE cnvrg_production;
exit
```

---

Restore cnvrg_production database from the backup

```jsx
echo $POSTGRESQL_PASSWORD
```

---

Scale cnvrg app and sideqik back. If Redis restore is needed, leave the pods scaled down at 0.

```jsx
kubectl -n cnvrg scale deploy/cnvrg-operator --replicas 1;
```

```jsx
kubectl -n cnvrg scale deploy/searchkiq --replicas 1;
```

```jsx
kubectl -n cnvrg scale deploy/app --replicas 1
```

---

## Redis Restore

Copy dump.rdb to new Redis pod

```jsx
REDIS_POD=$(kubectl get pods -l=app=redis -ncnvrg -o jsonpath='{.items[0].metadata.name}');
```

---

Change the name of the AOL file to .old using mv command

```jsx
kubectl -n cnvrg exec -it deploy/redis -- mv /data/appendonly.aof /data/appendonly.aof.old
```

---

Redis config is loaded from a secret named redis-creds. Edit the value of “appendonly” from “yes” to no. (*you will need to manually enter the value in <encoded-value>)

```jsx
kubectl -n cnvrg get secret redis-creds -o yaml |grep "redis.conf"|awk '{print $2}'|base64 -d |sed -e 's/yes/no/g' > /tmp/redis-secret;
kubectl -n cnvrg patch secret redis-creds --type=merge -p '{"data": {"redis.conf": "<encoded-value>"}}'
```

---

Verify the value is set to “no”

```jsx
kubectl -n cnvrg get secret redis-creds -o yaml |grep "redis.conf"|awk '{print $2}'|base64 -d
```

---

Delete redis pod to trigger a restore:

```jsx
REDIS_POD=$(kubectl get pods -l=app=redis -ncnvrg -o jsonpath='{.items[0].metadata.name}');
```

---

On pod start-up, verify the restoration of the old dump.

```jsx
REDIS_PASSWORD=$(kubectl -n cnvrg get secret redis-creds -o yaml |grep CNVRG_REDIS_PASSWORD| awk '{print $2}')
```

---

Scale the control-plane up
```
kubectl -n cnvrg scale deploy/cnvrg-operator --replicas 1;
kubectl -n cnvrg scale deploy/searchkiq --replicas 1;
kubectl -n cnvrg scale deploy/app --replicas 1;
kubectl -n cnvrg scale deploy/istiod --replicas 1;
kubectl -n cnvrg scale deploy/redis --replicas 1;
kubectl -n cnvrg scale deploy/cnvrg-ingressgateway --replicas 1;
kubectl -n cnvrg scale deploy/systemkiq --replicas 1
```
