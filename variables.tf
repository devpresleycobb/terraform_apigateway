variable "env" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["QA", "PROD"], var.env)
    error_message = "Allowed values for input_parameter are \"QA\", \"PROD\"."
  }
}

variable "lambda_name" {
    type        = string
    description = "The lambda to be invoked"
}

variable "account_id" {
    type = string
    description = "The account ID the resources will be deployed to"
}

variable "region" {
  type = string
  description = "Aws region"
}

variable "api_name" {
  type = string
  description = "Name of the API Gateway"
}