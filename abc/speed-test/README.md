# Stress Test: Performance and Network Testing

- Terraform Version: v0.12.12
- Alibaba Cloud Provider Version: v1.58.0
- Status: Script working as of 2019-10-22 (YYYY-MM-DD)

See this script in action [on YouTube](https://www.youtube.com/watch?v=AFv4mBDiM1g&feature=youtu.be)!

## What

This terraform script sets up a single ECS instance and installs some stress testing and network performance testing tools (iperf, stress).

- iperf is used for network throughput testing
- stress is used to create arbitrary CPU, memory, and disk loads

The "stress" tool is there mostly for testing things like auto scaling group rules and monitoring/alerts (i.e. test that you receive an email if CPU load climbs above X% for Y minutes).

## Why

Network performance is important when choosing a cloud provider. Automated alerts and management are also important. If you need an easy way to test these things, this script is your friend.

## How 

To run terraform and automatically provision the resources defined in main.tf, open a terminal, navigate to the directory holding this README file, and then run:

```
./setup.sh
```

That should automatically execute `terraform apply`. If you are curious about what terraform will do, then before running setup.sh, you can run `terraform plan` like this:

```
terraform plan
```

When you are done playing with the speed test ECS instance and are ready to delete all the resources created by terraform, run:

```
./destroy.sh
```

## Notes and Warnings

### Install Times

It takes a little while for `apt-get` to finish running and installing `iperf` and `stress`. When you first log in, you may find that one of the commands is missing, or the machine may reject your first few log in attempts if it's still booting up. I recommend waiting for at least a minute after the the `setup.sh` script finishes, before attempting to log in.

### How To Log In

You can log into the instance like so:

```
ssh -i name_of_key.pem root@instance_ip_address
```

### Dealing with SSH Key Permissions

You may need to restrict the permissions on the .pem file to avoid an angry warning from SSH. You can do that like so:

```
chmod go-rwx name_of_key.pem
```
### Deleting SSH keys 

If you choose to execute `terraform destroy` by hand instead of using using `./destroy.sh`, be aware that the SSH key .pem file will **not** be deleted by terraform. This can cause problems if you try to execute `./setup.sh` or `terraform apply` again in the future, as this old .pem file will prevent a new .pem keyfile from being written, which will **cause your login attempts to fail**.

## Architecture

Once `./setup.sh` has run successfully, you end up with an architecture that looks like this:

![Stress and Network Testing Environment](diagrams/ubuntu_speed_test.png)
