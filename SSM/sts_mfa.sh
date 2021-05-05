#!/bin/bash
#Retrieve STS Token
AWS_CLI=`which aws`

if [ ! -z $AWS_SESSION_TOKEN ]; then
        (exit 0)
fi

## Pre-Clean Env Vars
unset AccessKeyId
unset SecretAccessKey
unset SessionToken
unset IAM_USER

function getMFA_ID () {
        ## Get the MFA ID/Device Serial number
        Iam_User=$(aws sts get-caller-identity --output text |sed -E 's/^([0-9].*\:user\/)(.+)([A-Z]*)/\2/' | awk '{print $1}')
        MFA_ARN=$(aws iam list-mfa-devices --user-name $Iam_User --output text |awk '{print $3}')
}

function getSTS_Credentials () {
        read AccessKeyId SecretAccessKey SessionToken  <<< $(aws sts get-session-token --serial-number $MFA_ARN --token $MFA_CODE --output text --duration-seconds 21600 |awk '{print $2, $4, $5}')

        if [[ -z "$AccessKeyId" || -z "$SecretAccessKey" || -z "$SessionToken" ]] ; then
                echo  "Error setting temporary credentials"
        else
                echo "Temporary credentials for $Iam_User have been set as environment variables"
        fi
}



## Main ##

getMFA_ID
clear
echo "Fetching Temporary Credentials ....."
echo "Please enter MFA Token Code: "
read -s MFA_CODE
sleep 2
clear
getSTS_Credentials
echo export "AWS_ACCESS_KEY_ID=\"$AccessKeyId\"" > ~/.aws/.ssm_credentials
echo export "AWS_SECRET_ACCESS_KEY=\"$SecretAccessKey\"" >> ~/.aws/.ssm_credentials
echo export "AWS_SESSION_TOKEN=\"$SessionToken\"" >> ~/.aws/.ssm_credentials

export AWS_ACCESS_KEY_ID="$AccessKeyId"
export AWS_SECRET_ACCESS_KEY="$SecretAccessKey"
export AWS_SESSION_TOKEN="$SessionToken"

