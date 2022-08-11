#!/bin/bash
kubectl get crd --no-headers -o custom-columns=":metadata.name" | grep istio | xargs kubectl delete crd
kubectl get crd --no-headers -o custom-columns=":metadata.name" | grep cnvrg | xargs kubectl delete crd
kubectl get deployment -n cnvrg --no-headers -o custom-columns=":metadata.name" | xargs kubectl delete deployment -n cnvrg
kubectl get pvc -n cnvrg --no-headers -o custom-columns=":metadata.name" | xargs kubectl delete pvc -n cnvrg
kubectl get ingress -n cnvrg --no-headers -o custom-columns=":metadata.name" | xargs kubectl delete ingress -n cnvrg
kubectl get svc -n cnvrg --no-headers -o custom-columns=":metadata.name" | xargs kubectl delete svc -n cnvrg
kubectl get pods -n cnvrg --no-headers -o custom-columns=":metadata.name" | xargs kubectl delete pod -n cnvrg
