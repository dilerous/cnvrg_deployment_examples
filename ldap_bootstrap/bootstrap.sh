#!/bin/bash

echo "Update both the bootstrap.rb and change-registry.rb before running"
echo "Press '1' to create Admin User for new Deployment"
echo "Press '2' to change base registry"
read -p 'Selection: ' input

if [ $input -eq 1 ]
then
  app=$(kubectl -n cnvrg get pods -l app=app -o=jsonpath='{.items[0].metadata.name}')
  kubectl -n cnvrg cp ./bootstrap.rb $app:/opt/app-root/src
  kubectl -n cnvrg exec -it deploy/app -c cnvrg-app -- bash -c "chmod +x ./bootstrap.rb"
  kubectl -n cnvrg exec -it deploy/app -c cnvrg-app -- bash -c "rails r ./bootstrap.rb"
fi

if [ $input -eq 2 ]
then
  app=$(kubectl -n cnvrg get pods -l app=app -o=jsonpath='{.items[0].metadata.name}')
  kubectl -n cnvrg cp ./change-registry.rb $app:/opt/app-root/src
  kubectl -n cnvrg exec -it deploy/app -c cnvrg-app -- bash -c "chmod +x ./change-registry.rb"
  kubectl -n cnvrg exec -it deploy/app -c cnvrg-app -- bash -c "rails r ./change-registry.rb"
fi
