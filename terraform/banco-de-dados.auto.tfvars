#######################################################################################################################
# RDS #########################################################################################
# ---------------------------------------------------------------------------------------------------------------------

#########################
#### RDS - MySQL  #######
#########################

#### RDS OPTION GROUP ####

engine_name_mysql          = "mysql"
major_engine_version_mysql = "8.0"
option_group_name_mysql    = "og-mysql"
option_description_mysql   = "Option Group para o RDS (mysql)"

#### RDS PARAMETER GROUP ####

parameter_group_name_mysql = "pg-mysql"
family_mysql               = "mysql8.0"
tags_parameter_group_mysql = {
  Name        = "PARAMETER-GROUP-MYSQL"
  Owner       = "Rodrigo Gomes"
  Project     = "Desafios EZOps"
  Environment = "test"
}

#### RDS INSTANCE ####

identifier_mysql                            = "rds-organizer"
db_name_mysql                               = "training_app"
instance_class_mysql                        = "db.t3.micro"
engine_mysql                                = "mysql"
engine_version_mysql                        = "8.0"
license_model_mysql                         = null
username_mysql                              = "master"
password_mysql                              = "0z1kvWWJi1gE"
port_mysql                                  = 3306
allocated_storage_mysql                     = 10
max_allocated_storage_mysql                 = null
storage_type_mysql                          = "gp2"
final_snapshot_mysql                        = false
storage_encrypted_mysql                     = false
character_set_name_mysql                    = null
publicly_accessible_mysql                   = false
apply_immediately_mysql                     = true
backup_retention_period_mysql               = 3
backup_window_mysql                         = "04:00-06:00"
cloudwatch_logs_exports_mysql               = ["error", "general", "slowquery"]
multi_az_mysql                              = false
copy_tags_to_snapshot_mysql                 = true
performance_insights_mysql                  = false
performance_insights_retention_period_mysql = 0
allow_major_version_upgrade_mysql           = false
auto_minor_version_upgrade_mysql            = true
monitoring_interval_mysql                   = 0
maintenance_window_mysql                    = "sun:06:05-sun:06:35"
deletion_protection_mysql                   = false
delete_automated_backups_mysql              = false
monitoring_role_arn_mysql                   = null
iam_database_authentication_mysql           = false
customer_owned_ip_mysql                     = false
ca_cert_identifier_mysql                    = "rds-ca-rsa2048-g1"
option_group_mysql                          = "default:mysql-8-0"

tags_rds_mysql = {
  Name        = "RDS-MYSQL"
  Owner       = "Rodrigo Gomes"
  Project     = "Desafios EZOps"
  Environment = "test"
}

#### RDS SUBNET GROUP ####

name_subnet_group_rds = "subnet-group-rds"
tags_subnet_group_rds = {
  Name        = "SUBNET GROUP RDS"
  Owner       = "Rodrigo Gomes"
  Project     = "Desafios EZOps"
  Environment = "test"
}