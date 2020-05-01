#####-------------Google-provider-credentials----------
variable "provider_credential" {
  default = "C:\\Users\\vrethinavelu\\Downloads\\service_account.json"
}

variable "project_id_name" {
  default = "sinuous-anvil-273703"
  
}
###################### Variables for VPC #######################

variable "virtual_name" {
  default = "my-vpc"  
}

################### Subnet-01 -webserver
variable "subnet_web" {
  default = "subnet-01"  
}
variable "ip_subnet_web" {
  default = "10.10.10.0/24"
}
variable "reg_subnet_web" {
  default ="us-west1"
}

################### Subnet-02 -appserver #############################
variable "subnet_app" {
  default = "subnet-02"  
}
variable "ip_subnet_app" {
  default = "10.10.20.0/24"
}
variable "reg_subnet_app" {
  default ="us-west1"
}

######################################################## NAT #############################################

variable "router_name_web" {
  default = "my-router"
}

variable "nat_name" {
  default = "my-router-nat"
  
}


###################### Variables for compute Engine ########################## 
variable "vmmachine_type" {
  default = "n1-standard-1"  
}

variable "image_name" {
  default = "debian-cloud/debian-9"
}

