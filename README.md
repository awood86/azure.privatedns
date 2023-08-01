# Azure Private DNS Export/Import

This repo has been created to simplify the export of Private DNS Zones from Azure and to import them into an On-Premise DNS Infrastructure


## Export-PrivateDNSRecords.ps1

This PowerShell script exports all Azure Private DNS records from an Azure Subscription to a CSV file.

### Usage

The script will first authenticate with your Azure login credentials. The parameter `-privateDnsSubscriptionId` sets the subscription where all your Azure Private DNS Zones are held, the `-csvPath` parameter sets where the csv export will be

```powershell
.\scripts\Export-PrivateDNSRecords.ps1 -privateDnsSubscriptionId "00000000-0000-0000-0000-000000000000" -csvPath "c:\temp\pdns.csv"
```

Parameters
privateDnsSubscriptionId: The ID of the Azure subscription containing the Private DNS zones.
csvPath: The path to the CSV file to export the DNS records to.
Output
The script exports the following fields for each DNS record:

ZoneName: The name of the Private DNS zone.
Name: The name of the DNS record.
Value: The IP address of the DNS record.
The CSV file can be opened in Microsoft Excel or another spreadsheet program.

Output
The script creates a csv ready for import into a DNS server


## Import-PrivateDNSRecords.ps1

This PowerShell script imports Azure Private DNS records and creates Forward Lookup Zones from a CSV file

### Usage

To use the script ensure you have line of sight to the DNS server and permissions to write to the DNS Server. Then, run the script with the `-dnsServerName` and `-csvPath` parameters.
The script will check if the Forward Lookup Zone has been created for the records and if it hasn't it will create them, it will then check if the IP has been used for the A record and then check the A record name, if neither of these have been created it will proceed to create the record. If not, you will receive an error advising to check these and the records won't be created

```powershell
.\scripts\Import-PrivateDNSRecords.ps1 -dnsServerName "dns01" -csvPath "c:\temp\pdns.csv"
```

Parameters
dnsServerName: The name of the DNS server to add the DNS records to.
csvPath: The path to the CSV file containing the DNS records to import.
CSV File Format
The CSV file should contain the following columns:

Zone: The name of the Private DNS zone.
Name: The name of the DNS record.
Value: The IP address of the DNS record.

Output
The script adds the DNS records to the specified DNS server.