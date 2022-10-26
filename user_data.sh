#!/bin/bash
# Use this for your data (script from top to bottom)
# install httpd (Linux 2 version)
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo “This Website is Build by Terraform 2.0 $(hostname -f)”>/var/www/html/index.html
