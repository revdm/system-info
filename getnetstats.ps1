Get-NetAdapter | ForEach-Object {
    $adapterName = $_.Name
    $description = $_.InterfaceDescription
    $macAddress = $_.MacAddress
    $status = if ($_.Status -eq "Up") { "UP" } else { "DOWN" }
    $ipAddresses = (Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress) -join ", "
    $defaultGateway = (Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NextHop) -join ", "

    # Check for Wi-Fi frequency using netsh
    $wifiFrequency = if ($_.Name -match "Wi-Fi|Wireless") {
        try {
            $wifiDetails = netsh wlan show interfaces | Select-String -Pattern "Radio type|Channel" | Out-String
            if ($wifiDetails -match "Channel\s+:\s+(\d+)") {
                $channel = [int]$Matches[1]
                if ($channel -le 14) { "2.4 GHz" } else { "5 GHz" }
            } else {
                "(Unknown)"
            }
        } catch {
            "(Error fetching Wi-Fi frequency)"
        }
    } else {
        "(Not Wi-Fi)"
    }

    [PSCustomObject]@{
        Name            = $adapterName
        Description     = $description
        MACAddress      = $macAddress
        Status          = $status
        LinkSpeed       = $_.LinkSpeed
        IPAddress       = if ($ipAddresses -ne "") { $ipAddresses } else { "(None)" }
        DefaultGateway  = if ($defaultGateway -ne "") { $defaultGateway } else { "(None)" }
        WifiFrequency   = $wifiFrequency
    }
} | Format-Table -AutoSize

# Add SMB share information
Write-Host "`nSMB Shares:`n" -ForegroundColor Green
Get-SmbShare | ForEach-Object {
    [PSCustomObject]@{
        Name        = $_.Name
        Path        = $_.Path
        Description = $_.Description
        State       = if ($_.IsReadOnly) { "Read-Only" } else { "Read-Write" }
    }
} | Format-Table -AutoSize
