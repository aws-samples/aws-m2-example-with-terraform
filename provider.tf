// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = var.default_tags
  }
}