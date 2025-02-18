#!/bin/bash

mkdir -p /home/konnik/app

chown konnik:konnik /home/konnik/app
 
git clone https://github.com/konnikamii/k8s-tf-aws-asg.git /home/konnik/app

kubectl create namespace my-app 
kubectl config set-context --current --namespace=my-app

kubectl apply -f /home/konnik/app/k8s-manifests/