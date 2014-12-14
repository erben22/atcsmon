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

