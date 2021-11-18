# Terraform AWS Examples for Spot.io

## Introduction
Example Terraform for Spot.io

## Details
The module will aid in automatically connecting your AWS Account to Spot via terraform.  This will also leverage a python script to call the Spot.io APIs to create a Spot account within your Spot Organization and add the ARN of the created role. 

### Pre-Reqs
* Spot Organization Admin API token. This is required to be added as an environment variable stored in ```SPOTINST_TOKEN```.
* Python 3 installed

###Example
```hcl
module "spot_account_aws" {
    source = "stevenfeltner/aws-connect/spotinst"

    #AWS Profile (Optional)
    #profile = ""

    #Name of the linked account in Spot (Optional) If none is provided will use AWS account alias as the account name.
    #name = "test-terraform"
  
    #Policy File (Optional) File with policy to attach to role
    #policy_file = example.json
}
```
### Run
This terraform module will do the following:

On Apply:
* Create AWS IAM Policy 
* Create AWS IAM Role
* Create Spot Account within current Spot Organization
* Assign Policy to IAM Role
* Provide IAM Role to newly created Spot Account

On Destroy:
* Remove all above resources including deleting the Spot Account

## Documentation

If you're new to [Spot](https://spot.io/) and want to get started, please checkout our [Getting Started](https://docs.spot.io/connect-your-cloud-provider/) guide, available on the [Spot Documentation](https://docs.spot.io/) website.

## Getting Help

We use GitHub issues for tracking bugs and feature requests. Please use these community resources for getting help:

- Ask a question on [Stack Overflow](https://stackoverflow.com/) and tag it with [terraform-spotinst](https://stackoverflow.com/questions/tagged/terraform-spotinst/).
- Join our [Spot](https://spot.io/) community on [Slack](http://slack.spot.io/).
- Open an issue.

## Community

- [Slack](http://slack.spot.io/)
- [Twitter](https://twitter.com/spot_hq/)

## Contributing

Please see the [contribution guidelines](CONTRIBUTING.md).
