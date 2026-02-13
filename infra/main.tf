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


resource "aws_ecs_cluster" "this" {
  name = "pkl-demo-cluster"
}

# Logi
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/demo-app-pkl"
  retention_in_days = 7
}

# IAM dla ECS Task Execution
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { 
      type = "Service" 
      identifiers = ["ecs-tasks.amazonaws.com"] 
      }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "pkl-demo-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach" {
  role      = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Security Group dla taska (otwieramy 8080 na świat albo tylko na Twoje IP)
resource "aws_security_group" "ecs_app_sg" {
  name   = "pkl-demo-ecs-app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # dla labu; produkcyjnie ogranicz
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "demo-app-pkl"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = "demo-app-pkl"
    image     = var.app_image
    essential = true
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  name            = "pkl-demo-app-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]   # Twój public subnet
    security_groups  = [aws_security_group.ecs_app_sg.id]
    assign_public_ip = true
  }
}


output "ecr_repo_url" {
  value = aws_ecr_repository.demo.repository_url
}