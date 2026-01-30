###################################################################################################################
################################################## Banco de Dados #################################################
###################################################################################################################


######################################################## RDS ######################################################

####################
#### RDS - MySQL ####
####################

module "db_parameter_mysql" {
  source               = "./modulos/Banco_de_dados/prod/parameter-group"
  parameter_group_name = var.parameter_group_name_mysql
  family               = var.family_mysql
  tags                 = var.tags_parameter_group_mysql
}

module "rds_mysql" {
  source                = "./modulos/Banco_de_dados/prod/rds"
  identifier            = var.identifier_mysql
  db_name               = var.db_name_mysql
  instance_class        = var.instance_class_mysql
  engine                = var.engine_mysql
  engine_version        = var.engine_version_mysql
  license_model         = var.license_model_mysql
  username              = var.username_mysql
  password              = var.password_mysql
  port                  = var.port_mysql
  allocated_storage     = var.allocated_storage_mysql
  max_allocated_storage = var.max_allocated_storage_mysql
  storage_type          = var.storage_type_mysql
  #skip_final_snapshot                   = var.final_snapshot
  character_set_name        = var.character_set_name_mysql
  final_snapshot_identifier = "rds-final" //${md5(timestamp())}"
  final_snapshot            = var.final_snapshot_mysql
  storage_encrypted         = var.storage_encrypted_mysql
  publicly_accessible       = var.publicly_accessible_mysql
  apply_immediately         = var.apply_immediately_mysql
  backup_retention_period   = var.backup_retention_period_mysql
  backup_window             = var.backup_window_mysql
  cloudwatch_logs_exports   = var.cloudwatch_logs_exports_mysql
  multi_az                  = var.multi_az_mysql
  db_subnet_group_name      = module.subnet_group_rds.db_subnet_group_name
  security_groups_ids = [
    module.security_group_rds.security_group_id
  ]
  parameter_group_name                  = module.db_parameter_mysql.parameter_group_name
  option_group_name                     = var.option_group_mysql
  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot_mysql
  performance_insights                  = var.performance_insights_mysql
  performance_insights_retention_period = var.performance_insights_retention_period_mysql
  allow_major_version_upgrade           = var.allow_major_version_upgrade_mysql
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade_mysql
  monitoring_interval                   = var.monitoring_interval_mysql
  maintenance_window                    = var.maintenance_window_mysql
  deletion_protection                   = var.deletion_protection_mysql
  delete_automated_backups              = var.delete_automated_backups_mysql
  monitoring_role_arn                   = var.monitoring_role_arn_mysql
  iam_database_authentication           = var.iam_database_authentication_mysql
  customer_owned_ip                     = var.customer_owned_ip_mysql
  ca_cert_identifier                    = var.ca_cert_identifier_mysql

  tags = var.tags_rds_mysql
}

############ Subnet Group - RDS #############

module "subnet_group_rds" {
  source = "./modulos/Banco_de_dados/prod/db-subnet-group"
  name   = var.name_subnet_group_rds
  subnet_ids = [
    module.subnet_private.private_subnet_ids_by_name["Private-Subnet-AZ-2a"],
    module.subnet_private.private_subnet_ids_by_name["Private-Subnet-AZ-2b"]
  ]
  tags = var.tags_subnet_group_rds
}
