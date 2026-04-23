-- One-off grant script. Run once per target database, as the SQL server's
-- Entra (AAD) admin. Example invocation from a host that can reach the
-- server (e.g. one of your self-hosted agents):
--
--   sqlcmd -S <server>.database.windows.net -d <database> -G \
--          -U <entra-admin-upn> -i grant_pipeline_user.sql
--
-- Replace <service-connection-principal> with the display name of the
-- service principal / managed identity that backs your ADO service
-- connection (visible under Project Settings -> Service connections ->
-- <your connection> -> Manage Service Principal, or in Entra as the App
-- registration's display name).

CREATE USER [<service-connection-principal>] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [<service-connection-principal>];
ALTER ROLE db_datawriter ADD MEMBER [<service-connection-principal>];

-- Only needed if you use TRUNCATE TABLE (not DELETE). TRUNCATE requires
-- ALTER on the schema or the table.
GRANT ALTER ON SCHEMA::dbo TO [<service-connection-principal>];
