provider "aws" {
  region = var.region
}

resource "aws_api_gateway_rest_api" "gateway" {
  body = jsonencode({
  "openapi" : "3.0.1",
  "info" : {
    "title" : "${var.api_name}",
    "version" : "2022-08-21T16:31:14Z"
  },
  "servers" : [ {
    "url" : "https://je2h9zpwz3.execute-api.${var.region}.amazonaws.com/{basePath}",
    "variables" : {
      "basePath" : {
        "default" : "/QA"
      }
    }
  } ],
  "paths" : {
    "/invoke" : {
      "post" : {
        "responses" : {
          "200" : {
            "description" : "200 response",
            "content" : {
              "application/json" : {
                "schema" : {
                  "$ref" : "#/components/schemas/Empty"
                }
              }
            }
          }
        },
        "x-amazon-apigateway-integration" : {
          "type" : "aws",
          "httpMethod" : "POST",
          "uri" : "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.lambda_name}:${var.env}/invocations",
          "responses" : {
            "default" : {
              "statusCode" : "200"
            }
          },
          "passthroughBehavior" : "when_no_match",
          "contentHandling" : "CONVERT_TO_TEXT"
        }
      }
    }
  },
  "components" : {
    "schemas" : {
      "Empty" : {
        "title" : "Empty Schema",
        "type" : "object"
      }
    }
  }
})

  name = var.api_name
}

resource "aws_api_gateway_deployment" "QA" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_deployment" "PROD" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "QA_stage" {
  deployment_id = aws_api_gateway_deployment.QA.id
  rest_api_id   = aws_api_gateway_rest_api.gateway.id
  stage_name    = "QA"
}

resource "aws_api_gateway_stage" "PROD_stage" {
  deployment_id = aws_api_gateway_deployment.PROD.id
  rest_api_id   = aws_api_gateway_rest_api.gateway.id
  stage_name    = "PROD"
}

resource "aws_api_gateway_usage_plan" "api_usage_plan" {
  name         = "api_usage_plan"
  description  = "Useage plan for api_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.gateway.id
    stage  = aws_api_gateway_stage.QA_stage.stage_name
  }

  api_stages {
    api_id = aws_api_gateway_rest_api.gateway.id
    stage  = aws_api_gateway_stage.PROD_stage.stage_name
  }

  quota_settings {
    limit  = 100
    offset = 0
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 10
    rate_limit  = 30
  }
}

resource "aws_lambda_permission" "lambda_permission_QA" {
    statement_id  = "AllowGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = "${var.lambda_name}:QA"
    principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "lambda_permission_PROD" {
    statement_id  = "AllowGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = "${var.lambda_name}:PROD"
    principal     = "apigateway.amazonaws.com"
}

data "aws_secretsmanager_secret" "secrets" {
    name = "prod/${var.api_name}/api_key"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}

resource "aws_api_gateway_api_key" "api_key" {
  name = "api_key"
  value = nonsensitive(data.aws_secretsmanager_secret_version.current.secret_string)
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_usage_plan.id
}