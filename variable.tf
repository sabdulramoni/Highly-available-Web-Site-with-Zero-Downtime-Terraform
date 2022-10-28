variable "aws_region" {
    default = "us-east-2"
}


variable "port_list" {
    description = "Lists of port to open for Webserver"
    type = list(any)
    default = ["80", "443"]
  
}


variable "instance_size" {
    description = "EC2 Instance Size to provison"
    Type = string
    default = "t2.micro"
  
}