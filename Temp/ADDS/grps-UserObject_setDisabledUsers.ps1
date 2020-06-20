<#
    .SYNOPSIS
        Get/Move Disabled AD User Object(s).

    .DESCRIPTION
        Search an OU for any Disabled Users and move to the DisabledObjects OU. Add a custom Description to each
        User including a date stamp as well as the $sessionUser who performed the action.

    .NOTES
        Author: Greg Powers
#>

$date = (Get-Date).ToString("M/d/yyy")
$disabledOU = 'OU=DisabledObjects,OU=testDEV,DC=testDEV,DC=local'
$disabledUsers = Get-ADUser -Filter {Enabled -eq $false} -SearchBase $searchOU
$searchOU = 'OU=Users,OU=testDEV,DC=testDEV,DC=local'
$sessionUser = $env:UserName
$userArray = @()

<#
    For any Users found in the $disabledUsers variable, store each of them within the $userArray array. This will be
    used later to output all Users found to the console for visibility.

    Move all Disabled User(s) into the DisabledObjects OU and change the Description property for each User (see below).
#>

    foreach ($user in $disabledUsers) {
        try {
            $userArray += $user
            Start-Sleep -Seconds 1

            Get-ADUser -Identity $user | Set-ADUser -Description "Moved to [DisabledObjects] as of $date by $sessionUser" -PassThru | Move-ADObject -TargetPath $disabledOU
        }
        catch{
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

    if ($userArray.Count -eq "0") {
        Write-Host "No Disabled Users were found within" -NoNewline
        Write-Host -ForegroundColor Yellow " $searchOU"
        Write-Host ''
    }
    else {
        Start-Sleep -Seconds 1

        Write-Host "Found the following Users..."
        Write-Host ''

        foreach ($u in $userArray) {
            Write-Host -ForegroundColor Yellow $u.SamAccountName
        }

        Write-Host ''
        Start-Sleep -Seconds 1

        Write-Host "All Users' Descriptions have been updated to read..."
        Write-Host ''

        Write-Host "Moved to [DisabledObjects] as of" -NoNewline
        Write-Host -ForegroundColor Yellow " $($date)" -NoNewline
        Write-Host " by" -NoNewline
        Write-Host -ForegroundColor Yellow " $($sessionUser)"

        Pause
    }