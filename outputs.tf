// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Output the URL to our deployed application
output "application_url" {
  value = "http://${data.aws_lb.m2_lb.dns_name}:${var.port}/PlanetsDemo-web-1.0.0/"
}
