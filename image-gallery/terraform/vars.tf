variable "REGION" {
  default = "eu-central-1"
  type    = string
}

variable "image_gallery" {
  type    = string
  default = "static-image-gallery-654"
}

variable "image_storage" {
  type    = string
  default = "image-storage-6552"
}

variable "lambda_role" {
  type    = string
  default = "image-processing-lambda"
}

variable "function_name" {
  type    = string
  default = "lambda-function"
}

variable "api_name" {
  type    = string
  default = "image-processing-api"
}