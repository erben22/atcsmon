<#
.SYNOPSIS 
    Fill me in...

.DESCRIPTION
    Add fluff here.

.PARAMETER ParameterName
    Describe it here
    
.EXAMPLE
    Connect-AzureVM -AzureSubscriptionName "Visual Studio Ultimate with MSDN" -ServiceName "Finance" -VMName "WebServer01" -AzureOrgIdCredential $cred
    ManageTerritories.ps1 -blah

.NOTES
    AUTHOR: R. Cody Erben
    LASTEDIT: 20141128
#>

###############################################################################
# Function to grep input from the pipeline.
###############################################################################
function Expand-ZIPFile([string]$file, [string]$destination)
{
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items())
    {
       $shell.Namespace($destination).copyhere($item)
    }
}

param($territoryRoot)

# Ensure the project root exists.

if (Test-path $territoryRoot)
{
    Write-Host "territoryRoot exists: $territoryRoot"
}
else
{
    Write-Host "territoryRoot does not exist: $territoryRoot"
}

