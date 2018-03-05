#!/bin/bash
set -ex

lambda_name="ec2-autostop"
new_template_file="template_s3.yml"

#Packaging and sending package to S3, updating template with S3 URI
aws cloudformation package --template-file template.yml --s3-bucket serverless-public --s3-prefix $lambda_name --output-template-file $new_template_file --region ap-southeast-2

# Verify if lambda already published
lambda_name_exists=$(aws serverlessrepo list-applications --query "Applications[?Name==\`$lambda_name\`].[Name, Version]" --output text --region ap-southeast-2)
lambda_exists=true
if [[ -z "$lambda_name_exists" ]]; then
    echo "Lambda not found"
    lambda_exists=false
fi

source_code_url='git@github.com:octo-technology-downunder/sls-ec2-auto-stop.git'

if [[ ${lambda_exists} ]]; then
    echo "Lambda found"
    lambda_id=$(aws serverlessrepo list-applications --query "Applications[?Name==\`$lambda_name\`].ApplicationId" --output text --region ap-southeast-2)
    lambda_version=$(aws serverlessrepo get-application --application-id ${lambda_id} --query "Version.SemanticVersion" --output text --region ap-southeast-2)
    echo "Application id is $lambda_id"
    aws serverlessrepo create-application-version \
    --application-id ${lambda_id} \
    --semantic-version ${lambda_version} \
    --source-code-url ${source_code_url} \
    --template-body "`cat ./template_s3.yml`" \
    --region ap-southeast-2



else
    lambda_version='0.1.1'
    aws serverlessrepo create-application \
    --author "Octo Technology" \
    --description "Stopping EC2 instances automatically" \
    --home-page-url https://www.octo.com/en \
    --labels EC2 \
    --name $lambda_name \
    --semantic-version lambda_version \
    --source-code-url ${source_code_url} \
    --spdx-license-id Apache-2.0 \
    --template-body "`cat ./template_s3.yml`" \
    --region ap-southeast-2
fi
