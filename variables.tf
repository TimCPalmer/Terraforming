variable "resource_group_name" {
  description = "Resource group that contains the existing Azure SQL Server. The Automation account will be created here too."
  type        = string
}

variable "location" {
  description = "Azure region for the Automation account (e.g. eastus). Does not need to match the SQL server's region."
  type        = string
}

variable "sql_server_name" {
  description = "Short name of the existing Azure SQL logical server (without .database.windows.net)."
  type        = string
}

variable "target_database_name" {
  description = "Name of the existing database on the server that rows will be truncated from."
  type        = string
}

variable "automation_account_name" {
  description = "Name of the Azure Automation account to create. This string also becomes the display name of the managed identity in Entra ID."
  type        = string
  default     = "aa-sql-truncation"
}

variable "truncation_sql" {
  description = "T-SQL executed on every schedule tick. Use a DELETE ... WHERE for retention-style purges, or TRUNCATE TABLE for a full wipe."
  type        = string
  default     = "TRUNCATE TABLE dbo.MyTable;"
}

variable "schedule_frequency" {
  description = "Schedule frequency: one of Hour, Day, Week, Month."
  type        = string
  default     = "Day"

  validation {
    condition     = contains(["Hour", "Day", "Week", "Month"], var.schedule_frequency)
    error_message = "schedule_frequency must be Hour, Day, Week or Month."
  }
}

variable "schedule_interval" {
  description = "Number of frequency units between runs (e.g. every 1 Day, every 6 Hour)."
  type        = number
  default     = 1
}

variable "schedule_start_time" {
  description = "RFC3339 UTC timestamp for the first run. Azure requires this to be at least 5 minutes in the future on the very first apply; subsequent applies ignore changes to this value."
  type        = string
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
