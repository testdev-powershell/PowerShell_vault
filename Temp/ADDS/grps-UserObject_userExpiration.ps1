<#
    .SYNOPSIS
        Get expiring domain accounts for Active Directory Users.

    .DESCRIPTION
        Search through Active Directory for any User(s) whose accounts are set to expire within the next 7 days.
        Send a mail message to the Ops/IT group members responsible for the data as well including a report of
        all affected Users.

    .NOTES
        Author: Greg Powers
#>

$OUs =
'OU=Users,OU=testDEV,DC=testDEV,DC=local'
$reportDate = (Get-Date).ToString("M-d-yyy")
$reportDirectory = "$env:SystemDrive\Reports\scripProcess_" + $reportDate + ""
$reportName = "$env:SystemDrive\Reports\scriptProcess_" + $reportDate + "\" + $reportDate + ".csv"

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
    Gather information for each User that meets the criteria for the User being added to the $userListFinal variable.
    If the $userlistFinal is $NULL, create the NULL report file and stop there. If $userListFinal is populated, a mail
    message is composed, using the $userListFinalToOps content and sent to the Operations/IT team responsible for the data.
#>

    try {
        $userList = foreach ($OU in $OUs) {
            Search-ADAccount -AccountExpiring -SearchBase $OU -UsersOnly -TimeSpan 07.00:00:00 | Get-ADUser -Properties Name,SamAccountName,LastLogonDate,AccountExpirationDate,Description
        }

        $userListFinal = $userList | select Name,SamAccountName,LastLogonDate,AccountExpirationDate,Description | Sort-Object -Descending AccountExpirationDate

            if ($userListFinal -eq $null) {
                <#
                    If there are no User(s) found, create a "NULL" file to show script functioned properly
                #>
            
                New-Item -ItemType File -Path $reportDirectory\NULL_$reportDate
            }
            else {
                $userListFinal | Export-Csv $reportName -Force
                
                $To = @("admin@testDEV.local", "testDEV_admins@testDEV.local")
                $From = "Ops Automation <ops-noreply@testDEV.local>"
                $Cc = "testDL@testDEV.local"
                $Subject = "[testDEV] -- Domain User Expiration Report --"
                $Body =
                "This email is to inform you that one or more Users within Active Directory will expire within the next <b>7 days</b>. Please see the attached .csv file for the full list of User(s) that are set to expire. <br><br>
                If any or all of these User(s) should remain <b>enabled</b>, please reply to <b>testDEV_admins@testDEV.local</b> to contact the Ops department and let them know which User(s) should remain enabled. <br><br>
                If there is no response within <b>7 days</b> the User(s) listed in the attached .csv will become <b>disabled</b>! Thank you!"
                $Attachments = "$reportName"
                $SMTPserver = "testDEV-local.mail.protection.outlook.com"

                Send-MailMessage -To $To -From $From -Cc $Cc -Subject $Subject -Body $Body -Attachments $Attachments -SmtpServer $SMTPserver -BodyAsHtml -Priority High
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