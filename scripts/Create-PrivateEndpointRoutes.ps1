#### Written by: Andrew Wood
#### Date: 2023-08-18
#### Purpose: This script will create a route in a route table for each Private Endpoint in the subscription. The route will be a /32 route to the Private Endpoint's IP address, and the route name will be the Private Endpoint's DNS name. This script is intended to be run on a schedule, such as once per day, to ensure that the route table is kept up to date with any new Private Endpoints that have been created since the last time the script was run.
#### Usage: .\Create-PrivateEndpointRoutes.ps1 -subscriptionName "My Subscription" -routetableresourceGroupName "My Route Table Resource Group" -routeTableName "My Route Table"


param(
    [Parameter(Mandatory=$true)]
    [string]$subscriptionName,
    [Parameter(Mandatory=$true)]
    [string]$routetableresourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$routeTableName
)

# Authenticate to Azure
Write-Output "Authenticating to Azure..."
Connect-AzAccount

# Set the Azure subscription context
Write-Output "Setting Azure subscription context to '$subscriptionName'..."
Set-AzContext -SubscriptionName $subscriptionName

# Get all Private DNS zones in the subscription
Write-Output "Getting all Private DNS zones in the subscription..."
$privateDnsZones = Get-AzPrivateDnsZone

# Create an array to store the IPv4 addresses and DNS names
Write-Output "Creating an array to store the IPv4 addresses and DNS names..."
$ipv4AddressesAndNames = @()

# Loop through each Private DNS zone
foreach ($privateDnsZone in $privateDnsZones) {
    # Get the Private DNS zone records
    Write-Output "Getting Private DNS zone records for zone '$($privateDnsZone.Name)'..."
    $privateDnsZoneRecords = Get-AzPrivateDnsRecordSet -ZoneName $privateDnsZone.Name -ResourceGroupName $privateDnsZone.ResourceGroupName

    # Loop through each Private DNS zone record
    foreach ($privateDnsZoneRecord in $privateDnsZoneRecords) {
        # Check if the Private DNS zone record is an A record
        if ($privateDnsZoneRecord.RecordType -eq 'A') {
            # Add the IPv4 address and DNS name to the array
            $dnsName = "pe-" + $privateDnsZoneRecord.Name.Replace(".", "") + "-" + $privateDnsZone.name
            Write-Output "Adding IPv4 address '$($privateDnsZoneRecord.records.ipv4address)' and DNS name '$dnsName' to the array..."
            $ipv4AddressesAndNames += @{ipv4Address=$privateDnsZoneRecord.records.ipv4address; dnsName=$dnsName}
        }
    }
}

# Get the existing route table
Write-Output "Getting the existing route table '$routeTableName'..."
$routeTable = Get-AzRouteTable -Name $routeTableName -ResourceGroupName $routetableresourceGroupName

# Loop through each IPv4 address and create a route for it as a /32 in the route table, using the DNS name as the route config name
foreach ($ipv4AddressAndName in $ipv4AddressesAndNames) {
    $routeConfig = Get-AzRouteConfig -Name $ipv4AddressAndName.dnsName -RouteTable $routeTable -ErrorAction SilentlyContinue
    if ($routeConfig -eq $null) {
        Write-Output "Creating route for DNS name '$($ipv4AddressAndName.dnsName)' and IPv4 address '$($ipv4AddressAndName.ipv4Address)' in route table '$routeTableName'..."
        Add-AzRouteConfig -Name $ipv4AddressAndName.dnsName -AddressPrefix "$($ipv4AddressAndName.ipv4Address)/32" -NextHopType VirtualAppliance -NextHopIpAddress "10.14.0.68" -RouteTable $routeTable
    }
    else {
        Write-Output "Route for DNS name '$($ipv4AddressAndName.dnsName)' already exists in route table '$routeTableName'. Skipping..."
    }
}

Set-AzRouteTable -RouteTable $routeTable

Write-Output "Done."