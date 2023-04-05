# crunchydata Postgres Deployment

### Reference:

**CR documentation** - [https://access.crunchydata.com/documentation/postgres-operator/5.3.0/references/crd/#postgrescluster](https://access.crunchydata.com/documentation/postgres-operator/5.3.0/references/crd/#postgrescluster)

**Getting Started** - [https://access.crunchydata.com/documentation/postgres-operator/v5/installation/helm/](https://access.crunchydata.com/documentation/postgres-operator/v5/installation/helm/)

**Container Image list** - [https://www.crunchydata.com/developers/download-postgres/containers/postgresql13](https://www.crunchydata.com/developers/download-postgres/containers/postgresql13)

Deploy the crunchy data PG operator to get started:

```jsx
helm install pgo oci://registry.developers.crunchydata.com/crunchydata/pgo \
--set controllerImages.cluster=docker.io/cnvrg/crunchy:postgres-operator-ubi8-5.3.1-0 \
--set controllerImages.upgrade=docker.io/cnvrg/crunchy:postgres-operator-upgrade-ubi8-5.3.1-0 \
-n pgo --wait --create-namespace
```

Now that the operator is running you need to deploy a PG cluster.

Here is an example of a postgresCluster CR. This will deploy a postgres in HA.
`cnvrg-pg.yaml`

```yaml
apiVersion: postgres-operator.crunchydata.com/v1beta1
kind: PostgresCluster
metadata:
  name: cnvrg-production
  namespace: cnvrg
spec:
  patroni:
    dynamicConfiguration:
      postgresql:
        parameters:
          max_connections: 500
          shared_buffers: 2GB
          effective_cache_size: 4GB
  userInterface:
    pgAdmin:
      image: docker.io/cnvrg/crunchy:pgadmin4-ubi8-4.30-10
      dataVolumeClaimSpec:
        accessModes:
        - "ReadWriteOnce"
        resources:
          requests:
            storage: 5Gi
  image: docker.io/cnvrg/crunchy:postgres-ubi8-13.9-2
  postgresVersion: 13
  users:
  - name: cnvrg
    options: "SUPERUSER"
    databases:
    - cnvrg_production
    password:
      type: AlphaNumeric
  instances:
    - name: pgha1
      replicas: 3
      dataVolumeClaimSpec:
        accessModes:
        - "ReadWriteOnce"
        resources:
          limits:
            cpu: 4000m
            memory: 8000Mi
          requests:
            cpu: 100m
            memory: 100Mi
            storage: 80Gi
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchLabels:
                  postgres-operator.crunchydata.com/cluster: hippo-ha
                  postgres-operator.crunchydata.com/instance-set: pgha1
  backups:
    pgbackrest:
      image: docker.io/cnvrg/crunchy:pgbackrest-ubi8-2.41-2
      repos:
      - name: repo1
        volume:
          volumeClaimSpec:
            accessModes:
            - "ReadWriteOnce"
            resources:
              requests:
                storage: 5Gi
  proxy:
    pgBouncer:
      image: docker.io/cnvrg/crunchy:pgbouncer-ubi8-1.17-5
      replicas: 3
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchLabels:
                  postgres-operator.crunchydata.com/cluster: hippo-ha
                  postgres-operator.crunchydata.com/role: pgbouncer
---
apiVersion: v1
kind: Service
metadata:
  name: pgadmin
  namespace: cnvrg
  labels:
    postgres-operator.crunchydata.com/data: pgadmin
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 5050
  selector:
    postgres-operator.crunchydata.com/data: pgadmin
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: pgadmin
  namespace: cnvrg
spec:
  gateways:
  - istio-gw-cnvrg
  hosts:
  - pgadmin.aks-cicd-16722.cicd.cnvrg.me
  http:
  - retries:
      attempts: 5
      perTryTimeout: 3600s
    route:
    - destination:
        host: pgadmin.pgo.svc.cluster.local
        port:
          number: 80
    timeout: 18000s
```

apply yaml:

```jsx
kubectl apply -f cnvrg-pg.yaml
```

<aside>
⚠️ The example below is deploying the postgres cluster into the postgres ns, you can update this to the cnvrg namespace as needed

</aside>

To access the pg cluster here is the service to use and the password for the cnvrg user.

retrieve postgres cluster creds:

```yaml
HOST=$(kubectl -n pgo get secrets cnvrg-production-pguser-cnvrg \
--template={{.data.host}} | base64 -d)

PASSWORD=$(kubectl -n pgo get secrets cnvrg-production-pguser-cnvrg \
--template={{.data.password}} | base64 -d)

echo $HOST
echo $PASSWORD
```

**login to web UI:** grab credentials as done before, use following convention:

```yaml
email:    <PG_USER>@pgo
password: <PG_PASSWORD>
```
Next you need to create the pg-creds secret.
```bash
cat << EOF | kubectl apply -f -
apiVersion: v1
data:
  POSTGRES_DB: Y252cmdfcHJvZHVjdGlvbg==
  POSTGRES_HOST: cG9zdGdyZXM=
  POSTGRES_PASSWORD: SU5ocTJzNU9qbmU3Yzhha3NyNkc=
  POSTGRES_USER: Y252cmc=
  POSTGRESQL_ADMIN_PASSWORD: SU5ocTJzNU9qbmU3Yzhha3NyNkc=
  POSTGRESQL_DATABASE: Y252cmdfcHJvZHVjdGlvbg==
  POSTGRESQL_EFFECTIVE_CACHE_SIZE: MjA0OE1C
  POSTGRESQL_MAX_CONNECTIONS: NTAw
  POSTGRESQL_PASSWORD: SU5ocTJzNU9qbmU3Yzhha3NyNkc=
  POSTGRESQL_SHARED_BUFFERS: MTAyNE1C
  POSTGRESQL_USER: Y252cmc=
kind: Secret
metadata:
  name: pg-creds
  namespace: cnvrg
type: Opaque
```

patch `pg-creds` secret:

```bash
kubectl -n cnvrg patch secret pg-creds -p='{"stringData":{"POSTGRES_HOST": "'${HOST}'","POSTGRES_PASSWORD": "'${PASSWORD}'","POSTGRESQL_ADMIN_PASSWORD": "'${PASSWORD}'","POSTGRESQL_PASSWORD": "'${PASSWORD}'","POSTGRES_USER": "cnvrg","POSTGRESQL_USER":"cnvrg"}}' -v=1
```

Now that you verified connectivity to the pg database, you need to update the pg-creds secret in the cnvrg namespace. This tells cnvrg which host to point to for postgres.

example of pg-creds.yaml

```jsx
│ POSTGRES_DB: cnvrg_production                                                                                     │
│ POSTGRES_HOST: cnvrg-production-primary.postgres.svc.cluster.local                                                │
│ POSTGRES_PASSWORD: mFLX8Z^l]ITUkV4PxOAB0Z|/                                                                       │
│ POSTGRES_USER: cnvrg                                                                                              │
│ POSTGRESQL_ADMIN_PASSWORD: mFLX8Z^l]ITUkV4PxOAB0Z|/                                                               │
│ POSTGRESQL_DATABASE: cnvrg_production                                                                             │
│ POSTGRESQL_EFFECTIVE_CACHE_SIZE: 2048MB                                                                           │
│ POSTGRESQL_MAX_CONNECTIONS: "500"                                                                                 │
│ POSTGRESQL_PASSWORD: mFLX8Z^l]ITUkV4PxOAB0Z|/                                                                     │
│ POSTGRESQL_SHARED_BUFFERS: 1024MB                                                                                 │
│ POSTGRESQL_USER: cnvrg
```

### Helpful commands

Example of connecting to the pg cluster from within the cluster

```jsx
psql -h $HOST -U cnvrg -d cnvrg_production
```

List the database to confirm connectivity

```jsx
psql -h $HOST -U cnvrg -d cnvrg_production
Password for user cnvrg:
psql (13.10 (Ubuntu 13.10-1.pgdg18.04+1), server 13.9)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

cnvrg_production=> \l
                                     List of databases
       Name       |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
------------------+----------+----------+-------------+-------------+-----------------------
 cnvrg_production | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 | =Tc/postgres         +
                  |          |          |             |             | postgres=CTc/postgres+
                  |          |          |             |             | cnvrg=CTc/postgres
 postgres         | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 |
 template0        | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 | =c/postgres          +
                  |          |          |             |             | postgres=CTc/postgres
 template1        | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 | =c/postgres          +
                  |          |          |             |             | postgres=CTc/postgres
(4 rows)
```

Drop a database

```jsx
DROP DATABASE cnvrg_production;
```

Create a database

```jsx
CREATE DATABASE cnvrg_production;
```

Add full permissions to database

```jsx
GRANT ALL PRIVILEGES ON DATABASE cnvrg_production TO cnvrg;
```

### Connect to DB using port forwarding

First grab one of the names of the production pods

```jsx
kubectl -n postgres get pods
```

```jsx
NAME                                          READY   STATUS      RESTARTS       AGE
cnvrg-production-backup-xbwg-kzx2j            0/1     Completed   0              11d
cnvrg-production-pgbouncer-6bfd6dffb9-g9qhz   2/2     Running     18 (17h ago)   11d
cnvrg-production-pgbouncer-6bfd6dffb9-s59rk   2/2     Running     18 (17h ago)   11d
cnvrg-production-pgha1-d8nq-0                 4/4     Running     36 (17h ago)   11d
cnvrg-production-pgha1-l5rh-0                 4/4     Running     36 (17h ago)   11d
cnvrg-production-pgha1-zht4-0                 4/4     Running     36 (17h ago)   11d
cnvrg-production-repo-host-0                  2/2     Running     18 (17h ago)   11d
```

Next you need to port forward the service with the command below

```jsx
kubectl  -n postgres port-forward pod/cnvrg-production-pgha1-d8nq-0 :5432
```

Pay attention tot he randomly selected local port that was provided. In my example I can get to the DB using 127.0.0.1:51647

```jsx
k port-forward pod/cnvrg-production-pgha1-d8nq-0 :5432 -n postgres
Forwarding from 127.0.0.1:51647 -> 5432
```

Install PG Admin

Here is how to connect to the DB using PG Admin

Right click on servers and select “Register Server”

Provide a Name

![Untitled](crunchydata%20Postgres%20Deployment%207f6e13d9868f4798bdec0ecbb1ee7300/Untitled.png)

Now configure the connection settings. You can get the database password by doing the following

```jsx
kubectl -n postgres get secret cnvrg-production-pguser-cnvrg -ojsonpath='{.data.password}'
```

![Untitled](crunchydata%20Postgres%20Deployment%207f6e13d9868f4798bdec0ecbb1ee7300/Untitled%201.png)

Now click “save”

![Untitled](crunchydata%20Postgres%20Deployment%207f6e13d9868f4798bdec0ecbb1ee7300/Untitled%202.png)[]()
