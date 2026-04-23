param(
    [Parameter(Mandatory = $true)] [string] $SqlServerFqdn,
    [Parameter(Mandatory = $true)] [string] $DatabaseName,
    [Parameter(Mandatory = $true)] [string] $Sql
)

$ErrorActionPreference = 'Stop'

Write-Output "Authenticating with the Automation account's system-assigned managed identity..."
Disable-AzContextAutosave -Scope Process | Out-Null
$null = Connect-AzAccount -Identity

Write-Output "Acquiring an access token for https://database.windows.net/ ..."
$accessToken = Get-AzAccessToken -ResourceUrl 'https://database.windows.net/'
$token = if ($accessToken.Token -is [securestring]) {
    [System.Net.NetworkCredential]::new('', $accessToken.Token).Password
} else {
    $accessToken.Token
}

Write-Output "Connecting to $SqlServerFqdn / $DatabaseName ..."
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=tcp:$SqlServerFqdn,1433;Initial Catalog=$DatabaseName;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$conn.AccessToken = $token
$conn.Open()

try {
    $cmd = $conn.CreateCommand()
    $cmd.CommandTimeout = 0
    $cmd.CommandText = $Sql
    Write-Output "Executing: $Sql"
    $rows = $cmd.ExecuteNonQuery()
    Write-Output "Completed. Rows affected: $rows"
}
finally {
    $conn.Close()
}
