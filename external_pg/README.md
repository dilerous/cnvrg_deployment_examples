### Configure external Postgres Database with cnvrg.io
1. During installation of cnvrg update the values file to disable Postgres
```
dbs:
  pg:
    enabled: false
```
2. Create a secret with the Postgres details. This secret will point to your external Postgres DB.
##### Note: Ensure all of the values are base64 encoded.
pg-creds.yaml
```
apiVersion: v1
data:
  POSTGRES_DB: Y252cmfZHVjdGlvbg==
  POSTGRES_HOST: cG9zyZXM=
  POSTGRES_PASSWORD: VG5Dd2atY3l2UXlHUjNyRlg=
  POSTGRES_USER: Y2mc=
  POSTGRESQL_ADMIN_PASSWORD: VG5DdY3l2UXlHUjNyRlg=
  POSTGRESQL_DATABASE: Y252cmdfVjdGlvbg==
  POSTGRESQL_EFFECTIVE_CACHE_SIZE: MjA0OE1C
  POSTGRESQL_MAX_CONNECTIONS: NTAw
  POSTGRESQL_PASSWORD: VG5Dd2k1azJlHUjNyRlg=
  POSTGRESQL_SHARED_BUFFERS: MTAyNE1C
  POSTGRESQL_USER: Y25c=
kind: Secret
metadata:
  name: pg-creds
  namespace: cnvrg
type: Opaque
```
3. Apply the new secret to configure cnvrg to point to your external Postgres DB.
```
kubectl apply -f pg-creds.yaml
```
