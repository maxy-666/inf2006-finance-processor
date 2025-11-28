resource "aws_apprunner_service" "apprunner" {
  service_name = "inf2006rds"

  source_configuration {
    auto_deployments_enabled = false

    authentication_configuration {
      connection_arn = "arn:aws:apprunner:us-east-1:335360747232:connection/kaichuin/25cc70abb8fb4c11a43c75be964506b2"
    }

    code_repository {
      repository_url = "https://github.com/LohKaiChuin/inf2006"
      
      source_code_version {
        type  = "BRANCH"
        value = "main"
      }

      code_configuration {
        configuration_source = "API"

        code_configuration_values {
          runtime       = "NODEJS_18"
          build_command = "npm install"
          start_command = "npm start"
          port          = "3000"

          runtime_environment_variables = {
            "DB_HOST"    = "inf2006proj.c2recquoobti.us-east-1.rds.amazonaws.com"
            "DB_NAME"    = "users"
            "DB_PASS"    = "INF2006Year2Tri1"
            "DB_USER"    = "admin"
            "JWT_SECRET" = "YOUR_SECRET_KEY"
            "Port"       = "3000"
          }
        }
      }
    }
  }

  network_configuration {
    egress_configuration {
      egress_type = "DEFAULT"
    }
    ingress_configuration {
      is_publicly_accessible = true
    }
  }

  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }

  health_check_configuration {
    healthy_threshold   = 1
    interval            = 10
    path                = "/"
    protocol            = "TCP"
    timeout             = 5
    unhealthy_threshold = 5
  }
}