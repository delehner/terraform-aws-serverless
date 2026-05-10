variable "application_name" {
  type        = string
  description = "Application's name."
}

variable "environment" {
  type        = string
  description = "Environment where the resource is running."
}

variable "application_runtime" {
  type        = string
  default     = "provided.al2"
  description = "Application runtime."
}

variable "processor_architecture" {
  type        = string
  default     = "arm64"
  description = "Processor architecture."
}

variable "application_handler" {
  type        = string
  default     = "bootstrap"
  description = "Application handler."
}

variable "application_domain" {
  type        = string
  description = "The domain for the hosted zone."
}

variable "protocol_type" {
  type        = string
  default     = "HTTP"
  description = "Protocol type for the API Gateway."
}

variable "log_retention_in_days" {
  type        = number
  default     = 7
  description = "AWS Cloudwatch log retention in days."
}

variable "lambda_timeout" {
  type        = number
  default     = 30
  description = "Lambda timeout."
}

variable "concurrent_executions" {
  type        = number
  default     = -1
  description = "Number of Lambda concurrent executions."
}

variable "provisioned_concurrent_executions" {
  type        = number
  default     = 0
  description = "Number of Lambda provisioned concurrent executions."
}

variable "function_version" {
  type        = string
  default     = "1"
  description = "Lambda function version."
}

variable "health_check_enabled" {
  type        = bool
  default     = false
  description = "Flag that sets if health check will be active."
}

variable "health_check_path" {
  type        = string
  default     = "/health"
  description = "Health Check path for the application resource."
}

variable "health_check_threshold" {
  type        = string
  default     = "2"
  description = "Health Check threshold for the application resource."
}

variable "events" {
  type        = list(string)
  default     = []
  description = "List of events that the application emits."
}

variable "health_check_interval" {
  type        = string
  default     = "30"
  description = "Health Check interval for the application resource."
}

variable "enable_custom_domain_route53_record" {
  type        = bool
  default     = true
  description = "Create the Route53 alias record (api-<env>.<domain> → API GW). Set false when a downstream module owns the public hostname (e.g. CloudFront-fronted edge) and the registry record would collide."
}
