#!/bin/bash

app=$(kubectl -n cnvrg get pods -l app=app -o=jsonpath='{.items[0].metadata.name}')
kubectl -n cnvrg cp ./bootstrap.rb $app:/opt/app-root/src
kubectl -n cnvrg exec -it deploy/app -c cnvrg-app -- bash -c "chmod +x ./bootstrap.rb"
kubectl -n cnvrg exec -it deploy/app -c cnvrg-app -- bash -c "rails r ./bootstrap.rb"
