<#
.SYNOPSIS 
    Script for handling ATCSMon territory updates.  Design to run as a scheduled
    task, firing off and looking for new territories, and then extracting and 
    applying them to ATCSMon install(s).

.DESCRIPTION
    Script that will extract and ATCSMon territory package, place files in 
    appropriate locations, and then import the MCP update package (either an
    ini or database) into the ATCSMon database.

.PARAMETER territoryRoot
    Directory where the territory(ies) to import are located.  Zip files in this
    location will be processed.
    
.PARAMETER atcsmonRoot
    Root directory for an ATCSMon installation to apply the territory updates
    to.

.EXAMPLE
    ManageTerritories.ps1 -territoryRoot 'C:\ATCSMon\Downloads\Territories\incoming' `
        -atcsmonRoot 'C:\ATCSMon' 

.NOTES
    AUTHOR: R. Cody Erben
    LASTEDIT: 20141215
#>

[CmdletBinding()]
param (
    [parameter(Mandatory=$false, Position=0)]
    [string]$territoryRoot = 'C:\Users\rerben\Dropbox\ATCSMon\Downloads\Territories\incoming',

    [parameter(Mandatory=$false, Position=1)]
    [string]$atcsmonRoot = 'C:\Users\rerben\Dropbox\ATCSMon-Script-Test' 
)

Import-Module WDAC

###############################################################################
# Use the shell to extract a zip file.
###############################################################################
function Expand-ZIPFile([string]$file, [string]$destination)
{
    $shellCopyOpNoProgressDialog = 4
    $shellCopyOpYesToAll = 16

    $shell = New-Object -com Shell.Application
    $zip = $shell.NameSpace($file)

    foreach($item in $zip.items())
    {
        $shell.Namespace($destination).CopyHere($item, `
            $shellCopyOpNoProgressDialog -bor $shellCopyOpYesToAll)
    }
}

Function Connect-Database([string]$database)
{
    Write-Host "Connecting to the database: " $database

    # Logic should be something like:
    #   - Open source database.
    #   - Ensure the MCP table exists.
    #   - Open destination datbase.
    #   - Ensure the MCP table exists.

    #   - For each recordset in source database:
    #   - Add to destination DB
    #     - What happens if it already exists?  Overwrite or duplicate?

    #   - Do I need to know each column in the MCP db, or, can I just
    #     pass in a recordset?

    try
    {
        $adOpenStatic = 3
        $adLockOptimistic = 3

        $adSchemaTables = 20
        $adSchemaColumns = 4

        $atcsDB = New-Object -ComObject ADODB.Connection
        $atcsDBProvider = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=C:\Users\rerben\Dropbox\ATCSMon-Script-Test\atcsdb.mdb"
    
        #$kitUpdateDB = New-Object -ComObject ADODB.Connection
        #$kitDBProvider = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=" + $database
        #$kitDBProvider = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=C:\Users\rerben\Dropbox\ATCSMon\Downloads\Territories\incoming\extract\BNSF-eastwashington-20141118.mdb"

        $atcsDBProvider.Open($kitDBProvider)

        #$objRecordset = $atcsDBProvider.OpenSchema($adSchemaTables)
        $objRecordset = $atcsDBProvider.OpenSchema($adSchemaColumns)
        $objRecordset.MoveFirst()

        do 
        {
            #if ("TABLE" -eq $objRecordset.Fields.Item("TABLE_TYPE").Value)
            if ("MCP" -eq $objRecordset.Fields.Item("TABLE_NAME").Value)
            {
                Write-Host "Column Name: " $objRecordset.Fields.Item("COLUMN_NAME").Value;
            }             
            $objRecordset.MoveNext()
        } until ($objRecordset.EOF -eq $True)

        $objRecordset.Close()

        $objRecordset.Open("Select * from MCP", $kitUpdateDB, $adOpenStatic, $adLockOptimistic)

        $objRecordset.MoveFirst()

        do 
        {
            $objRecordset.Fields.Item("MCPAddress").Value; 
            $objRecordset.MoveNext()
        } until ($objRecordset.EOF -eq $True)

        $objRecordset.Close()


        $atcsDBProvider.Close()

    #Set rstList = cnnDB.OpenSchema(adSchemaTables)

    #   ' Loop through the results and print the
    #   ' names and types in the Immediate pane.
    #   With rstList
    #      Do While Not .EOF
    #         If .Fields("TABLE_TYPE") <> "VIEW" Then
    #            Debug.Print .Fields("TABLE_NAME") & vbTab & _
    #               .Fields("TABLE_TYPE")
    #         End If
    #         .MoveNext
    #      Loop
    #   End With
    #   cnnDB.Close


        #$objRecordset.Open("Select * from MCP", $kitUpdateDB,$adOpenStatic,$adLockOptimistic)

        #$objRecordset.MoveFirst()

        #do 
        #{
        #    $objRecordset.Fields.Item("MCPAddress").Value; 
        #    $objRecordset.MoveNext()
        #} until ($objRecordset.EOF -eq $True)

        #$objRecordset.Close()

        #$kitUpdateDB.Close()
    }
    catch
    {
        $Error[0]
    }

    Write-Host "Done with the database operations."
}

