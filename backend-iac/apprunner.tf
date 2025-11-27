# aws_apprunner_service.apprunner:
resource "aws_apprunner_service" "apprunner" {
    arn                            = "arn:aws:apprunner:us-east-1:335360747232:service/inf2006rds/39d31690e3cd4750ac40fe699be58428"
    auto_scaling_configuration_arn = "arn:aws:apprunner:us-east-1:335360747232:autoscalingconfiguration/DefaultConfiguration/1/00000000000000000000000000000001"
    id                             = "arn:aws:apprunner:us-east-1:335360747232:service/inf2006rds/39d31690e3cd4750ac40fe699be58428"
    service_id                     = "39d31690e3cd4750ac40fe699be58428"
    service_name                   = "inf2006rds"
    service_url                    = "9qjpd4xue2.us-east-1.awsapprunner.com"
    status                         = "RUNNING"
    tags                           = {}
    tags_all                       = {}

    health_check_configuration {
        healthy_threshold   = 1
        interval            = 10
        path                = "/"
        protocol            = "TCP"
        timeout             = 5
        unhealthy_threshold = 5
    }

    instance_configuration {
        cpu               = "1024"
        instance_role_arn = null
        memory            = "2048"
    }

    network_configuration {
        ip_address_type = "IPV4"

        egress_configuration {
            egress_type       = "DEFAULT"
            vpc_connector_arn = null
        }

        ingress_configuration {
            is_publicly_accessible = true
        }
    }

    observability_configuration {
        observability_configuration_arn = null
        observability_enabled           = false
    }

    source_configuration {
        auto_deployments_enabled = false

        authentication_configuration {
            access_role_arn = null
            connection_arn  = "arn:aws:apprunner:us-east-1:335360747232:connection/kaichuin/25cc70abb8fb4c11a43c75be964506b2"
        }

        code_repository {
            repository_url   = "https://github.com/LohKaiChuin/inf2006"
            source_directory = "/"

            code_configuration {
                configuration_source = "API"

                code_configuration_values {
                    build_command                 = "npm install"
                    port                          = "3000"
                    runtime                       = "NODEJS_18"
                    runtime_environment_secrets   = {}
                    runtime_environment_variables = {
                        "DB_HOST"    = "inf2006proj.c2recquoobti.us-east-1.rds.amazonaws.com"
                        "DB_NAME"    = "users"
                        "DB_PASS"    = "INF2006Year2Tri1"
                        "DB_USER"    = "admin"
                        "JWT_SECRET" = "YOUR_SECRET_KEY"
                        "Port"       = "3000"
                    }
                    start_command                 = "npm start"
                }
            }

            source_code_version {
                type  = "BRANCH"
                value = "main"
            }
        }
    }
}
