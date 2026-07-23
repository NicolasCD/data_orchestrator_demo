#!/bin/bash

AWS_ACCESS_KEY_ID=''
AWS_SECRET_ACCESS_KEY=''
AWS_DEFAULT_REGION='fr-par'
AWS_ENDPOINT_URL='http://s3.fr-par.scw.cloud'

wd=$(pwd)

echo namespace creating
#Create namespace
NAMESPACE=$(scw function namespace create | grep 'ID' | head -n1 | tr -s ' ' | cut -d' ' -f2)
sleep 5
echo namespace ID $NAMESPACE created

#Function_1
echo function_1 creating
f=function_1
cd "$wd/$f"
PYTHON_VERSION=3.13 && docker run --rm -v .:/home/app/function --workdir /home/app/function rg.fr-par.scw.cloud/scwfunctionsruntimes-public/python-dep:$PYTHON_VERSION pip install -r requirements.txt --target ./package

#Compress archive
zip -r $f.zip handlers package

#Size of archive
CONTENT_LENGTH=$(du -b $f.zip | cut -f1)

#Create function. Python 3.14 not dispo with "scw" cli
ID_FUNCTION1=$(scw function function create \
namespace-id=$NAMESPACE \
runtime=python313 \
handler='handlers/get_file.handle' \
environment-variables.AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
secret-environment-variables.0.key=AWS_SECRET_ACCESS_KEY \
secret-environment-variables.0.value=$AWS_SECRET_ACCESS_KEY \
environment-variables.AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
environment-variables.AWS_ENDPOINT_URL=$AWS_ENDPOINT_URL \
 | grep 'ID' | head -n1 | tr -s ' ' | cut -d' ' -f2)

#Asking for upload URL
URL=$(scw function function get-upload-url $ID_FUNCTION1 content-length=$CONTENT_LENGTH | grep 'URL' | head -n1 | tr -s ' ' | cut -d' ' -f2)

#Upload archive
curl $URL \
-X PUT \
-H 'Content-Type: application/octet-stream' \
--data-binary @$f.zip

#Deploy
scw function function deploy $ID_FUNCTION1

#Wait status is "ready"
while true; do
    STATUS=$(scw function function get $ID_FUNCTION1 | grep 'Status' | head -n1 | tr -s ' ' | cut -d' ' -f2)

    if [ "$STATUS" = "ready" ]; then
        echo $f deployed
        break
    else
        sleep 2
    fi
done



#Function_2
echo function_2 creating
f=function_2
cd "$wd/$f"
PYTHON_VERSION=3.13 && docker run --rm -v .:/home/app/function --workdir /home/app/function rg.fr-par.scw.cloud/scwfunctionsruntimes-public/python-dep:$PYTHON_VERSION pip install -r requirements.txt --target ./package

#Compress archive
zip -r $f.zip handlers package

#Size of archive
CONTENT_LENGTH=$(du -b $f.zip | cut -f1)

#Create function. Python 3.14 not dispo with "scw" cli
ID_FUNCTION2=$(scw function function create \
namespace-id=$NAMESPACE \
runtime=python313 \
handler='handlers/compute_file.handle' \
environment-variables.AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
secret-environment-variables.0.key=AWS_SECRET_ACCESS_KEY \
secret-environment-variables.0.value=$AWS_SECRET_ACCESS_KEY \
environment-variables.AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
environment-variables.AWS_ENDPOINT_URL=$AWS_ENDPOINT_URL \
 | grep 'ID' | head -n1 | tr -s ' ' | cut -d' ' -f2)

#Asking for upload URL
URL=$(scw function function get-upload-url $ID_FUNCTION2 content-length=$CONTENT_LENGTH | grep 'URL' | head -n1 | tr -s ' ' | cut -d' ' -f2)

#Upload archive
curl $URL \
-X PUT \
-H 'Content-Type: application/octet-stream' \
--data-binary @$f.zip

#Deploy
scw function function deploy $ID_FUNCTION2

#Wait status is "ready"
while true; do
    STATUS=$(scw function function get $ID_FUNCTION2 | grep 'Status' | head -n1 | tr -s ' ' | cut -d' ' -f2)

    if [ "$STATUS" = "ready" ]; then
        echo $f deployed
        break
    else
        sleep 2
    fi
done


# Create Workflow
echo workflow creating
cd "$wd"
sed "s/function_1/$ID_FUNCTION1/g" ./workflow/S3_titanic_pattern.yaml > workflow.yaml
sed -i "s/function_2/$ID_FUNCTION2/g" workflow.yaml
scw-do-linux data-orchestrator definition create region=fr-par name="youpi" version-name="v1-0-0" yaml-content=@workflow.yaml


#Delete namespace
#scw function namespace delete $NAMESPACE

