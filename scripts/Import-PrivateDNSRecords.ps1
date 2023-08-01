#usage
#.\Import-PrivateDNSRecords.ps1 -dnsServerName "dns01" -csvPath "c:\temp\pdns.csv"

param
(
    [Parameter(Mandatory = $true)]
    [string]$dnsServerName,
    [Parameter(Mandatory = $true)]
    [string]$csvPath
)


# Import the DNS records from the CSV file
Write-Output "Importing DNS records from CSV file..."
$dnsRecords = Import-Csv -Path $csvPath

# Loop through each DNS record
foreach ($dnsRecord in $dnsRecords) {
    # Get the DNS zone
    Write-Output "Getting DNS zone '$($dnsRecord.Zone)'..."
    $dnsZone = Get-DnsServerZone -Name $dnsRecord.Zone -ErrorAction SilentlyContinue

    # Check if the DNS zone exists
    if (!$dnsZone) {
        # Create the DNS zone
        Write-Output "DNS zone '$($dnsRecord.Zone)' does not exist. Creating zone..."
        Add-DnsServerPrimaryZone -Name $dnsRecord.Zone -DynamicUpdate Secure -ReplicationScope Forest
    }

    # Check if the A record already exists
    Write-Output "Checking if A record '$($dnsRecord.Name)' already exists in zone '$($dnsRecord.Zone)'..."
    $aRecordExists = Get-DnsServerResourceRecord -ZoneName $dnsRecord.Zone -Name $dnsRecord.Name -RRType A -ErrorAction SilentlyContinue

    if ($aRecordExists) {
        # The A record already exists, so skip adding the record
        Write-Error "A record '$($dnsRecord.Name)' already exists in zone '$($dnsRecord.Zone)'. Skipping record creation for $($dnsRecord.Name)."
    }
    else {
        # Check if the IP address is already in use
        Write-Output "Checking if IP address '$($dnsRecord.Value)' is already in use..."
        $ipExists = Get-DnsServerResourceRecord -ZoneName $dnsRecord.Zone -RRType A -ErrorAction SilentlyContinue | Where-Object {$_.RecordData.IPv4Address -eq $dnsRecord.Value}

        if ($ipExists) {
            # The IP address is already in use, so skip adding the record
            Write-Error "IP address '$($dnsRecord.Value)' is already in use in zone '$($dnsRecord.Zone)'. Skipping record creation for $($dnsRecord.Name)."
        }
        else {
            # Add the DNS A record to the DNS zone
            Write-Output "Adding DNS A record '$($dnsRecord.Name)' with value '$($dnsRecord.Value)' to zone '$($dnsRecord.Zone)'..."
            Add-DnsServerResourceRecordA -Name $dnsRecord.Name -IPv4Address $dnsRecord.Value -ZoneName $dnsRecord.Zone -ComputerName $dnsServerName

            # Wait for 5 seconds before processing the next record
            Start-Sleep -Seconds 5
        }
    }
}