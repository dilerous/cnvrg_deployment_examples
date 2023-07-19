#### Worker Installs with cert-manager
Install Cert-Manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml
```

Install the GoDaddy Webhook using Helm. Make sure to update the groupName with your domain.

```bash
helm repo add godaddy-webhook https://fred78290.github.io/cert-manager-webhook-godaddy/;
helm repo update;

helm upgrade -i godaddy-webhook godaddy-webhook/godaddy-webhook \
    --set groupName=<update with your wildcard domain> \
    --set image.tag=v1.27.1 \
    --set image.pullPolicy=Always \
    --namespace cert-manager
```
Go to ``https://developer.godaddy.com`` and create an API key and Secret.
Put the key and secret into the `secret.yaml`
**Note: You need to base64 encode the API key and Secret before you add to the secret**
`printf "<your api key>" | base64`

Install Secret

```bash
kubectl apply -f secret.yaml
```

Update the email, dnsName and groupName and then apply the ClusterIssuer.

```bash
kubectl apply -f clusterissuer.yaml
```

Update the dnsNames and then apply the certificate.

```bash
kubectl apply -f certificate.yaml
```

Grab the external IP from the ingress controller and update the host A record in goDaddy

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
