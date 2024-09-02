# Terraform On Alibaba Cloud: A Simple Example

- Terraform Version: v0.12.12
- Alibaba Cloud Provider Version: v1.58
- Status: Script working as of 2019-10-27 (YYYY-MM-DD)

See this script in action [on Youtube](https://www.youtube.com/watch?v=15ZfFnSC1W4&feature=youtu.be)!

## What

This script creates a single ECS instance with Apache installed. The script's purpose is to illustrate how to use Terraform with Alibaba Cloud. The script goes along with a [video tutorial](https://www.youtube.com/watch?v=xlm_htUWsT0) I posted to YouTube. Feel free to check that out!

## Why

I needed a way to illustrate simple terraform usage for Alibaba Cloud users. This script accomplishes that simple goal. Although simple, this script illustrates basic Terraform usage and would be useful to anyone who is new to either Terraform or Alibaba Cloud in general.

## How 

To run the terraform scripts located here, open a terminal and navigate to the directory holding this README, then type in:

```
./setup.sh
```

That should automatically execute `terraform apply`. If you are curious about what terraform will do, then before running setup.sh, you can run `terraform plan` like this:

```
terraform plan
```

When you are done playing with the speed test ECS instance and are ready to delete all the resource created by terraform, run:

```
./destroy.sh
```

## Notes and Warnings

If you choose to execute `terraform destroy` by hand instead of using using `./destroy.sh`, be aware that the SSH key .pem file will **not** be deleted by terraform. This can cause problems if you try to execute `./setup.sh` or `terraform apply` again in the future, as this old .pem file will prevent a new .pem keyfile from being written, which will **cause your login attempts to fail**.

## Architecture

Once `./setup.sh` has run successfully, you end up with an architecture that looks like this:

![Simple Webserver on Alibaba Cloud](diagrams/terraform_on_alibaba.png)
