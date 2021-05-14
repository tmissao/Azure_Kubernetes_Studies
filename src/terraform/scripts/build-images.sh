#!/bin/bash

az acr login --name ${acr_registry}

# Docker Build Sender Image
docker build -t ${acr_registry}.azurecr.io/studies/sender  ../nodejs/sender
docker push ${acr_registry}.azurecr.io/studies/sender


# Docker Build Consumer Image
docker build -t ${acr_registry}.azurecr.io/studies/consumer  ../nodejs/consumer
docker push ${acr_registry}.azurecr.io/studies/consumer
