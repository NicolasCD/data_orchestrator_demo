#!/bin/bash

AWS_ACCESS_KEY_ID='SCWZXQANBYN3YSQ9MQR8'
AWS_SECRET_ACCESS_KEY='b43c3ec5-998d-4677-80ba-491ac8cbb1ec'
AWS_DEFAULT_REGION='fr-par'
AWS_ENDPOINT_URL='http://s3.fr-par.scw.cloud'

echo namespace creating
#Create namespace
NAMESPACE=$(scw function namespace create | grep 'ID' | head -n1 | tr -s ' ' | cut -d' ' -f2)
#Wait creating namespace
sleep 5

#Function_1
echo function_1 creating
cd function_1
PYTHON_VERSION=3.13 && docker run --rm -v .:/home/app/function --workdir /home/app/function rg.fr-par.scw.cloud/scwfunctionsruntimes-public/python-dep:$PYTHON_VERSION pip install -r requirements.txt --target ./package

#Compress archive
zip -r function_1.zip handlers package

#Size of archive
CONTENT_LENGTH=$(du -b function_1.zip | cut -f1)

#Create function. Python 3.14 not dispo with "scw" cli
ID=$(scw function function create \
namespace-id=$NAMESPACE \
runtime=python313 \
handler='handlers/get_file.handle' \
environment-variables.AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
environment-variables.AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
environment-variables.AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
environment-variables.AWS_ENDPOINT_URL=$AWS_ENDPOINT_URL \
 | grep 'ID' | head -n1 | tr -s ' ' | cut -d' ' -f2)

#Asking for upload URL
URL=$(scw function function get-upload-url $ID content-length=$CONTENT_LENGTH | grep 'URL' | head -n1 | tr -s ' ' | cut -d' ' -f2)

#Upload archive
curl $URL \
-X PUT \
-H 'Content-Type: application/octet-stream' \
--data-binary @function_1.zip

#Deploy
scw function function deploy $ID

#Wait status is "ready"
while true; do
    STATUS=$(scw function function get $ID | grep 'Status' | head -n1 | tr -s ' ' | cut -d' ' -f2)

    if [ "$STATUS" = "ready" ]; then
        echo Waiting deploying function_1
        break
    else
        sleep 2
    fi
done




#Delete namespace
#scw function namespace delete $NAMESPACE

