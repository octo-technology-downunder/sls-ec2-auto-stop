#!/bin/bash
set -ex

lambda_name="ec2-autostop"
new_template_file="template_s3.yml"

#Packaging and sending package to S3, updating template with S3 URI
aws cloudformation package --template-file template.yml --s3-bucket serverless-public --s3-prefix $lambda_name --output-template-file $new_template_file --region ap-southeast-2

# Verify if lambda already published
lambda_name_exists=$(aws serverlessrepo list-applications --query "Applications[?Name==\`$lambda_name\`].Name" --output text --region ap-southeast-2)
lambda_exists=true
if [[ -z "$lambda_name_exists" ]]; then
    echo "Lambda not found"
    lambda_exists=false
fi

version='0.1.1'
source_code_url='github.com'

if [[ ${lambda_exists} ]]; then
    echo "Lambda found"
    lambda_id=$(aws serverlessrepo list-applications --query "Applications[?Name==\`$lambda_name\`].ApplicationId" --output text --region ap-southeast-2)
    echo "Application id is $lambda_id"
    aws serverlessrepo create-application-version \
    --application-id ${lambda_id} \
    --semantic-version ${version} \
    --source-code-url ${source_code_url} \
    --template-body ${new_template_file} \
    --region ap-southeast-2
else
    aws serverlessrepo create-application \
    --author "Octo Technology" \
    --description "Stopping EC2 instances automatically" \
    --home-page-url https://www.octo.com/en \
    --labels EC2 \
    --name $lambda_name \
    --semantic-version $version \
    --source-code-url ${source_code_url} \
    --spdx-license-id Apache-2.0 \
    --template-body $new_template_file \
    --region ap-southeast-2
fi
