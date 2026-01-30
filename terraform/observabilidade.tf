# ==========================================================
# SERVICE DISCOVERY (Cloud Map)
# ==========================================================

resource "aws_service_discovery_private_dns_namespace" "observability" {
  name        = "observability.local"
  description = "Private DNS namespace for observability services"
  vpc         = module.vpc_app.vpc_id
}

resource "aws_service_discovery_service" "prometheus" {
  name = "prometheus"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.observability.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.observability.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# ==========================================================
# CLOUDWATCH LOG GROUPS
# ==========================================================

resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/ecs/prometheus"
  retention_in_days = 30

  tags = {
    Name        = "prometheus-logs"
    Environment = "observability"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/grafana"
  retention_in_days = 30

  tags = {
    Name        = "grafana-logs"
    Environment = "observability"
    ManagedBy   = "Terraform"
  }
}

# ==========================================================
# SEGURANÇA (Security Groups)
# ==========================================================

# SG do Prometheus: Precisa acessar o Backend e ser acessado pelo Grafana
resource "aws_security_group" "prometheus_sg" {
  name        = "prometheus-sg"
  description = "Security Group for Prometheus"
  vpc_id      = module.vpc_app.vpc_id

  # Saída para o Backend (Scraping) e Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prometheus-sg"
  }
}

# Regra de ingress separada para evitar referência circular
resource "aws_security_group_rule" "prometheus_from_grafana" {
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.prometheus_sg.id
  source_security_group_id = aws_security_group.grafana_sg.id
  description              = "Allow Grafana to access Prometheus"
}

resource "aws_security_group_rule" "ecs_backend_from_prometheus" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = module.security_group_ecs.security_group_id
  source_security_group_id = aws_security_group.prometheus_sg.id
  description              = "Allow Prometheus to scrape backend metrics"
}

# SG do Grafana: Precisa ser acessado pelo ALB (ou público para teste)
resource "aws_security_group" "grafana_sg" {
  name        = "grafana-sg"
  description = "Security Group for Grafana"
  vpc_id      = module.vpc_app.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Acesso Web ao Grafana (porta 3000)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Idealmente, restrinja ao seu IP ou ALB
  }
}

# ==========================================================
# PROMETHEUS (ECS Task & Service)
# ==========================================================

resource "aws_ecs_task_definition" "prometheus_task" {
  family                   = "prometheus-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::618889059366:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "618889059366.dkr.ecr.us-east-2.amazonaws.com/prometheus:latest" # Use a imagem que criamos no Passo A
      essential = true
      portMappings = [
        {
          containerPort = 9090
          hostPort      = 9090
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.prometheus.name
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "prometheus"
        }
      }
    }
  ])

  depends_on = [aws_cloudwatch_log_group.prometheus]
}

resource "aws_ecs_service" "prometheus_service" {
  name            = "prometheus-service"
  cluster         = module.ecs_cluster.cluster_id # Referência ao seu cluster existente
  task_definition = aws_ecs_task_definition.prometheus_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.subnet_private.private_subnet_id
    security_groups  = [aws_security_group.prometheus_sg.id]
    assign_public_ip = false
  }

  # Service Discovery - Permite que o Grafana encontre o Prometheus por DNS
  service_registries {
    registry_arn = aws_service_discovery_service.prometheus.arn
  }
}

# ==========================================================
# GRAFANA (ECS Task & Service)
# ==========================================================

resource "aws_ecs_task_definition" "grafana_task" {
  family                   = "grafana-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::618889059366:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = "618889059366.dkr.ecr.us-east-2.amazonaws.com/grafana:latest" # Imagem oficial
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        { name = "GF_SECURITY_ADMIN_PASSWORD", value = "admin" } # Mude isso em produção!
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.grafana.name
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "grafana"
        }
      }
    }
  ])

  depends_on = [aws_cloudwatch_log_group.grafana]
}

resource "aws_ecs_service" "grafana_service" {
  name            = "grafana-service"
  cluster         = module.ecs_cluster.cluster_id
  task_definition = aws_ecs_task_definition.grafana_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.subnet_public.public_subnet_id # Publique se quiser acesso direto (ou Privada + ALB)
    security_groups  = [aws_security_group.grafana_sg.id]
    assign_public_ip = true # True se estiver na subnet pública para facilitar o acesso
  }
}