<#
    .SYNOPSIS
        Get expiring domain passwords for Active Directory Users.

    .DESCRIPTION
        Search through Active Directory for any User(s) whose passwords are set to expire within the next 7 days.
        Send a mail message to each User affected individually with information including the password expiry
        date. Send another mail message to the Ops/IT group members responsible for the data as well including
        a report of all affected Users.

    .NOTES
        Author: Greg Powers
#>

$OUs =
'OU=Users,OU=testDEV,DC=testDEV,DC=local'
$reportDate = (Get-Date).ToString("M-d-yyy")
$reportDirectory = "$env:SystemDrive\Reports\scripProcess_" + $reportDate + ""
$reportName = "$env:SystemDrive\Reports\scriptProcess_" + $reportDate + "\" + $reportDate + ".log"

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
    Gather information for each User that meets the criteria for the User being added to the $userListFinal/ToOps variable.
    If the $userlistFinal is $NULL, create the NULL report file and stop there. If $userListFinal/ToOps is populated, using
    the $userListFinal variable's contents, for each User, send a personalized mail message including the User's name, the
    expiry date of their domain account password and instructions concerning how to update their domain password.

    A separate mail message is then composed, using the $userListFinalToOps content and sent to the Operations/IT team responsible
    for the data.
#>

    try {
        $userList = foreach ($OU in $OUs) {
            Get-ADUser -Filter {Enabled -eq $true -and PasswordNeverExpires -eq $false -and PasswordLastSet -ne "0"} -Properties Name, EmailAddress, GivenName, PasswordLastSet, msDS-UserPasswordExpiryTimeComputed -SearchBase $OU -SearchScope OneLevel
        }

        $userListFinal = $userList | select Name, EmailAddress, GivenName, @{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} | ? {($_.ExpiryDate -le (Get-Date).AddDays(7)) -and ($_.ExpiryDate -ge (Get-Date))}
        $userListFinalToOps = $userList | select Name, @{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} | ? {($_.ExpiryDate -le (Get-Date).AddDays(7)) -and ($_.ExpiryDate -ge (Get-Date))} | Format-Table -AutoSize
  
        if ($userListFinal -eq $null) {
            <#
                If there are no User(s) found, create a "NULL" file to show script functioned properly
            #>
            
            New-Item -ItemType File -Path $reportDirectory\NULL_$reportDate
        }
        else {
            $userListFinalToOps | Out-File $reportName -Force

            foreach ($user in ($userListFinal | ? {-not [string]::isnullorwhitespace($_.EmailAddress)})) {
                $expiry = $user.ExpiryDate.DateTime

                $ToUsers = "noreply@testDEV.local"
                $From = "Ops Automation <ops-noreply@testDEV.local>"
                $BccUsers = "$($user.EmailAddress)"
                $SubjectUsers = "[testDEV] Domain User Password Expiration -- Do Not Reply --"
                $BodyUsers =
                "Hi $($user.GivenName), <br><br> This email is to inform you that your domain password will expire on <b>$expiry</b>! <br><br> Please refer to the following ways to update your password... <br><br>"
                $SMTPserver = "testDEV-local.mail.protection.outlook.com"
            
                Send-MailMessage -To $ToUsers -From $From -Bcc $BccUsers -Subject $SubjectUsers -Body $BodyUsers -SmtpServer $SMTPserver -BodyAsHtml -Priority High
            }

            $ToOps = @("admin@testDEV.local", "testDEV_admins@testDEV.local")
            $From = "Ops Automation <ops-noreply@testDEV.local>"
            $SubjectOps = "[tesDEV] -- Domain User Password Expiration --"
            $Attachments = "$reportName"
            $BodyOps =
            "This email is to inform you that one or more <b>testDEV</b> User(s) <b>passwords</b> within Active Directory will expire within the next <b>7 days</b>. <br><br> Please see the attachment for detailed information!"
            $SMTPserver = "wbiegames-com.mail.protection.outlook.com"
            
            Send-MailMessage -To $ToOps -From $From -Subject $SubjectOps -Body $BodyOps -Attachments $Attachments -SmtpServer $SMTPserver -BodyAsHtml -Priority High
        }
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