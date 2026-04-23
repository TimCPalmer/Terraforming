data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_mssql_server" "this" {
  name                = var.sql_server_name
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_automation_account" "this" {
  name                = var.automation_account_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_automation_runbook" "truncate" {
  name                    = "Invoke-SqlTruncation"
  location                = var.location
  resource_group_name     = data.azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  log_verbose             = true
  log_progress            = false
  runbook_type            = "PowerShell"
  description             = "Executes a T-SQL statement against ${var.target_database_name} using the account's system-assigned managed identity."

  content = file("${path.module}/runbook.ps1")

  tags = var.tags
}

resource "azurerm_automation_schedule" "truncate" {
  name                    = "sql-truncation"
  resource_group_name     = data.azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  frequency               = var.schedule_frequency
  interval                = var.schedule_interval
  timezone                = "Etc/UTC"
  start_time              = var.schedule_start_time
  description             = "Triggers the SQL truncation runbook."

  lifecycle {
    ignore_changes = [start_time]
  }
}

resource "azurerm_automation_job_schedule" "truncate" {
  resource_group_name     = data.azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  schedule_name           = azurerm_automation_schedule.truncate.name
  runbook_name            = azurerm_automation_runbook.truncate.name

  # Azure lowercases runbook parameter names, so keep these lowercase here
  # and in the runbook's param() block.
  parameters = {
    sqlserverfqdn = "${data.azurerm_mssql_server.this.name}.database.windows.net"
    databasename  = var.target_database_name
    sql           = var.truncation_sql
  }
}
