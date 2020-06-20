function Set-NetDnsServer {

<#
    .SYNOPSIS
        Set Computer Objects' DNS server(s)

    .DESCRIPTION
        Set a specific network adapter's DNS server(s) for Computer(s) or a Computer Object.
        Can accept pipeline input for -ComputerName and meant to run alongside the Query-NetDnsServer
        command to gather information for a specific network adapter.

    .NOTES
        Author: Greg Powers
#>

    [CmdletBinding (
    )]

    Param (
        # ComputerName --
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true
        )]
        [System.Object]
        $ComputerName,

        # NetworkAdapter --
        [Parameter(
            Mandatory=$true
        )]
        [System.String]
        $NetworkAdapter,

        # PrimaryDnsServer --
        [Parameter(
            Mandatory=$true
        )]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [System.String]
        $PrimaryDnsServer,

        # SecondaryDnsServer --
        [Parameter(
            Mandatory=$false
        )]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [System.String]
        $SecondaryDnsServer = $null
    )

    Begin {
        $NEWDnsServers = $PrimaryDnsServer,$SecondaryDnsServer
        $NetworkAdapterIndex = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $Computer -ErrorAction Ignore | ? {$_.Description -eq "$NetworkAdapter"} | select -ExpandProperty InterfaceIndex
        $GetDnsClientsbyIndex = Get-DnsClientServerAddress -AddressFamily IPv4 | ? {$_.InterfaceIndex -eq $NetworkAdapterIndex} | select -ExpandProperty ServerAddresses

        <#
            Using $GetDnsClientsbyIndex, set the values for the current Primary/Secondary DNS servers.
        #>

        if (!($GetDnsClientsbyIndex)) {
            $PrimaryServer = "Not Set"
            $SecondaryServer = "Not Set"
        }
        elseif ($GetDnsClientsbyIndex.Count -eq 1) {
            $PrimaryServer = $GetDnsClientsbyIndex
            $SecondaryServer = "Not Set"
        }
        else {
            $PrimaryServer = $GetDnsClientsbyIndex[0]
            $SecondaryServer = $GetDnsClientsbyIndex[1]
        }

        $NEWPrimaryDnsServer = $PrimaryDnsServer,$SecondaryServer
    }
    Process { # OPEN Process
        foreach ($Computer in $ComputerName) { # OPEN foreach
            if ($PrimaryDnsServer -notlike $null -and $SecondaryDnsServer -notlike $null) { # OPEN if -- Both -Primary AND -Secondary have been SET!                
                try {
                    <#
                        Focusing on the current Primary DNS server and the value entered for $PrimaryDnsServer by the user,
                        check if the current DNS server matches the value provided for -PrimaryDnsServer.
                    #>

                    if ($PrimaryServer -ne $PrimaryDnsServer) {
                        Write-Host ''
                        Write-Host "Primary DNS Server is currently set to" -NoNewline
                        Write-Host -ForegroundColor Yellow " [$PrimaryServer]" -NoNewline
                        Write-Host ". Updating the entry..."
                        Start-Sleep -Seconds 1
                    }
                    elseif ($PrimaryServer -eq $PrimaryDnsServer) {
                        Write-Host ''
                        Write-Warning -Message "The Primary DNS Server for [$ComputerName] on Network [$NetworkAdapter] is already set to the value provided [$PrimaryDnsServer]..."
                        Start-Sleep -Seconds 1
                    }

                    <#
                        Focusing on the current Secondary DNS server and the value entered for $SecondaryDnsServer by the user,
                        check if the current DNS server matches the value provided for -SecondaryDnsServer.
                    #>

                    if ($SecondaryServer -ne $SecondaryDnsServer) {
                        Write-Host ''
                        Write-Host "Secondary DNS Server is currently set to" -NoNewline
                        Write-Host -ForegroundColor Yellow " [$SecondaryServer]" -NoNewline
                        Write-Host ". Updating the entry..."
                        Start-Sleep -Seconds 1
                    }
                    elseif ($SecondaryServer -eq $SecondaryDnsServer) {
                        Write-Host ''
                        Write-Warning -Message "The Secondary DNS Server for [$ComputerName] on Network [$NetworkAdapter] is already set to the value provided [$SecondaryDnsServer]..."
                        Start-Sleep -Seconds 1
                    }

                    <#
                        If the current DNS servers do NOT match the Primary and Secondary parameter values, proceed updating the DNS
                        servers to their new values specified by the user.
                    #>

                    if (!(Get-DnsClientServerAddress -InterfaceIndex 12 -AddressFamily IPv4 | ? {($_.ServerAddresses[0] -eq $PrimaryDnsServer) -and ($_.ServerAddresses[1] -eq $SecondaryDnsServer)})) {
                        Set-DnsClientServerAddress -InterfaceIndex $NetworkAdapterIndex -ServerAddresses $NEWDnsServers
                        
                        Write-Host ''
                        Write-Host "Gathering updated DNS server information for" -NoNewline
                        Write-Host -ForegroundColor Yellow " [$ComputerName]" -NoNewline
                        Write-Host " on Network" -NoNewline
                        Write-Host -ForegroundColor Yellow " [$NetworkAdapter]" -NoNewline
                        Write-Host "..."
                        Write-Host ''
                        Start-Sleep -Seconds 3
                        
                        $GetDnsClientsbyIndex = $null
                        $GetDnsClientsbyIndex = Get-DnsClientServerAddress -AddressFamily IPv4 | ? {$_.InterfaceIndex -eq $NetworkAdapterIndex} | select -ExpandProperty ServerAddresses

                        $GetDnsClientsbyIndex

                        Start-Sleep -Seconds 1
                    }

                    if (!(Get-DnsClientServerAddress -InterfaceIndex 12 -AddressFamily IPv4 | ? {($_.ServerAddresses[0] -eq $PrimaryDnsServer) -and ($_.ServerAddresses[1] -eq $SecondaryDnsServer)})) {
                        throw("DNS not properly set!")
                    }
                }
                catch {
                    Write-Host -ForegroundColor Red "Error Type:"
                    $PSItem.GetType().FullName
                    Write-Host ''
    
                    Write-Host -ForegroundColor Red "Error Position:"
                    $PSItem.InvocationInfo.PositionMessage.Split("+")[0].Trim()
                    Write-Host ''
    
                    Write-Host -ForegroundColor Red "Error Line:"
                    $PSItem.InvocationInfo.Line.Trim()
                    Write-Host ''

                    Write-Host -ForegroundColor Red "Error Message:"
                    $PSItem.Exception.Message
                    Write-Host ''
                    Start-Sleep -Seconds 3

                    EXIT
                }
            } # CLOSE if -- Both -Primary AND -Secondary have been SET!
            elseif ($PrimaryDnsServer -notlike $null -and $SecondaryDnsServer -like $null) { # OPEN elseif -- -Primary ONLY has been SET!        
                try {
                    <#
                        Focusing on the current Primary DNS server and the value entered for $PrimaryDnsServer by the user,
                        check if the current DNS server matches the value provided for -PrimaryDnsServer.
                    #>

                    if ($PrimaryServer -ne $PrimaryDnsServer) {
                        Write-Host ''
                        Write-Host "Primary DNS Server is currently set to" -NoNewline
                        Write-Host -ForegroundColor Yellow " [$PrimaryServer]" -NoNewline
                        Write-Host ". Updating the entry..."
                        Start-Sleep -Seconds 1
                    }
                    elseif ($PrimaryServer -eq $PrimaryDnsServer) {
                        Write-Host ''
                        Write-Warning -Message "The Primary DNS Server for [$ComputerName] on Network [$NetworkAdapter] is already set to the value provided [$PrimaryDnsServer]..."
                        Start-Sleep -Seconds 1
                    }

                    <#
                        Because the -SecondaryDnsServer paramater was left blank, we are only reporting on what is currently set as
                        the Secondary DNS server. This may be a valid server address or $null, in which case "Not Set" wil be the
                        returned value.
                    #>

                    Write-Host ''
                    Write-Host "Secondary DNS Server is currently set to" -NoNewline
                    Write-Host -ForegroundColor Yellow " [$SecondaryServer]" -NoNewline
                    Write-Host ". Value was not specificed during command execution. No updates will be made..."
                    Start-Sleep -Seconds 1

                    <#
                        If the current DNS servers do NOT match the Primary and Secondary parameter values, proceed updating the DNS
                        servers to their new values specified by the user.
                    #>

                    if (!(Get-DnsClientServerAddress -InterfaceIndex 12 -AddressFamily IPv4 | ? {($_.ServerAddresses[0] -eq $PrimaryDnsServer) -and ($_.ServerAddresses[1] -eq $SecondaryServer)})) {
                        Set-DnsClientServerAddress -InterfaceIndex $NetworkAdapterIndex -ServerAddresses $NEWPrimaryDnsServer
                        
                        Write-Host ''
                        Write-Host "Gathering updated DNS server information for" -NoNewline
                        Write-Host -ForegroundColor Yellow " [$ComputerName]" -NoNewline
                        Write-Host " on Network" -NoNewline
                        Write-Host -ForegroundColor Yellow " [$NetworkAdapter]" -NoNewline
                        Write-Host "..."
                        Write-Host ''
                        Start-Sleep -Seconds 3
                        
                        $GetDnsClientsbyIndex = $null
                        $GetDnsClientsbyIndex = Get-DnsClientServerAddress -AddressFamily IPv4 | ? {$_.InterfaceIndex -eq $NetworkAdapterIndex} | select -ExpandProperty ServerAddresses

                        $GetDnsClientsbyIndex

                        Start-Sleep -Seconds 1
                    }

                    if (!(Get-DnsClientServerAddress -InterfaceIndex 12 -AddressFamily IPv4 | ? {($_.ServerAddresses[0] -eq $PrimaryDnsServer) -and ($_.ServerAddresses[1] -eq $SecondaryServer)})) {
                        throw("DNS not properly set!")
                    }
                }
                catch {
                    Write-Host -ForegroundColor Red "Error Type:"
                    $PSItem.GetType().FullName
                    Write-Host ''
    
                    Write-Host -ForegroundColor Red "Error Position:"
                    $PSItem.InvocationInfo.PositionMessage.Split("+")[0].Trim()
                    Write-Host ''
    
                    Write-Host -ForegroundColor Red "Error Line:"
                    $PSItem.InvocationInfo.Line.Trim()
                    Write-Host ''

                    Write-Host -ForegroundColor Red "Error Message:"
                    $PSItem.Exception.Message
                    Write-Host ''
                    Start-Sleep -Seconds 3

                    EXIT
                }
            }  # OPEN elseif -- -Primary ONLY has been SET!
        } # CLOSE foreach
    } # CLOSE Process
    End {
    }
}