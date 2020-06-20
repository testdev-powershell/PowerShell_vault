<#
    .SYNOPSIS
        Create a Hyper-V External vSwitch

    .DESCRIPTION
        Create a new Hyper-V Switch, choosing from an External, Internal or Private
        switch. Select from local Network Adapter(s) to use if you choose to create
        an External switch only!

    .NOTES
        Author: Greg Powers
#>

function New-HyperVSwitch {
    [CmdletBinding(
    )]

    Param (
        # Name --
        [Parameter(
            Position=0,
            Mandatory=$true
        )]
        [System.String]
        $Name,

        # NetworkAdapter (used for External switch) --
        [Parameter(
            Mandatory=$false,
            ParameterSetName="1"
        )]
        [System.String]
        $NetworkAdapter,

        # Type (Internal,Private) --
        [Parameter(
            Mandatory=$false,
            ParameterSetName="2"
        )]
        [ValidateSet(
            "Internal","Private"
        )]
        $Type
    )

    Begin {
    }
    Process { # OPEN Process
        if ($NetworkAdapter) { # OPEN if -- $NetworkAdapter (External switch)
            try {
                New-VMSwitch -Name $Name -NetAdapterName $NetworkAdapter -AllowManagementOS $true -Notes "[$Name] -- Created with PowerShell" -Confirm:$false -ErrorAction Stop | Out-Null

                Write-Host ''
                Write-Host "New Hyper-V" -NoNewline
                Write-Host  -ForegroundColor Yellow " [External]" -NoNewline
                Write-Host " vSwitch has been created! The new vSwitch's name is" -NoNewline
                Write-Host  -ForegroundColor Yellow " [$Name]" -NoNewline
                Write-Host ". Please see the summary below for more information..."
                Write-Host ''
                Start-Sleep -Seconds 1
        
                Get-VMSwitch -Name $Name | Format-List -Property *
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
        } # CLOSE if -- $NetworkAdapter (External switch)
        elseif ($Type -eq "Internal") { # OPEN if -- Internal
            try {
                New-VMSwitch -Name $Name -SwitchType Internal -Notes "[$Name] -- Created with PowerShell" -Confirm:$false -ErrorAction Stop | Out-Null

                Write-Host ''
                Write-Host "New Hyper-V" -NoNewline
                Write-Host  -ForegroundColor Yellow " [Internal]" -NoNewline
                Write-Host " vSwitch has been created! The new vSwitch's name is" -NoNewline
                Write-Host  -ForegroundColor Yellow " [$Name]" -NoNewline
                Write-Host ". Please see the summary below for more information..."
                Write-Host ''
                Start-Sleep -Seconds 1
        
                Get-VMSwitch -Name $Name | Format-List -Property *
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
        } # CLOSE if -- Internal
        elseif ($Type -eq "Private") { # OPEN if -- Private
            try {
                New-VMSwitch -Name $Name -SwitchType Private -Notes "[$Name] -- Created with PowerShell" -Confirm:$false -ErrorAction Stop | Out-Null

                Write-Host ''
                Write-Host "New Hyper-V" -NoNewline
                Write-Host  -ForegroundColor Yellow " [Private]" -NoNewline
                Write-Host " vSwitch has been created! The new vSwitch's name is" -NoNewline
                Write-Host  -ForegroundColor Yellow " [$Name]" -NoNewline
                Write-Host ". Please see the summary below for more information..."
                Write-Host ''
                Start-Sleep -Seconds 1
        
                Get-VMSwitch -Name $Name | Format-List -Property *
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
        } # CLOSE if -- Private
    } # CLOSE Process
    End {
    }
}