# variable "access_key" { #Todo: uncomment the default value and add your access key.
#   description = "Access key to AWS console"
#   default     = ""
# }
 
# variable "secret_key" { #Todo: uncomment the default value and add your secert key.
#   description = "Secret key to AWS console"
#   default     = ""
# }

variable "vpc_name" {
  default = "hellobaghub-k8s" #the jump host to access k8s cluster
}

variable "cidr_block" {
  
  default = "10.0.0.0/24"
}

variable "ami_key_pair_name" { #Todo: uncomment the default value and add your pem key pair name. Hint: don't write '.pem' exction just the key name
  default = "k8s-key-us-east-1"
}
variable "number_of_worker" {
  description = "number of worker instances to be join on cluster."
  default     = 2
}

variable "region" {
  description = "The region zone on AWS"
  default     = "us-east-1" #The zone I selected is us-east-1, if you change it make sure to check if ami_id below is correct.
}

variable "ami_id" {
  description = "The AMI to use"
  default     = "ami-04b4f1a9cf54c11d0" #Ubuntu 24.04
}

variable "instance_type" {
  default = "t2.medium" #the best type to start k8s with it,
}

variable "jump_host_instance_type" {
  default = "t2.micro" #the jump host to access k8s cluster
}