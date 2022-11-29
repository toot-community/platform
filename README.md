# Infrastructure

> :warning: **This code is provided as-is — it is not meant to be executed verbatim. No support is provided in any way.**

This repository holds all platform code for running a Mastadon server on [DigitalOcean](https://www.digitalocean.com/) using [Kubernetes](https://www.digitalocean.com/products/kubernetes).

## Getting started

1. [Create a Digitalocean account](https://cloud.digitalocean.com/login)
2. [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).
3. [Install aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Credentials

[Create a Personal Access Token and a Spaces access key](https://cloud.digitalocean.com/account/api/tokens).

The following environment variables have to be set

Personal access token:
- `DIGITALOCEAN_ACCESS_TOKEN`

Spaces access keys:
- `SPACES_ACCESS_KEY_ID`
- `SPACES_SECRET_ACCESS_KEY`

[Configure aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) with the values from `SPACES_ACCESS_KEY_ID` and `SPACES_SECRET_ACCESS_KEY`:

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

Continue with [deploying Mastodon](https://github.com/toot-community/kubernetes).
