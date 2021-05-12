#!/bin/bash

set -x
echo "#########################################################################################"
echo "#                       Stating Installing Docker                                       #"
echo "#########################################################################################"
curl https://releases.rancher.com/install-docker/19.03.sh | sh
usermod -a -G docker ubuntu

docker run -d -p 80:80 --name web nginx

echo "#########################################################################################"
echo "#                       Stating AzCLI                                                   #"
echo "#########################################################################################"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "vm successfull started" > ./log.txt

# Login with Identity
az login -i
az storage blob upload --account-name ${storage_name} -f ./log.txt -c ${container_name} -n log.txt --auth-mode login



