## Helm Install Command Example

Set the docker hub registry username and password:

```bash
USER=<cnvrg-user>
PASSWORD=<cnvrg-user-password>
```

Helm install example using the standard base install values file.

```bash
helm install cnvrgv3 cnvrgv3/cnvrg -n cnvrg --create-namespace --wait --timeout 1000s \
-f ./values_files/standard_base_install.yaml \
--set registry.user=$USER --set registry.user=$PASSWORD
```
