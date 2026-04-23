# Scheduled Azure SQL row truncation

Scheduled T-SQL against a private-endpoint Azure SQL database, driven from an
Azure DevOps pipeline running on self-hosted agents. No new Azure resources
required.

## Files

| File | Purpose |
|---|---|
| `azure-pipelines.yml` | Pipeline definition: cron schedule + single PowerShell step that runs the SQL via MI/SP access token. |
| `sql/grant_pipeline_user.sql` | One-off T-SQL to authorise the service connection's principal inside the target database. |

## Prerequisites

- Self-hosted ADO agent pool with network line-of-sight to the SQL server's private endpoint (DNS resolves `<server>.database.windows.net` to the PE private IP).
- An ADO service connection to the target Azure subscription (workload identity federation preferred).
- An Entra (AAD) admin set on the SQL logical server — needed once to create the Entra-authenticated user in the database.

## Placeholders to fill in

**`azure-pipelines.yml`**

- `pool.name` — your self-hosted pool name.
- `azureSubscription` — your ADO service connection name.
- `sqlServerFqdn` — e.g. `sql-prod-eus.database.windows.net`.
- `databaseName` — target database.
- `truncationSql` — the T-SQL to run (defaults to `TRUNCATE TABLE dbo.MyTable;`).
- `schedules.cron` — defaults to `0 2 * * *` (02:00 UTC daily).

**`sql/grant_pipeline_user.sql`**

- Replace `<service-connection-principal>` with the display name of the service principal behind your service connection. Find it in ADO under *Project Settings → Service connections → \<your connection\> → Manage Service Principal*, or in Entra as the App registration's display name.

## End-to-end steps

1. **Fill in the placeholders** in `azure-pipelines.yml` and commit to `main`.
2. **Create the pipeline** in ADO: *Pipelines → New pipeline → Azure Repos Git → select this repo → Existing Azure Pipelines YAML file → `/azure-pipelines.yml`*. Save (don't run yet).
3. **Authorise the service-connection principal in the database.** As the SQL server's Entra admin, from somewhere that can reach the private endpoint (one of the agents works):
   ```
   sqlcmd -S <server>.database.windows.net -d <database> -G \
          -U <entra-admin-upn> -i sql/grant_pipeline_user.sql
   ```
4. **Smoke-test.** In ADO, hit *Run pipeline*. Confirm the job prints `Done.` and check row counts in the target database.
5. Leave it; it will run on the cron schedule. `always: true` ensures it fires regardless of commit activity.

## Notes

- Authentication uses `Get-AzAccessToken` against `https://database.windows.net/` and passes the token to `Invoke-Sqlcmd -AccessToken`. No SQL password exists anywhere.
- The pipeline installs the `SqlServer` PowerShell module on first run if the agent doesn't have it cached. Subsequent runs reuse the cached module.
- If you switch from `TRUNCATE TABLE` to `DELETE ... WHERE ...`, drop the `GRANT ALTER ON SCHEMA::dbo` line from the grant script — `db_datawriter` is sufficient for `DELETE`.
- TRUNCATE requires `ALTER` on the table (or schema) in addition to write rights, which is why the grant script includes it by default.
