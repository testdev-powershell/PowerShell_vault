<#
    .SYNOPSIS
        Get/Disable expired Active Directory Computer Object(s) & remove the associated DNS A Record(s).

    .DESCRIPTION
        Search through Active Directory for any expired Computer Objects (> 90 days), disable them and remove the associated DNS A Records
        if found.

    .NOTES
        Author: Greg Powers
#>

$daysInactive = 90
$disabledDate = Get-Date
$disabledOU = 'OU=DisabledObjects,OU=testDEV,DC=testDEV,DC=local'
$expiredCompObj = Get-ADComputer -SearchBase $searchOU -Filter * -Properties * | ? {$_.LastLogonDate -le $timeDelta} | select -Property Name,LastLogonDate,DistinguishedName | sort LastLogonDate
$reportDate = (Get-Date).ToString("M-d-yyy")
$reportDirectory = "$env:SystemDrive\Reports\ADComputerObject_Expired_" + $reportDate + ""
$reportName = "$env:SystemDrive\Reports\ADComputerObject_Expired_" + $reportDate + "\" + $reportDate + ".log"
$searchOU = 'OU=Computers,OU=testDEV,DC=testDEV,DC=local'
$sessionUser = $env:UserName
$timeDelta = (Get-Date).AddDays(-($daysInactive))

<#
    Check to see if $reportDirectory exists. If not, create the directory before continuing on.
#>
    if (!(Test-Path $reportDirectory)) {
        Write-Host -ForegroundColor Yellow "[$reportDirectory]" -NoNewline
        Write-Host " does NOT exist! Attempting to create the directory..."
        Write-Host ''
        Start-Sleep -Seconds 1

            try {
                New-Item -ItemType Directory -Path $reportDirectory -Force
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
        Write-Host -ForegroundColor Yellow "[$reportDirectory]" -NoNewline
        Write-Host " already exists!"
    }

<#
    If there are no Computer Objects found in $expiredCompObj, create a NULL (empty) file to show the script has run but with no results.
    For each Computer Object found within $expiredCompObj, disable each Object, change the Description property (see below) and
    move each Object to the DisabledObjects OU. Append specific Computer Object information (see below) to $reportName log file,
    and finally, search DNS for any host record(s) each Computer Object and if found, remove them. Information regarding the DNS
    records will also be appended to the $reportName log file.
#>

    if ($expiredCompObj -eq $null) {
        New-Item -ItemType File -Path $reportDirectory\NULL_$reportDate
    }
    else {
        $expiredCompObjVar = foreach ($c in $expiredCompObj) {
            try {
                Get-ADComputer -Identity $c.Name | Disable-ADAccount -PassThru | Set-ADObject -Description "Moved to [DisabledObjects] as of $disabledDate by $sessionUser" -PassThru | Move-ADObject -TargetPath $disabledOU

                Get-ADComputer -Identity $c.Name -Properties Name,Enabled,DistinguishedName | select Name,Enabled,DistinguishedName | Out-File $reportName -Append
                Start-Sleep -Seconds 5
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
    
            Get-DnsServerResourceRecord -ZoneName "testDEV.local" -ComputerName "DNS server" -RRType "A" -Name $c.Name -ErrorAction SilentlyContinue | Remove-DnsServerResourceRecord -ZoneName "testDEV.local" -ComputerName "DNS server" -Force -Confirm:$false -ErrorAction SilentlyContinue

            if (!(Get-DnsServerResourceRecord -ZoneName "testDEV.local" -ComputerName "DNS server" -RRType "A" -Name $c.Name -ErrorAction SilentlyContinue)) {
                Write-Output "An entry for [$($c.Name)] was not found in DNS. The A Record has either been removed successfully or was previously removed (Aging/Scavenging)!" | Out-File $reportName -Append
                Write-Output '' | Out-File $reportName -Append
            }
            else {
                Write-Output "[$($c.Name)] was found in DNS Please review manually!" | Out-File $reportName -Append
                Get-DnsServerResourceRecord -ZoneName "testDEV.local" -ComputerName "DNS server" -RRType "A" -Name $c.Name | Out-File $reportName -Append
                Write-Output '' | Out-File $reportName -Append
            }
        }

        <#
            Call the $expiredCompObjVar
        #>

        $expiredCompObjVar

        <#
            Send-MailMessage setup with various parameters to confirm 
        #>

        $To = @("admin@testDEV.local", "testDEV_admins@testDEV.local")
        $From = "Ops Automation <ops-noreply@testDEV.local>"
        $Cc = "testDL@testDEV.local"
        $Bcc = "test.user@testDEV.local"
        $Subject = "Test Script Subject"
        $Body =
        "This email alert is to inform you that the <b>ComputerObject_setDisabledComputers</b> process has run. <br><br> Please see the attachment for detailed information!"
        $Attachments = "$reportName"
        $SMTPserver = "testDEV-local.mail.protection.outlook.com"

        Send-MailMessage -To $To -From $From -Cc $Cc -Bcc $Bcc -Subject $Subject -Body $Body -Attachments $Attachments -SmtpServer $SMTPserver -BodyAsHtml -Priority High
    }