### Helm Install Command Example

Set the docker hub registry username and password:

```bash
USER=<cnvrg-user>
PASSWORD=<cnvrg-user-password>
```

Helm install example using the standard base install values file.

```bash
helm install cnvrg cnvrgv3/cnvrg -n cnvrg --create-namespace --wait --timeout 1000s \
-f ./values_files/standard_base_install.yaml \
--set registry.user=$USER --set registry.password=$PASSWORD
```

#### Worker Install with cert-manager
Install Cert-Manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml
```

Clone down the goDaddy Webhook Repo

```bash
git clone git@github.com:snowdrop/godaddy-webhook.git
```

Apply webhook yaml file to install godaddy webhook

```bash
kubectl apply -f deploy/webhook-all.yml
```

Install cnvrg

```bash
helm install cnvrg cnvrgv3/cnvrg -n cnvrg --create-namespace --timeout 1000s --wait \
-f ./values_files/worker_cluster_with_certSecret.yaml
```

Go to godaddy api and create a api token with key as production
``https://developer.godaddy.com``
Put the key and id into the ``./worker_installs/secret.yml``

Install Secret

```bash
kubectl apply -f secret.yaml -n cert-manager
```

Install ClusterIssuer

```bash
kubectl apply -f ./worker_installs/clusterissuer.yml
```

Install the certificate

```bash
kubectl apply -f certificate.yml -n cnvrg
```

Grab the external IP from svcs and update the host a record in goDaddy

```bash
kubectl get svc -n cnvrg
```

Apply the cluster-role.yaml to the worker cluster

```bash
kubectl apply -f ./worker_installs/cluster-role.yaml
```

Grab the kubeconfig info from the create_sa.sh script

```bash
./worker_installs/create_sa.sh
cat kubeconfig-cnvrg-job
```

In metacloud add the cluster with the kubconfig-cnvrg-job output and make sure to select https scheme.
