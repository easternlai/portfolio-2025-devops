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
