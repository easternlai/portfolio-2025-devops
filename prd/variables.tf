variable "env" {
  type    = string
  default = "prd"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "az_count" {
  type        = number
  default     = 1
  description = "The number of redundant AZs."

  #Prevents chosen AZ acount from exceeding total available. 
  validation {
    condition     = var.az_count <= length(local.available_AZs)
    error_message = "You have exceeded the number of available AZs."
  }
}

variable "jumpbox" {
  type        = bool
  default     = true
  description = "Creates jumpbox in public subnet to access DB server in private subnet."
}

variable "ecr_repo_frontend" {
  default = "856660075226.dkr.ecr.us-west-2.amazonaws.com/portfolio-frontend-2025:latest"
  type    = string
}

variable "ecr_repo_backend" {
  default = "856660075226.dkr.ecr.us-west-2.amazonaws.com/portfolio-2025:latest"
  type    = string
}
