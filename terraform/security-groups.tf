module "security_group_ecs" {
  source        = "./modulos/Conectividade/prod/security-group"
  name          = var.name_sg_ecs
  description   = var.description_sg_ecs
  vpc_id        = module.vpc_app.vpc_id
  ingress_rules = concat(
    jsondecode(file("${path.module}/security_rules/rules-sg-ecs.json")).ingress,
    [
      {
        description     = "Acesso do ALB"
        from_port       = 3000
        to_port         = 3000
        protocol        = "tcp"
        security_groups = [module.security_group_alb.security_group_id]
      }
    ]
  )
  egress_rules  = jsondecode(file("${path.module}/security_rules/rules-sg-ecs.json")).egress
  tags          = var.tags_sg_ecs
}

module "security_group_alb" {
  source        = "./modulos/Conectividade/prod/security-group"
  name          = var.name_sg_alb
  description   = var.description_sg_alb
  vpc_id        = module.vpc_app.vpc_id
  ingress_rules = jsondecode(file("${path.module}/security_rules/rules-sg-alb.json")).ingress
  egress_rules  = jsondecode(file("${path.module}/security_rules/rules-sg-alb.json")).egress
  tags          = var.tags_sg_alb
}

module "security_group_rds" {
  source      = "./modulos/Conectividade/prod/security-group"
  name        = var.name_sg_rds_ecs
  description = var.description_rds_ecs
  vpc_id      = module.vpc_app.vpc_id
  ingress_rules = [
    {
      description     = "Acesso das subnets privadas (MySQL)"
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      cidr_blocks     = values(var.subnet_cidr_blocks_private)
    }
  ]
  egress_rules = [
    {
      description      = "Saida para internet"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  ]
  tags = var.tags_rds_ecs
}
