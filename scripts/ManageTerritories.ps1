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

Set-StrictMode -version 2
$ErrorActionPreference = "Stop"

$adOpenStatic = 3
$adLockOptimistic = 3
$adSchemaTables = 20
$adSchemaColumns = 4


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

function Get-DatabaseInfo($database)
{
    if ($database)
    {
        #try
        #{
            #$objRecordset = $database.OpenSchema($adSchemaTables)
            $objRecordset = $database.OpenSchema($adSchemaColumns)
            $objRecordset.MoveFirst()

            do
            {
                #if ("TABLE" -eq $objRecordset.Fields.Item("TABLE_TYPE").Value)
                if ("MCP" -eq $objRecordset.Fields.Item("TABLE_NAME").Value)
                {
                    Write-Host "Column Name: " $objRecordset.Fields.Item("COLUMN_NAME").Value
                }
                $objRecordset.MoveNext()
            } until ($objRecordset.EOF -eq $True)

            $objRecordset.Close()

            $objRecordset.Open("Select * from MCP", $database, $adOpenStatic, $adLockOptimistic)
            $objRecordset.MoveFirst()

            $mcpDBData = @()

            do
            {

                $mcpObject = New-Object PSObject -Property @{
                    MCPAddress = $objRecordset.Fields.Item("MCPAddress").Value}

#                $mcpObject = New-Object PSObject -Property @{
#                    MCPAddress = $objRecordset.Fields.Item("MCPAddress").Value
#                    MCPName = $objRecordset.Fields.Item("MCPName").Value
#                    MCPMilepost = $objRecordset.Fields.Item("MCPMilepost").Value
#                    MCPControlMessageNo = $objRecordset.Fields.Item("MCPControlMessageNo").Value
#                    MCPControlBits = $objRecordset.Fields.Item("MCPControlBits").Value
#                    MCPControlMnemonics = $objRecordset.Fields.Item("MCPControlMnemonics").Value
#                    MCPIndicationMessageNo = $objRecordset.Fields.Item("MCPIndicationMessageNo").Value
#                    MCPIndicationBits = $objRecordset.Fields.Item("MCPIndicationBits").Value
#                    MCPIndicationMnemonics = $objRecordset.Fields.Item("MCPIndicationMnemonics").Value
#                    MCPSubdivision = $objRecordset.Fields.Item("MCPSubdivision").Value
#                    MCPStateCountry = $objRecordset.Fields.Item("MCPStateCountry").Value
#                    MCPFrequency = $objRecordset.Fields.Item("MCPFrequency").Value
#                    MCPProtocol = $objRecordset.Fields.Item("MCPProtocol").Value
#                    MCPResetRoutes = $objRecordset.Fields.Item("MCPResetRoutes").Value
#                    MCPLongitude = $objRecordset.Fields.Item("MCPLongitude").Value
#                    MCPLatitude = $objRecordset.Fields.Item("MCPLatitude").Value
#                    MCPUpdated = $objRecordset.Fields.Item("MCPUpdated").Value
#                    MCPActivityI = $objRecordset.Fields.Item("MCPActivityI").Value
#                    MCPActivityC = $objRecordset.Fields.Item("MCPActivityC").Value}

                #$mcpDBData += $mcpObject

                $objRecordset.MoveNext()
            } until ($objRecordset.EOF -eq $True)

            $objRecordset.Close()

            #$mcpDBData | Format-Table

            Write-Host "Done with the database operations."
        #}
        #catch
        #{
        #    Write-Error "Error occured: $_"
        #}
    }
}

function Open-Database([System.IO.FileInfo]$databasePath)
{
    if (Test-Path $databasePath.FullName)
    {
        $database = New-Object -ComObject ADODB.Connection
        $databaseProvider = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=$($databasePath.FullName)"

        $database.Open($databaseProvider)

        return $database
    }
}

function Close-Database($database)
{
    if ($database)
    {
        $database.Close()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($database)
    }
}

function Get-EntryKeyValue([string]$keyValueData)
{
    Set-Variable -Option Constant keyValueDelimiter -Value '='
    $keyValueData.Split($keyValueDelimiter)
}

