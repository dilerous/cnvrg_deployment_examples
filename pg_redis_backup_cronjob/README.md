## Postgres and Redis Backup cronjob

### How to use

1. Update the ```cron-job.yaml``` with the schedule to match your environment. 
    [Here](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs) you can find details on how to configure the schedule.
    ```yaml
    spec:
      schedule: "0 0 * * *" # Update your schedule for when the cron job runs
    ```


2. Create the config map:
    ```bash
    kubectl -n cnvrg create configmap dbs-backup-script --from-file=./dbs-backup.sh
    ```

3. Apply the ```cron-job.yaml``` file to the cluster:
    ```bash
    kubectl -n cnvrg apply -f cron-job.yaml
    ```
***Note:*** To manually run your cron job, type the following:
```bash
kubectl -n cnvrg create job test-backup-job --from cronjob/dbs-backups
```
