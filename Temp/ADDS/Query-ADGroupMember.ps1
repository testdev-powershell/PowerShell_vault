<#
    .SYNOPSIS
        Get Active Directory Group Member(s).

    .DESCRIPTION
        Get all the members of an Active Directory Group. Multiple included Switch parameters can be used to call specific
        objectClasses (users, computers and contacts) if need be. Similar to Get-ADGroupMember cmdlet.

    .NOTES
        Author: Greg Powers
#>

function Query-ADGroupMember {
    [CmdletBinding (
    )]

    Param (
        # -Identity -- Active Directory Group's SamAccountName
        [Parameter (
            Mandatory=$true,
            Position=0
        )]
        [System.String]
        $Identity,

        # -Full -- Displays additional information about the command being run
        [Parameter (
            Mandatory=$false
        )]
        [switch]
        $Full,

        # -Users -- Displays information only for members of the objectClass (user) within the Group
        [Parameter (
            Mandatory=$false
        )]
        [switch]
        $Users,

        # -Computers -- Displays information only for members of the objectClass (computer) within the Group
        [Parameter (
            Mandatory=$false
        )]
        [switch]
        $Computers,

        # -Contacts -- Displays information only for members of the objectClass (contact) within the Group. Not native to Get-ADGroupMember! This information is pulled using Get-ADGroup instead.
        [Parameter (
            Mandatory=$false
        )]
        [switch]
        $Contacts
    )

    Begin {
        $groupMembers = Get-ADGroupMember -Identity $Identity
        [array]$groupMembersArray = @()

        $groupUsers = Get-ADGroupMember -Identity $Identity | ? objectClass -eq "user"
        [array]$groupUsersArray = @()

        $groupComputers = Get-ADGroupMember -Identity $Identity | ? objectClass -eq "computer"
        [array]$groupComputersArray = @()

        $groupContacts = Get-ADGroup -Identity testGroup1 -Properties Members | select -ExpandProperty Members | Get-ADObject | ? objectClass -EQ "contact" | select @{ Name = "Contact"; Expression = {$_.Name}}
    }
    Process {
        if ($groupMembers.count -eq "0") {
            Write-Host "There were no Members found within the AD Group [$Identity]..."
            Write-Host ''
            Start-Sleep -Seconds 1
        }
        elseif ($Users) {
            if ($Full) {
                Write-Host ''
                Write-Host "Attempting to gather" -NoNewline
                Write-Host -ForegroundColor Yellow " [User]" -NoNewline 
                Write-Host " information from" -NoNewline
                Write-Host -ForegroundColor Yellow " [$Identity]" -NoNewline
                Write-Host ", including each User's" -NoNewline
                Write-Host -ForegroundColor Yellow " [Enabled]" -NoNewline
                Write-Host " and" -NoNewline
                Write-Host -ForegroundColor Yellow " [LastLogonDate]" -NoNewline
                Write-Host " status..."
                Write-Host ''
                Start-Sleep -Seconds 1
            }

            try {
                foreach ($u in $groupUsers) {
                    $User = Get-ADUser -Identity $u.SamAccountName -Properties SamAccountName,Enabled,LastLogonDate,MemberOf | ? {$_.MemberOf -match $Identity} | select @{Name = "UserName" ; Expression = { $_.SamAccountName }},Enabled,LastLogonDate
                    $groupUsersArray += $User
                }

                $groupUsersArray | sort Enabled -Descending
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
            }
        }
        elseif ($Computers) {
            if ($Full) {
                Write-Host ''
                Write-Host "Attempting to gather" -NoNewline
                Write-Host -ForegroundColor Yellow " [Computer]" -NoNewline 
                Write-Host " information from" -NoNewline
                Write-Host -ForegroundColor Yellow " [$Identity]" -NoNewline
                Write-Host ", including each Computer's" -NoNewline
                Write-Host -ForegroundColor Yellow " [Enabled]" -NoNewline
                Write-Host " and" -NoNewline
                Write-Host -ForegroundColor Yellow " [LastLogonDate]" -NoNewline
                Write-Host " status..."
                Write-Host ''
                Start-Sleep -Seconds 1
            }

            try {
                foreach ($c in $groupComputers) {
                    $Computer = Get-ADComputer -Identity $c.Name -Properties Name,Enabled,LastLogonDate,MemberOf | ? {$_.MemberOf -match $Identity} | select @{Name = "ComputerName" ; Expression = { $_.Name }},Enabled,LastLogonDate
                    $groupComputersArray += $Computer
                }

                $groupComputersArray | sort Enabled -Descending
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
            }
        }
        elseif ($Contacts) {
            if ($Full) {
                Write-Host ''
                Write-Host "Attempting to gather" -NoNewline
                Write-Host -ForegroundColor Yellow " [Contact]" -NoNewline 
                Write-Host " information from" -NoNewline
                Write-Host -ForegroundColor Yellow " [$Identity]" -NoNewline
                Write-Host "..."
                Write-Host ''
                Start-Sleep -Seconds 1
            }

            try {
                $groupContacts
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
            }
        }
        else {
            if ($Full) {
                Write-Host ''
                Write-Host "Attempting to gather" -NoNewline
                Write-Host -ForegroundColor Yellow " [Member]" -NoNewline 
                Write-Host " information from" -NoNewline
                Write-Host -ForegroundColor Yellow " [$Identity]" -NoNewline
                Write-Host "..."
                Write-Host ''
                Start-Sleep -Seconds 1
            }

            try {
                foreach ($m in $groupMembers) {
                    $Member = Get-ADObject -Identity $m.DistinguishedName -Properties SamAccountName,objectClass,MemberOf | ? {$_.MemberOf -match $Identity} | select @{Name = "Name" ; Expression = { $_.SamAccountName }}, @{Name = "MemberType" ; Expression = { $_.objectClass }}
                    $groupMembersArray += $Member
                }
                $groupMembersArray | sort Name
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
            }
        }
    }
    End {
    }
}