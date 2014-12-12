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

[CmdletBinding()]
param (
    [parameter(Mandatory=$false, Position=0)]
    [string]$territoryRoot = 'C:\Users\rerben\Dropbox\ATCSMon\Downloads\Territories\incoming',

    [parameter(Mandatory=$false, Position=0)]
    [string]$atcsmonRoot = 'C:\Users\rerben\Dropbox\ATCSMon-Script-Test' 
)

Import-Module WDAC

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



# Ensure the project root exists.

if (Test-path $territoryRoot)
{
    $territories = Get-ChildItem -File -Filter '*.zip' -Path $territoryRoot

    foreach ($territory in $territories)
    {
        $extractDir = Join-Path -Path $territoryRoot -ChildPath 'extract'
        New-Item -Force -ItemType Directory -Path $extractDir | Out-Null

        Expand-ZIPFile $territory.FullName $extractDir

        Write-Host "Extracted contents:"
        $extractedContents = Get-ChildItem -File -Path $extractDir

        foreach ($extractedItem in $extractedContents)
        {
            Write-Host "  " $extractedItem

            switch ($extractedItem.Extension)
            {
                ".mcp" {Write-Host "     MCP or MDB file"}
                ".mdb" {Write-Host "     MCP or MDB file"}
                ".lay" {Write-Host "     Layout file"}
                ".ini" {Write-Host "     INI file"}
                ".txt" {Write-Host "     TEXT file"}
                ".kmz" {Write-Host "     KMZ file"}
                default {Write-Host "     Unknown file"}
            }
        }

        Write-Host "Removing the extract directory..." $extractDir
        Remove-Item -Force -Recurse -Path $extractDir
    }
}
else
{
    Write-Host "territoryRoot does not exist: $territoryRoot"
}