function Get-EntryKeyValue([string]$keyValueData)
{
    Set-Variable -Option Constant keyValueDelimiter -Value '='
    $keyValueData.Split($keyValueDelimiter)
}

function Import-MCPFile([System.IO.FileInfo]$mcpFile)
{
    # Need to parse the MCP file, building up a collection of the data in it.

    $mcpFileContents = Get-Content $mcpFile.FullName
    $keyValueData = Get-EntryKeyValue($mcpFileContents[1])

    Write-Host "keyValueData is: " $keyValueData

    $numMCPEntries = [Convert]::ToInt32((Get-EntryKeyValue($mcpFileContents[1]))[1], 10)

    Write-Host "Processing " $numMCPEntries " MCP entries..."

    $mcpLineIndex = 2

    $mcpEntry = @{}
    $mcpData = @{}
    $currentMCPIndex = 1
    $currentMCPAddress = ''

    while ($mcpFileContents.Count -gt $mcpLineIndex)
    {
        $keyValueData = Get-EntryKeyValue($mcpFileContents[$mcpLineIndex])
        
        $parsed = $keyValueData[0] -match '^([a-zA-Z]+)([0-9]+)'

        if ($parsed)
        {
            $mcpIndex = [Convert]::ToInt32($matches[2], 10)
            #Write-Host "  File Index(" $mcpLineIndex "): MCP Index(" $mcpIndex ") Key(" $matches[1] ") Value(" $keyValueData[1] ")"

            # Need to use two hashtables.  One will be an mcpIndex key, to a hashtable value.  The
            # second will be a hashtable of all the mcpIndex entries.

            if ($currentMCPIndex -ne $mcpIndex)
            {
                # Have a new MCP entry to handle.  Add the previous entry, then clear
                # the working data.

                $mcpEntry.Add($currentMCPAddress, $mcpData)            

                $mcpData.Clear()
                $currentMCPIndex = $mcpIndex
            }

            if ($matches[1] -eq "MCPAddress")
            {
                $currentMCPAddress = $keyValueData[1]
            }

            $mcpData.Add($matches[1], $keyValueData[1])
        }

        $mcpLineIndex++;
    }

    $mcpEntry.Add($currentMCPAddress, $mcpData)

    Write-Host "Done processing MCP file.  mcpEntry data:"

    foreach ($entry in $mcpEntry.GetEnumerator())
    {
        Write-Host "$($entry.Name): $($entry.Value)"

        foreach ($valueEntry in $entry.value.GetEnumerator())
        {
            Write-Host "    $($valueEntry.Name): $($valueEntry.Value)"
        }
    }
}

function HandleMCPs([System.IO.FileInfo]$mcpFile)
{
    Write-Host "Processing an MCP/MDB file: " $mcpFile.FullName

    if (".mcp" -eq $mcpFile.Extension)
    {
        # Process with the MCP importer.

        Import-MCPFile $mcpFile
    }

    #Connect-Database $mcpFile.FullName
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
