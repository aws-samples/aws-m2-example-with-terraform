// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0


variable "region" {
  type = string
}

variable "profile" {
  type    = string
  default = null
}

variable "name" {
  type    = string
  default = "terraform-m2-demo"
}

variable "engine_type" {
  type    = string
  default = "bluage"
}

variable "engine_version" {
  type    = string
  default = "3.9.0"
}

variable "instance_type" {
  type    = string
  default = "M2.m5.large"
}

variable "my_public_ip" {
  type = string
}

variable "port" {
  type    = string
  default = "8196"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR for VPC"
}

variable "azs" {
  type        = number
  default     = 2
  description = "Number of availability zones to deploy in"
  validation {
    condition     = var.azs >= 2
    error_message = "Mainframe Modernization requires at least two availability zones"
  }
}

variable "default_tags" {
  type = map(string)
  default = {
    project = "mainframe-modernization-demo"
  }
}