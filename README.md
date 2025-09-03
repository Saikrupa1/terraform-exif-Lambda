# Terraform EXIF Removal Lambda

## Overview
This project contains Terraform code to deploy:
- 2 S3 buckets (source and destination)
- Lambda function to remove EXIF metadata from images
- S3 trigger and IAM roles

## Files
- main.tf → Terraform configuration
- lambda_function.py → Python code for Lambda
- lambda.zip → zipped Lambda function (with dependencies)

## Deployment
1. Install Terraform.
2. Run:
   ```bash
   terraform init
   terraform apply -auto-approve