function Import-MCPFile([System.IO.FileInfo]$mcpFile)
{
    # Need to parse the MCP file, building up a collection of the data in it.

    # Gobble up the MCP file content.

    $mcpFileContents = Get-Content $mcpFile.FullName

    # Start our processing after skipping the first two lines.  The first line
    # is the ini file section, and the second line is the number of MCP entries.

    $mcpLineIndex = 2

    # Initialize some variables we will use in our processing.

    $mcpEntry = @{}
    $mcpData = @{}
    $currentMCPIndex = 1
    $currentMCPAddress = ''

    while ($mcpFileContents.Count -gt $mcpLineIndex)
    {
        # Read the key/value entry in the MCP file:

        $keyValueData = Get-EntryKeyValue($mcpFileContents[$mcpLineIndex])

        # Ensure we have a valid key of the form 'xyz99'.

        $parsed = $keyValueData[0] -match '^([a-zA-Z]+)([0-9]+)'

        if ($parsed)
        {
            # From parsing of the key, matches[2] is the MCP index we are
            # processing in this iteration.

            $mcpIndex = [Convert]::ToInt32($matches[2], 10)

            #Write-Host "  File Index(" $mcpLineIndex "): MCP Index(" $mcpIndex ") Key(" $matches[1] ") Value(" $keyValueData[1] ")"

            # If our currentMCPIndex differs from the mcpIndex we parsed out
            # of the key, then we have hit a new record.

            if ($currentMCPIndex -ne $mcpIndex)
            {
                # Have a new MCP entry to handle.  Add the hashtable of data
                # to our mcpEntry, then clear the working data hashtable so
                # it can build up data for the next MCP.

                $mcpEntry.Add($currentMCPAddress, $mcpData)

                $mcpData.Clear()
                $currentMCPIndex = $mcpIndex
            }

            # The key we processed is MCPAddress, so we want to set our
            # key into the mcpEntry hashtable to the value of MCPAddress.

            if ($matches[1] -eq "MCPAddress")
            {
                $currentMCPAddress = $keyValueData[1]
            }

            # Once we get here, we want to store the key/value pair
            # into our mcpData hashtable.

            $mcpData.Add($matches[1], $keyValueData[1])
        }

        $mcpLineIndex++;
    }

    # Due to how we process data, once we complete iterating, we have a record
    # that we have built-up, but was not added to the mcpEntry collection yet.
    # We take care of that here, and we now have all our file data contained
    # in a collection we can use and index into.

    $mcpEntry.Add($currentMCPAddress, $mcpData)

    # Check and see if the MCP file told us to process the same number of
    # records as we actually processed.  Treating as a warning for now...
    # should maybe flag this as an error.

    $mcpEntriesFromMCPFile = [Convert]::ToInt32((Get-EntryKeyValue($mcpFileContents[1]))[1], 10)
    if ($mcpEntriesFromMCPFile -ne $mcpEntry.Count)
    {
        Write-Warning "Difference in number of MCP entries from MCP file ($mcpEntriesFromMCPFile) and records parsed ($($mcpEntry.Count))."
    }

    #Write-Host "Done processing MCP file.  mcpEntry data:"

    #foreach ($entry in $mcpEntry.GetEnumerator())
    #{
    #    Write-Host "$($entry.Name): $($entry.Value)"
    #
    #    foreach ($valueEntry in $entry.value.GetEnumerator())
    #    {
    #        Write-Host "    $($valueEntry.Name): $($valueEntry.Value)"
    #    }
    #}

    # Return the mcpEntry collection to the caller.

    $mcpEntry
}

function Get-ATCSMonDB()
{
    if (Test-Path $atcsmonRoot)
    {
        Get-ChildItem -File -Filter 'atcsdb.mdb' -Path $atcsmonRoot
    }
}

function HandleMCPs([System.IO.FileInfo]$mcpFile)
{
    Write-Host "Processing an MCP/MDB file: " $mcpFile.FullName

    if (".mcp" -eq $mcpFile.Extension)
    {
        # Process with the MCP importer.

        $mcpCollection = Import-MCPFile $mcpFile

        $atcsDBFile = Get-ATCSMonDB
        $atcsDatabase = Open-Database($atcsDBFile)

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

        Get-DatabaseInfo($atcsDatabase)

        Close-Database($atcsDatabase)
    }
}

# Ensure the project root exists.

try
{
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
}
catch
{
    Write-Error $_
    [System.Environment]::Exit(1)
}
