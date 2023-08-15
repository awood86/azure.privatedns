#usage
#.\Check-PrivateDNSRecords.ps1 -csvPath "c:\temp\pdns.csv"

param
(
    [Parameter(Mandatory = $true)]
    [string]$csvPath
)

# Import the CSV
Write-output "Importing CSV"
$csv = Import-Csv -Path $csvPath

# Check the DNS Records from CSV
Write-output "Checking DNS Records resolve to IP Address in CSV"

foreach ($record in $csv)
{
    $recordName = $record.Name
    $recordValue = $record.Value
    $recordZone = $record.Zone

    if ($recordZone -eq "privatelink.vaultcore.azure.net")
    {
        $recordZone = "vault.azure.net"
    }
    elseif ($recordZone -ne "privatelink.adf.azure.com" -and $recordZone -ne "privatelink.purviewstudio.azure.com" -and $recordName -notlike "*ab-pod01*")
    {
        $recordZone = $recordZone.Replace("privatelink.", "")
    }

    $dnsRecord = Resolve-DnsName -Name "$recordName.$recordZone"

    if ($dnsRecord.IPAddress -contains $recordValue)
    {
        Write-Host "DNS Record $recordName.$recordZone resolves to $recordValue" -ForegroundColor Green
    }
    else
    {
        Write-Host "DNS Record $recordName.$recordZone does not resolve to $recordValue" -ForegroundColor Red
    }
}