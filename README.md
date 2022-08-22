# Terraform API Gateway 

This terraform template creates an apigateway that invokes a lambda. The API will be protected by an api key.

## Prerequisites

In order for his template to work you will need to add a secret to secrets manager that will act the api key. This secret should be a plain text secret. The secret must also be between 30 and 128 characters.

This template also assumes there is a lambda you want to use as the targer of the apigateway. You will need that lambda name. Fill that out in the `terraform.tfvars` file.

## Deploy the sample application

During the first deploy make sure to use `QA` as the env variable. What this will do is deploy both PROD and QA to apigateway. This is a necessary step because you can not create a usage without a deployment stage. After the first deployment deployments to QA and PROD must be done manually.
