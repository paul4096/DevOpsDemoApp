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