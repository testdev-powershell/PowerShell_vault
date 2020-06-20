<#
    .SYNOPSIS
        Logging and Send-MailMessage template.

    .DESCRIPTION
        A simple template showcasing a structure for setting up logging and Send-MailMessage options/parameters.

    .NOTES
        Author: Greg Powers
#>

$reportDate = (Get-Date).ToString("M-d-yyy")
$reportDirectory = "$env:SystemDrive\Reports\scripProcess_" + $reportDate + ""
$reportName = "$env:SystemDrive\Reports\scriptProcess_" + $reportDate + "\" + $reportDate + ".log"

$To = @("admin@testDEV.local", "testDEV_admins@testDEV.local")
$From = "Ops Automation <ops-noreply@testDEV.local>"
$Cc = "testDL@testDEV.local"
$Bcc = "test.user@testDEV.local"
$Subject = "Test Script Process Subject"
$Body =
"This email alert is to inform you that the <b>testDEV script</b> process has run. <br><br> Please see the attachment for detailed information!"
$Attachments = "$reportName"
$SMTPserver = "testDEV-local.mail.protection.outlook.com"

Send-MailMessage -To $To -From $From -Cc $Cc -Bcc $Bcc -Subject $Subject -Body $Body -Attachments $Attachments -SmtpServer $SMTPserver -BodyAsHtml -Priority High