<#
    .SYNOPSIS
        try/catch for $Error handling.

    .DESCRIPTION
        Error/Exception handling template (catch block) to be used universally regardless of what is being run in the try block.
        See (https://powershellexplained.com/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/) for detailed
        information concerning Error/Exception Handling (thanks to Kevin Marquette/Lee Daily).

    .NOTES
        Author: Greg Powers
#>

    try {
        <#
            cmdlet(s)/script snippet/function goes here!
        #>

        ...
    }
    catch {
        <#
            Use either a 'Pause' and/or 'EXIT' depending on if you want the script to continue or terminate. If you use a 'throw' in the catch
            block the script/function will not continue processing any proceeding commands. If you use 'Write-Error' in the catch block along
            with '-ErrorAction Stop' the script/function will terminate as well.
        #>

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

        #Pause
        #Return
        #Break
        #EXIT
    }