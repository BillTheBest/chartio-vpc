# Connecting Chartio to a Database Within an Aamazon VPC

This repo accompanies the tutorial found [here](http://support.chartio.com/connecting-to-a-database-within-an-amazon-vpc).

## Architecture

![](http://f.cl.ly/items/1f392L1z2F3d0k3F032a/00.png "Diagram of the VPC architecture.")

Note: Egress rules will not be exactly as depicted due to [this Terraform issue](https://github.com/hashicorp/terraform/issues/1169).

## Requirements

[Terraform](https://www.terraform.io/) v0.3.7

## Usage

```
terraform apply

ssh ubuntu@<EC2_PUBLIC_IP>

# Create a table so Chartio has something to reflect.
sudo apt-get update
sudo apt-get install -y postgresql-client
psql -h <RDS_HOSTNAME> -p 5432 -d chartio -U chartio -c "CREATE TABLE foo(id int);" # password: chartiovpc

# Install and setup the Connection Client
sudo apt-get install -y python-pip
sudo pip install chartio
chartio_setup
```
