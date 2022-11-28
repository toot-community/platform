# Infrastructure

This repository holds all platform code for running a Mastadon server on DigitalOcean using Kubernetes.

## Getting started

### Terraform

First you need to install Terraform.

Information on how to install Terraform for your platform can be [found here](https://learn.hashicorp.com/tutorials/terraform/install-cli).

### Shell

To make life a little easier you can put this alias in your shell config.

```
alias tf="terraform"
```

### AWS CLI

Install [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to interface with Spaces storage.

### Credentials

The following environment variables have to be set

Personal access token:
- DIGITALOCEAN_ACCESS_TOKEN

Spaces access keys:
- SPACES_ACCESS_KEY_ID
- SPACES_SECRET_ACCESS_KEY

Configure aws-cli with the values from SPACES_ACCESS_KEY_ID and SPACES_SECRET_ACCESS_KEY.

```
aws configure --profile digitalocean
```

Active the aws-cli profile:

```
export AWS_PROFILE=digitalocean
```

## Deployment

In the environments folder you will find a `production` folder, that's the only environment for now. If you want to test major changes you can simply copy the `production` folder, change all variables and deploy an entirely seperate environment just for testing.

To deploy the infrastructure needed on Digitalocean you can `cd` into every folder in `environments/production` and change all variables. 

After you did that you can run...

```
terraform init
terraform plan
terraform apply
```

Repeat these steps until you reached the end of the folder tree.
