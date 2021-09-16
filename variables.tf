variable "region" {
  type = string
  default = "ap-northeast-1"
}

variable "ac_key" {
  type = string
  default = ""
}

variable "sc_key" {
  type = string
  default = ""
}

variable "project" {
  type = string
  default = "DigitalCheckList"
}

variable "instance" {
  type = string
  default = "t2.medium"
}

variable "nat-router-instance" {
  type = string
  default = "t2.micro"
}

variable "pub-key-path" {
  type = string
  default = "/home/valentyn/SS/DigitalCheckList_AWS/aws-ssh-key.pub"
}

variable "prv-key-path" {
  type = string
  default = "/home/valentyn/SS/DigitalCheckList_AWS/aws-ssh-key"
}

variable "vpc_range" {
  type = string
  default = "10.100.0.0/16"
}

variable "vpc-public-subnet-range" {
  type = string
  default = "10.100.50.0/24"
}

variable "vpc-private-subnet-range" {
  type = string
  default = "10.100.100.0/24"
}

variable "vpc-all-ips" {
  type = string
  default = "0.0.0.0/0"
}

/* ---------------------------------- Bash ENV ---------------------------------- */

variable "mongodb_password" {
  type = string
  default = "Myadmin111"
}

variable "db_user" {
  type = string
  default = "Administrator"
}

variable "db_mail" {
  type = string
  default = "myadmin@mail.ua"
}

variable "nd_env" {
  type = string
  default = "production"
}

variable "token" {
  type = string
  default = "mystrongjwt"
}

variable "wport" {
  type = string
  default = "5000"
}

variable "mg_urif" {
  type = string
  default = "mongodb://"
}

variable "mg_uril" {
  type = string
  default = ":27017/app"
}

variable "sip" {
  type = string
  default = "`curl http://ident.me`"
}

variable "bitbucket_aws_s3" {
  type = string
  default = "DigitalCheckList-Bucket"
}

locals {
  mongo_ip="${var.mg_urif}${aws_instance.mongodb-server.private_ip}${var.mg_uril}"
}