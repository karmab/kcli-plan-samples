#!/bin/bash

if [ "$#" != "!1" ] ; then
    echo Usage: $0 file_path
    exit 1
fi
URL=$(hostname -I | cut -d' ' -f1):8080
FILE="$1"
if  [ ! -f $FILE ] ; then
    echo FIle $FILE not found
    exit1
fi
ID=$( basename $FILE | sed 's/_/-/g')
curl -X POST https://$URL/job/TEAM-FOLDER/credentials/store/folder/domain/_/createCredentials -F secret=@$HOME -F 'json={"": "4", "credentials": {"file": "secret", "id": "$ID", "description": "HELLO-curl", "stapler-class": "org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl", "$class": "org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl"}}'
