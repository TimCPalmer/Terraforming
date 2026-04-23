output "automation_account_name" {
  description = "Name of the created Automation account. This is also the display name of its managed identity in Entra ID."
  value       = azurerm_automation_account.this.name
}

output "automation_identity_principal_id" {
  description = "Object (principal) ID of the Automation account's system-assigned managed identity."
  value       = azurerm_automation_account.this.identity[0].principal_id
}

output "sql_server_fqdn" {
  value = "${data.azurerm_mssql_server.this.name}.database.windows.net"
}

output "grant_sql_user_statements" {
  description = "T-SQL to run inside the target database as the SQL server's Entra admin to authorise the Automation managed identity."
  value       = <<-SQL
    -- Connect to [${var.target_database_name}] on ${data.azurerm_mssql_server.this.name}.database.windows.net
    -- as the Entra (AAD) admin of the server, then run:

    CREATE USER [${azurerm_automation_account.this.name}] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER [${azurerm_automation_account.this.name}];
    ALTER ROLE db_datawriter ADD MEMBER [${azurerm_automation_account.this.name}];
    -- TRUNCATE TABLE needs ALTER on the schema (or the table). Drop this if you only DELETE:
    GRANT ALTER ON SCHEMA::dbo TO [${azurerm_automation_account.this.name}];
  SQL
}
