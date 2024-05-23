# Define the input and output file paths
$inputFile = "~\rdp\vm-ip-addresses.conf"
$outputFile = "~s\rdp\RDCMan.rdg"

# Read the server list
$servers = Get-Content $inputFile

# Initialize the XML content with proper formatting
$xmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<RDCMan programVersion="2.93" schemaVersion="3">
  <file>
    <credentialsProfiles />
    <properties>
      <expanded>True</expanded>
      <name>workers</name>
    </properties>
    <group>
      <properties>
        <name>workers</name>
        <expanded>True</expanded>
      </properties>
"@

# Iterate through each server and add it to the XML content
foreach ($server in $servers) {
    $parts = $server -split ":", 2
    if ($parts.Length -eq 2) {
        $hostname = $parts[0].Trim()
        $ipaddress = $parts[1].Trim()

        $xmlContent += @"
      <server>
        <properties>
          <name>$hostname</name>
          <displayName>$hostname</displayName>
          <connectionSettings>
            <serverName>$ipaddress</serverName>
          </connectionSettings>
          <logonCredentials inherit="None">
            <userName>qumulo</userName>
            <domain></domain>
            <password>P@55w0rd123!</password>
          </logonCredentials>
        </properties>
      </server>
"@
    } else {
        Write-Output "Skipping invalid entry: $server"
    }
}

# Close the XML structure
$xmlContent += @"
    </group>
  </file>
  <connected />
  <favorites />
  <recentlyUsed />
</RDCMan>
"@

# Save the XML content to the output file
$xmlContent | Out-File -Encoding UTF8 $outputFile

Write-Output "RDCMan.rdg file has been created at $outputFile"
