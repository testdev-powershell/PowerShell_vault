<#
    .SYNOPSIS
        Update one or more Active Directory User's Name(s).

    .DESCRIPTION
        Update an Active Directory User's Name to be the same as the User's DisplayName.

    .NOTES
        Author: Greg Powers
#>

function Rename-ADUser {
    [CmdletBinding (
        SupportsShouldProcess=$true
    )]

    Param (
        # -Identity -- Active Directory User's SamAccountName
        [Parameter (
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true
        )]
        [System.String]
        $Identity,

        # -Full -- Displays additional information about the User
        [Parameter (
            Mandatory=$false
        )]
        [switch]
        $Full
    )

    Begin {
        $displayName = Get-ADUser -Identity $Identity -Properties DisplayName | select -ExpandProperty DisplayName
        $distinguishedName = Get-ADUser -Identity $Identity -Properties DistinguishedName | select -ExpandProperty DistinguishedName
        $Name = Get-ADUser -Identity $Identity -Properties Name | select -ExpandProperty Name
    }
    Process{
        try {
            if ($displayName -eq $Name) {
                Write-Host ''
                Write-Host "The [Name] and [DisplayName] for" -NoNewline
                Write-Host -ForegroundColor Yellow " [$Name]" -NoNewline
                Write-Host " already match! No changes will be made to the User..."
                Write-Host ''
                Start-Sleep -Seconds 1
            }
            else {
                if ($Full) {
                    $displayName = Get-ADUser -Identity $Identity -Properties DisplayName | select -ExpandProperty DisplayName
                    $distinguishedName = Get-ADUser -Identity $Identity -Properties DistinguishedName | select -ExpandProperty DistinguishedName
                    $Name = Get-ADUser -Identity $Identity -Properties Name | select -ExpandProperty Name
                    
                    Write-Host ''
                    Write-Host "Attempting to rename User" -NoNewline
                    Write-Host -ForegroundColor Yellow " [$Name]" -NoNewline
                    Write-Host " to" -NoNewline
                    Write-Host -ForegroundColor Yellow " [$displayName]" -NoNewline
                    Write-Host "..."
                    Write-Host ''
                    Start-Sleep -Seconds 1
                    
                    Rename-ADObject -Identity $distinguishedName -NewName $displayName
                    Start-Sleep -Seconds 1

                    $displayName = $Name = $null

                    if ($displayName -eq $Name) {
                        $displayName = Get-ADUser -Identity $Identity -Properties DisplayName | select -ExpandProperty DisplayName
                        $distinguishedName = Get-ADUser -Identity $Identity -Properties DistinguishedName | select -ExpandProperty DistinguishedName
                        $Name = Get-ADUser -Identity $Identity -Properties Name | select -ExpandProperty Name

                        Get-ADUser -Identity $Identity -Properties DisplayName,Name | select DisplayName,Name
                    }
                }
                else {
                    $displayName = Get-ADUser -Identity $Identity -Properties DisplayName | select -ExpandProperty DisplayName
                    $distinguishedName = Get-ADUser -Identity $Identity -Properties DistinguishedName | select -ExpandProperty DistinguishedName
                    $Name = Get-ADUser -Identity $Identity -Properties Name | select -ExpandProperty Name

                    Rename-ADObject -Identity $distinguishedName -NewName $displayName
                }
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
        }
    }
    End {
    }
}