terraform {
    required_version = ">= 0.13.0"
}


locals {
    cmd = "${path.module}/scripts/spot-account-aws"
    account_id = lookup(data.external.account.result,"account_id","Fail")
    external_id = data.external.external_id.result["external_id"]
    name = var.name == null ? data.aws_iam_account_alias.current.account_alias : var.name

}

data "aws_iam_account_alias" "current" {}

# Create a random string
resource "random_id" "role" {
    byte_length = 8
}

# Create the AWS Role for Spot
resource "aws_iam_role" "spot"{
    name = "SpotRole-${random_id.role.hex}"
    provisioner "local-exec" {
        # Without this set-cloud-credentials fails
        command = "sleep 10"
    }
    assume_role_policy = <<-EOT
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                "Effect": "Allow",
                "Principal": {
                    "AWS": "arn:aws:iam::922761411349:root"
                },
                "Action": "sts:AssumeRole",
                "Condition": {
                    "StringEquals": {
                    "sts:ExternalId": "${local.external_id}"
                    }
                }
                }
            ]
        }
    EOT
}

# Create the Policy
resource "aws_iam_policy" "spot" {
    name        = "Spot-Policy-${random_id.role.hex}"
    path        = "/"
    description = "Allow Spot.io to manage resources"

    policy = templatefile(var.policy_file == null ? "${path.module}/spot_policy.json" : var.policy_file, {})
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "spot" {
    role       = aws_iam_role.spot.name
    policy_arn = aws_iam_policy.spot.arn
}

# Call Spot API to create the Spot Account
resource "null_resource" "account" {
    triggers = {
        cmd = "${path.module}/scripts/spot-account-aws"
        name = local.name
    }
    provisioner "local-exec" {
        interpreter = ["/bin/bash", "-c"]
        command = "${self.triggers.cmd} create ${self.triggers.name}"
    }

    provisioner "local-exec" {
        when = destroy
        interpreter = ["/bin/bash", "-c"]
        command = <<-EOT
            ID=$(${self.triggers.cmd} get --filter=name=${self.triggers.name} --attr=account_id) &&\
            ${self.triggers.cmd} delete "$ID"
        EOT
    }
}

# Retrieve the Spot Account ID
data "external" "account" {
    depends_on = [null_resource.account]
    program = [
        local.cmd,
        "get",
        "--filter=name=${local.name}"
    ]
}

# Retrieve the Spot Account autogenerated external-id
data "external" "external_id" {
    depends_on = [null_resource.account]
    program = [
        local.cmd,
        "create-external-id",
        local.account_id
    ]
}

# Link the Role ARN to the Spot Account
resource "null_resource" "account_association" {
    depends_on = [aws_iam_role.spot]
    provisioner "local-exec" {
        interpreter = ["/bin/bash", "-c"]
        command = "${local.cmd} set-cloud-credentials ${local.account_id} ${aws_iam_role.spot.arn}"
    }
}