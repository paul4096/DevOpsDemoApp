variable "aws_region" {
    description = "Region dla AWS"
    type = string
    default = "eu-central-1"  
}

variable "ecr_repo_name" {
    description = "ECR repository name"
    type = string
    default = "demo-app-pkl"  
}

variable "app_image" {
    type = string
    default = "504913911906.dkr.ecr.eu-central-1.amazonaws.com/demo-app-pkl:10"
  
}