# Terraform - Serverless Module

This Terraform module provides all the necessary resources for deploying a serverless architecture on AWS.

## Usage

Here's a code example of how you can use this module:

```hcl
module "serverless" {
  source  = "app.terraform.io/<organization>/serverless/aws"
  version = "~> 0.0.1"

  application_name   = "serverless-boilerplate"
  environment        = "development"
  application_domain = "nexing.com"
}
```