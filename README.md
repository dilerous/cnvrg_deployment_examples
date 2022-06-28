### Helm Install Command Example

Set the docker hub registry username and password:

```bash
USER=<cnvrg-user>
PASSWORD=<cnvrg-user-password>
```

Helm install example using the standard base install values file.

```bash
helm install cnvrgv3 cnvrgv3/cnvrg -n cnvrg --create-namespace --wait --timeout 1000s \
-f ./values_files/standard_base_install.yaml \
--set registry.user=$USER --set registry.password=$PASSWORD
```

#### Worker Installs with cert-manager
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
kubectl apply -f ./deploy/webhook-all.yml
```

Put the key and id into the ``./worker_installs/secret.yml``

Install Secret

```bash
kubectl apply -f ./worker_installs/secret.yaml -n cert-manager
```

Update then install the ClusterIssuer

```bash
kubectl apply -f clusterissuer.yml
```


Update then install the certificate

```bash
kubectl apply -f certificate.yml -n cnvrg
```

Grab the external IP from svcs and update the host A record in goDaddy

```bash
kubectl get svc -n cnvrg
```

Apply the cluster-role.yaml to the worker cluster

```bash
kubectl apply -f ./worker_installs/cluster-role.yaml
```

Run the create_sa script then grab the output of the kubeconfig-cnvrg-job file

```bash
./worker_installs/create_sa.sh
cat kubeconfig-cnvrg-job
```

In metacloud add the cluster with the kubconfig-cnvrg-job output and make sure to select https scheme.
