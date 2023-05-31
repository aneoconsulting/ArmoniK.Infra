locals {
  #add default values
  master_cluster  = merge(var.master_cluster, { "ami" = coalesce(var.master_cluster.ami, data.aws_ami.redhat_8_6.image_id) })
  workers_cluster = { for k, v in var.workers_cluster : k => merge(v, { "ami" = coalesce(v.ami, data.aws_ami.redhat_8_6.image_id) }) }

}

# Get latest CentOS Linux 7.x AMI in the current region.
# as of today 2023/05/22 it is : "CentOS 7.9.2009 x86_64"
data "aws_ami" "centos7" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "name"
    values = ["CentOS-7-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "is-public"
    values = [true]
  }
}




data "aws_ami" "redhat_8_6" {
  most_recent = true
  owners      = ["309956199498"]
  filter {
    name   = "name"
    values = ["RHEL-8.6.0*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "is-public"
    values = [true]
  }
}