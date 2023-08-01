#usage
#.\Export-PrivateDNSRecords.ps1 -privateDnsSubscriptionId "00000000-0000-0000-0000-000000000000" -csvPath "c:\temp\pdns.csv"

param
(
    [Parameter(Mandatory = $true)]
    [string]$privateDnsSubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$csvPath
)

# Check if the CSV file already exists
if (Test-Path $csvPath) {
    Write-Error "The CSV file '$csvPath' already exists. Please specify a different file path or remove file and try again."
    return
}

# Authenticate to Azure
Write-Output "Authenticating to Azure..."
Connect-AzAccount

#Get the Azure subscription name
$subscriptionName = (Get-AzSubscription -SubscriptionId $privateDnsSubscriptionId).Name

# Set the Azure subscription context
Write-Output "Setting Azure subscription context to '$subscriptionName'..."
Set-AzContext -SubscriptionId $privateDnsSubscriptionId

# Get all Private DNS zones in the subscription
Write-Output "Getting all Private DNS zones in the subscription..."
$privateDnsZones = Get-AzPrivateDnsZone

# Create an array to store the DNS records
Write-Output "Creating an array to store the DNS records..."
$dnsRecords = @()

# Loop through each Private DNS zone
foreach ($privateDnsZone in $privateDnsZones) {
    # Get the Private DNS zone records
    Write-Output "Getting Private DNS zone records for zone '$($privateDnsZone.Name)'..."
    $privateDnsZoneRecords = Get-AzPrivateDnsRecordSet -ZoneName $privateDnsZone.Name -ResourceGroupName $privateDnsZone.ResourceGroupName

    # Loop through each Private DNS zone record
    foreach ($privateDnsZoneRecord in $privateDnsZoneRecords) {
        # Check if the Private DNS zone record is an A record
        if ($privateDnsZoneRecord.RecordType -eq 'A') {
            # Create a new DNS record object
            Write-Output "Creating a new DNS record object for record '$($privateDnsZoneRecord.Name)' in zone '$($privateDnsZoneRecord.ZoneName)'..."
            $dnsRecord = [PSCustomObject]@{
                Name = $privateDnsZoneRecord.Name
                Zone = $privateDnsZoneRecord.ZoneName
                Type = $privateDnsZoneRecord.RecordType
                Value = $privateDnsZoneRecord.records.ipv4address
            }

            # Add the DNS record object to the array
            Write-Output "Adding the DNS record object to the array..."
            $dnsRecords += $dnsRecord
        }
    }
}

# Export the DNS records to a CSV file
Write-Output "Exporting the DNS records to CSV file '$csvPath'..."
$dnsRecords | Export-Csv -Path $csvPath -NoTypeInformation

Write-Output "Done."