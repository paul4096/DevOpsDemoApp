terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "demo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { #skanowanie obrazu przed wystawieniem teraz jest darmowe ale trzeba śledzić czy z powrotem nie będzie płatne
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "keep_last_20" {
  repository = aws_ecr_repository.demo.name
  policy     = <<POLICY
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 20 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 20
      },
      "action": { "type": "expire" }
    }
  ]
}
POLICY
} # Policy jest jsonem i lepiej by było to przekazać jako json encode

output "ecr_repo_url" {
  value = aws_ecr_repository.demo.repository_url
}