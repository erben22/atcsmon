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

Function Connect-Database([string]$database)
{
    Write-Host "Connecting to the database: " $database

    $adOpenStatic = 3
    $adLockOptimistic = 3

    $objConnection = New-Object -comobject ADODB.Connection
    $objRecordset = New-Object -comobject ADODB.Recordset

    #$provider = "Provider = Microsoft.Jet.OLEDB.4.0; Data Source = " + $database
    #$provider = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=C:\Users\rerben\Dropbox\ATCSMon-Script-Test\atcsdb.mdb"
    #Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=C:\mydatabase.accdb
    $provider = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=C:\Users\rerben\Dropbox\ATCSMon-Script-Test\atcsdb.mdb"

    Write-Host "Provider string: " $provider

    $objConnection.Open($provider)

    $objRecordset.Open("Select * from MCP", $objConnection,$adOpenStatic,$adLockOptimistic)

    $objRecordset.MoveFirst()

    do 
    {
        $objRecordset.Fields.Item("MCPAddress").Value; 
        $objRecordset.MoveNext()
    } until ($objRecordset.EOF -eq $True)

    $objRecordset.Close()
    $objConnection.Close()


    Write-Host "Done with the database operations."
}

function HandleMCPs([System.IO.FileInfo]$mcpFile)
{
    Write-Host "Processing an MCP/MDB file: " $mcpFile.FullName

    Connect-Database $mcpFile.FullName
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
                ".mcp" {HandleMCPs $extractedItem}
                ".mdb" {HandleMCPs $extractedItem}
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

