#!/bin/bash

#k8s-deployment.sh

sed -i 's#replace#docker-registry:5000/java-app:latest#g' k8s_deployment_service.yaml
kubectl -n default apply -f k8s_deployment_service.yaml