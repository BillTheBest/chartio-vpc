# VPC

resource "aws_vpc" "chartio-vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    tags {
        Name = "chartio-vpc"
    }
}


# Internet gateway

resource "aws_internet_gateway" "chartio-igw" {
    vpc_id = "${aws_vpc.chartio-vpc.id}"
}


# Subnets

resource "aws_subnet" "chartio-public-sn" {
    vpc_id = "${aws_vpc.chartio-vpc.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-west-1a"
    map_public_ip_on_launch = true
    # Ensure resources with public IPs are destroyed before the Internet
    # gateway.
    depends_on = ["aws_internet_gateway.chartio-igw"]
    tags {
        Name = "chartio-public-sn"
    }
}

resource "aws_subnet" "chartio-private-sn" {
    vpc_id = "${aws_vpc.chartio-vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-west-1b"
    map_public_ip_on_launch = false
    tags {
        Name = "chartio-private-sn"
    }
}


# Custom route table

resource "aws_route_table" "chartio-rt1" {
    vpc_id = "${aws_vpc.chartio-vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.chartio-igw.id}"
    }
    tags {
        Name = "chartio-rt1"
    }
}

resource "aws_route_table_association" "chartio-rta1" {
    subnet_id = "${aws_subnet.chartio-public-sn.id}"
    route_table_id = "${aws_route_table.chartio-rt1.id}"
}


# Security groups

resource "aws_security_group" "chartio-rds-sg" {
    name = "chartio-rds-sg"
    description = "chartio-vpc RDS security group"
    vpc_id = "${aws_vpc.chartio-vpc.id}"
    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        cidr_blocks = ["${aws_subnet.chartio-public-sn.cidr_block}"]
    }
}

resource "aws_security_group" "chartio-ec2-sg" {
    name = "chartio-ec2-sg"
    description = "chartio-vpc EC2 security group"
    vpc_id = "${aws_vpc.chartio-vpc.id}"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.YOUR_LOCAL_IP}/32"]
    }
    egress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


# RDS subnet group & instance

resource "aws_db_subnet_group" "chartio-dsg" {
    name = "chartio-dsg"
    description = "chartio-vpc subnet group"
    subnet_ids = [
        "${aws_subnet.chartio-public-sn.id}", "${aws_subnet.chartio-private-sn.id}"
    ]
}

resource "aws_db_instance" "chartio-rds" {
    identifier = "chartio"
    engine = "postgres"
    engine_version = "9.3.6"
    port = 5432
    instance_class = "db.t1.micro"
    allocated_storage = 5
    name = "chartio"
    username = "chartio"
    password = "chartiovpc"
    parameter_group_name = "default.postgres9.3"
    db_subnet_group_name = "${aws_db_subnet_group.chartio-dsg.name}"
    multi_az = false
    availability_zone = "${aws_subnet.chartio-private-sn.availability_zone}"
    publicly_accessible = false
    vpc_security_group_ids = ["${aws_security_group.chartio-rds-sg.id}"]
}


# EC2 instance

resource "aws_instance" "chartio-ec2" {
    instance_type = "t2.micro"
    ami = "ami-5c120b19"
    subnet_id = "${aws_subnet.chartio-public-sn.id}"
    security_groups = ["${aws_security_group.chartio-ec2-sg.id}"]
    key_name = "${var.AWS_KEYPAIR_NAME}"
    tags {
        "Name" = "chartio-${aws_subnet.chartio-public-sn.id}"
    }
}
