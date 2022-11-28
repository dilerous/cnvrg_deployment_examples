Kube DNS Busy Box

1. On the Kubernetes master (if you used an HA deployment, select the primary master), set up a test environment by running the following command:
```
kubectl create -f https://k8s.io/examples/admin/dns/busybox.yaml
```
2.  This command returns the following result when successful: pod/busybox created. 
3. Verify that the test pod is running by executing the following command:
```
kubectl get pods busybox  
```
If the pod is running, the command returns the following response: NAME READY STATUS RESTARTS AGE busybox 1/1 Running 0 some-amount-of-time
4. Verify that DNS is working correctly by running the following command:
```
kubectl exec -ti busybox -- nslookup kubernetes.default
```

https://help.hcltechsw.com/connections/v6/admin/install/cp_prereq_kubernetes_dns.html
