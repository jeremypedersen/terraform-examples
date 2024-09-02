- **Last Updated:** 2024-09-02
- **Last Tested:** PENDING

# Terraform Examples

**WARNING: Code here has not been updated since late 2022.** Updates are coming, as time allows.

Welcome! This repo holds a collection of Terraform scripts I have written myself or adapted from examples found on the web.

The aim is to cover a wide range of use cases across multiple cloud providers including AWS, Azure, GCP, and even Alibaba Cloud.

## Structure

Each Terraform example is built to be usable independently of the others. I break down the examples based on which cloud they are intended to run on. For instance Google Cloud examples are in the `gcp` directory, while AWS examples are in `aws`. 

Each of these "parent cloud" directories will contain multiple subdirectories, one for each Terraform example. Like this:

```
.
├── LICENSE
├── README.md
├── abc
│   └── chrome-on-windows
│       ├── install_chrome.ps1
│       ├── main.tf
│       ├── outputs.tf
|       └── README
│       └── variables.tf
│   └── scalable-wordpress
│       ├── setup.sh
│       ├── main.tf
│       ├── outputs.tf
|       └── README
│       └── variables.tf
├── aws
│   └── chrome-on-windows
│       ├── install_chrome.ps1
│       ├── main.tf
│       ├── outputs.tf
|       └── README
│       └── variables.tf
│   └── scalable-wordpress
│       ├── setup.sh
│       ├── main.tf
│       ├── outputs.tf
|       └── README
│       └── variables.tf
    ...and so on

```

## Usage

Simply `cd` into any example directory, such as `aws/chrome-on-windows` and run:

```
terraform init
terraform plan
terraform apply
```

When you're done trying things out, just run:

```terraform destroy```

**WARNING:** In some cases, setup and destroy scripts are included instead, which help to do additional setup/teardown. Please use those where available. For setup:

```
terraform init
./setup.sh
```

For teardown:

```
./destroy.sh
```

