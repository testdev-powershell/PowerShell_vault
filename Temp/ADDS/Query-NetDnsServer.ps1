function Query-NetDnsServer {

<#
    .SYNOPSIS
        Get Computer Objects' DNS server(s)

    .DESCRIPTION
        Query the network DNS server(s) for individual Computer(s) or Computer Object from Active Directory.

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
            ValueFromPipeline=$true,
            ParameterSetName="nonDefault"
        )]
        [System.Object]
        $ComputerName,

        # Default --
        [Parameter(
            Position=0,
            Mandatory=$true,
            ParameterSetName="Default"
        )]
        [switch]
        $Default,

        # SearchBase --
        [Parameter(
            Position=1,
            Mandatory=$false,
            ValueFromPipeline=$true,
            ParameterSetName="Default"
        )]
        [System.String]
        $SearchBase = (Get-ADDomain).DistinguishedName
    )

    Begin {
        if ($SearchBase -ne (Get-ADDomain).DistinguishedName) {
            try {
                $Computers = Get-ADComputer -Filter {Enabled -eq $true} -SearchBase $SearchBase -Properties * | Where-Object {$_.OperatingSystem -match "Windows"}
            }
            catch {
                Write-Warning -Message "The string [$SearchBase] does not match an AD Organizational Unit's DistinguishedName..."
                Break
            }
        }
        $Date = (Get-Date).ToString("M-d-yyy")
        $computerList = "$env:HOMEPATH\Documents\computers_DnsQuery_$($Date).txt"
        $Computers = Get-ADComputer -Filter {Enabled -eq $true} -SearchBase $SearchBase -Properties * | Where-Object {$_.OperatingSystem -match "Windows"}
    }
    Process { # OPEN Process
        if ($ComputerName) { # OPEN if
            try {
                foreach ($Computer in $ComputerName) {
                    $NetworksDns = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Computer -ErrorAction Stop | ? {($_.DHCPEnabled -eq $false)}
 
                    foreach ($n in $NetworksDns) {
                        $DnsServers = $n.DNSServerSearchOrder
                        $NetworkName = $n.Description
                        $IsDHCPEnabled = $n.DHCPEnabled

                        if (!($DnsServers)) {
                            $PrimaryServer = "Not Set"
                            $SecondaryServer = "Not Set"
                        }
                        elseif ($DnsServers.Count -eq 1) {
                            $PrimaryServer = $DnsServers[0]
                            $SecondaryServer = "Not Set"
                        }
                        else {
                            $PrimaryServer = $DnsServers[0]
                            $SecondaryServer = $DnsServers[1]
                        }

                        $OutputObj = New-Object -TypeName psobject

                        $OutputObj | Add-Member -MemberType NoteProperty -Name NetworkName -Value $NetworkName
                        $OutputObj | Add-Member -MemberType NoteProperty -Name IsDHCPEnabled -Value $IsDHCPEnabled
                        $OutputObj | Add-Member -MemberType NoteProperty -Name PrimaryDnsServer -Value $PrimaryServer
                        $OutputObj | Add-Member -MemberType NoteProperty -Name SecondaryDnsServer -Value $SecondaryServer

                        Write-Host ''
                        Write-Host "Gathering network DNS information for" -NoNewline
                        Write-Host -ForegroundColor Yellow " [$Computer]" -NoNewline
                        Write-Host "..."
                        Start-Sleep -Seconds 1
    
                        $OutputObj | Format-Table -AutoSize
                    }
                }
            }
            catch {
                Write-Host ''
                Write-Warning -Message "Oops... Something went wrong!"
                Write-Host ''
    
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
            } 
        }
        else { # OPEN else
            <#
            Check to see if $computerList exists. If not, create the file before continuing on.
            #>

            if ($Default) { # OPEN if ($Default)
                if ($SearchBase -ne (Get-ADDomain).DistinguishedName) { # OPEN if ($Searchbase)
                    $Date = (Get-Date).ToString("M-d-yyy")
                    $computerListSB = "$env:HOMEPATH\Documents\computers_DnsQuery_$($SearchBase)_$($Date).txt"

                    if (!(Test-Path $computerListSB)) {
                        Write-Host ''
                        Write-Host -ForegroundColor Yellow "[$computerListSB]" -NoNewline
                        Write-Host " does NOT exist! Attempting to create the file..."
                        Write-Host ''
                        Start-Sleep -Seconds 1

                        try {
                            New-Item -ItemType File -Path $computerListSB -Force
                            Write-Host ''

                            foreach ($Computer in $Computers) {
                                if (Test-Connection -ComputerName $Computer.Name -Count 1 -Quiet -ErrorAction Ignore) {
                                    if (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Computer.Name -ErrorAction Ignore | ? {$_.DHCPEnabled -eq $false}) {
                                        $Computer.Name | Out-File $computerListSB -Append
                                    }
                                }
                            }

                            Write-Host "Using Computers from" -NoNewline
                            Write-Host -ForegroundColor Yellow " [$computerListSB]" -NoNewline
                            Write-Host "..."
                            Write-Host ''
                            Start-Sleep -Seconds 1
                        }
                        catch {
                            Write-Warning -Message "Oops... Something went wrong!"
                            Write-Host ''
    
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

                            Pause
                            EXIT
                        }
                    }
                    else {
                        Write-Host ''
                        Write-Host -ForegroundColor Yellow "[$computerListSB]" -NoNewline
                        Write-Host " already exists!"
                        Write-Host ''
                        Write-Host "Using Computers from" -NoNewline
                        Write-Host -ForegroundColor Yellow " [$computerListSB]" -NoNewline
                        Write-Host "..."
                        Write-Host ''
                        Start-Sleep -Seconds 1
                    }

                    try {
                        foreach ($Computer in (Get-Content -Path $computerListSB)) {
                            try {
                                $NetworksDns = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Computer -ErrorAction Stop | ? {($_.DHCPEnabled -eq $false)}
 
                                foreach ($n in $NetworksDns) {
                                    $DnsServers = $n.DNSServerSearchOrder
                                    $NetworkName = $n.Description
                                    $IsDHCPEnabled = $n.DHCPEnabled

                                    if (!($DnsServers)) {
                                        $PrimaryServer = "Not Set"
                                        $SecondaryServer = "Not Set"
                                    }
                                    elseif ($DnsServers.Count -eq 1) {
                                        $PrimaryServer = $DnsServers[0]
                                        $SecondaryServer = "Not Set"
                                    }
                                    else {
                                        $PrimaryServer = $DnsServers[0]
                                        $SecondaryServer = $DnsServers[1]
                                    }

                                    $OutputObj = New-Object -TypeName psobject

                                    $OutputObj | Add-Member -MemberType NoteProperty -Name NetworkName -Value $NetworkName
                                    $OutputObj | Add-Member -MemberType NoteProperty -Name IsDHCPEnabled -Value $IsDHCPEnabled
                                    $OutputObj | Add-Member -MemberType NoteProperty -Name PrimaryDnsServer -Value $PrimaryServer
                                    $OutputObj | Add-Member -MemberType NoteProperty -Name SecondaryDnsServer -Value $SecondaryServer

                                    Write-Host ''
                                    Write-Host "Gathering network DNS information for" -NoNewline
                                    Write-Host -ForegroundColor Yellow " [$Computer]" -NoNewline
                                    Write-Host "..."
                                    Start-Sleep -Seconds 1
    
                                    $OutputObj | Format-Table -AutoSize
                                }
                            }
                            catch {
                                Write-Host ''
                                Write-Warning -Message "Oops... Something went wrong!"
                                Write-Host ''
    
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
                            }
                        }
                    }
                    catch {
                        Write-Host ''
                        Write-Warning -Message "Oops... Something went wrong!"
                        Write-Host ''
    
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
                    }
                } # CLOSE if ($Searchbase)
                else { # OPEN else ($Default (non-$Searchbase)
                    if (!(Test-Path $computerList)) {
                        Write-Host ''
                        Write-Host -ForegroundColor Yellow "[$computerList]" -NoNewline
                        Write-Host " does NOT exist! Attempting to create the file..."
                        Write-Host ''
                        Start-Sleep -Seconds 1

                        try {
                            New-Item -ItemType File -Path $computerList -Force
                            Write-Host ''

                            foreach ($Computer in $Computers) {
                                if (Test-Connection -ComputerName $Computer.Name -Count 1 -Quiet -ErrorAction Ignore) {
                                    if (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Computer.Name -ErrorAction Ignore | ? {$_.DHCPEnabled -eq $false}) {
                                        $Computer.Name | Out-File $computerList -Append
                                    }
                                }
                            }

                            Write-Host "Using Computers from" -NoNewline
                            Write-Host -ForegroundColor Yellow " [$computerList]" -NoNewline
                            Write-Host "..."
                            Write-Host ''
                            Start-Sleep -Seconds 1
                        }
                        catch {
                            Write-Warning -Message "Oops... Something went wrong!"
                            Write-Host ''
    
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

                            Pause
                            EXIT
                        }
                    }
                    else {
                        Write-Host ''
                        Write-Host -ForegroundColor Yellow "[$computerList]" -NoNewline
                        Write-Host " already exists!"
                        Write-Host ''
                        Write-Host "Using Computers from" -NoNewline
                        Write-Host -ForegroundColor Yellow " [$computerList]" -NoNewline
                        Write-Host "..."
                        Write-Host ''
                        Start-Sleep -Seconds 1
                    }

                    try {
                        foreach ($Computer in (Get-Content -Path $computerList)) {
                            try {
                                $NetworksDns = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Computer -ErrorAction Stop | ? {($_.DHCPEnabled -eq $false)}
 
                                foreach ($n in $NetworksDns) {
                                    $DnsServers = $n.DNSServerSearchOrder
                                    $NetworkName = $n.Description
                                    $IsDHCPEnabled = $n.DHCPEnabled

                                    if (!($DnsServers)) {
                                        $PrimaryServer = "Not Set"
                                        $SecondaryServer = "Not Set"
                                    }
                                    elseif ($DnsServers.Count -eq 1) {
                                        $PrimaryServer = $DnsServers[0]
                                        $SecondaryServer = "Not Set"
                                    }
                                    else {
                                        $PrimaryServer = $DnsServers[0]
                                        $SecondaryServer = $DnsServers[1]
                                    }

                                    $OutputObj = New-Object -TypeName psobject

                                    $OutputObj | Add-Member -MemberType NoteProperty -Name NetworkName -Value $NetworkName
                                    $OutputObj | Add-Member -MemberType NoteProperty -Name IsDHCPEnabled -Value $IsDHCPEnabled
                                    $OutputObj | Add-Member -MemberType NoteProperty -Name PrimaryDnsServer -Value $PrimaryServer
                                    $OutputObj | Add-Member -MemberType NoteProperty -Name SecondaryDnsServer -Value $SecondaryServer

                                    Write-Host ''
                                    Write-Host "Gathering network DNS information for" -NoNewline
                                    Write-Host -ForegroundColor Yellow " [$Computer]" -NoNewline
                                    Write-Host "..."
                                    Start-Sleep -Seconds 1
    
                                    $OutputObj | Format-Table -AutoSize
                                }
                            }
                            catch {
                                Write-Host ''
                                Write-Warning -Message "Oops... Something went wrong!"
                                Write-Host ''
    
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
                            }
                        }
                    }
                    catch {
                        Write-Host ''
                        Write-Warning -Message "Oops... Something went wrong!"
                        Write-Host ''
    
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
                    }
                } # CLOSE else ($Default (non-$Searchbase)
            } # CLOSE if ($Default)
        } # CLOSE else
    } # CLOSE Process
    End {
    }
}