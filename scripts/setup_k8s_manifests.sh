#!/bin/bash

mkdir -p /home/konnik/app

chown konnik:konnik /home/konnik/app
 
git clone https://github.com/konnikamii/k8s-tf-aws-asg.git /home/konnik/app

kubectl create namespace my-app 
kubectl config set-context --current --namespace=my-app

# Install Ingress Nginx Controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.admissionWebhooks.enabled=false

sed -i -e 's/hello-app/ingress-service/' /home/konnik/app/k8s-manifests/ingress.yaml
sed -i -e 's/default/my-app/' /home/konnik/app/k8s-manifests/ingress.yaml
sed -i -e 's/<Ingress-IP>/tf-k8s-loadbalancer-1963880661.eu-central-1.elb.amazonaws.com/' /home/konnik/app/k8s-manifests/ingress.yaml

kubectl apply -f /home/konnik/app/k8s-manifests/


# kubectl create deployment demo --image=httpd --port=80
# kubectl expose deployment demo