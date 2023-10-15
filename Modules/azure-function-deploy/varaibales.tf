variable "workload_name" {
  description = "A prefix for generating resource names"
  type        = string
}

variable "location" {
  description = "Azure region where resources should be created"
}

variable "SendGridApiKey" {
  description = "SendGrid Api Key for sending emails"
}

variable "sender_email" {
  description = "Sender email address"
}

variable "recipient_email" {
  description = "Recipient email address"
}