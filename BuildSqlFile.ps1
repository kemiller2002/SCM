
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

. "$dir\GetItemOrderDependency.ps1"

$GetPath = {

    param($item, $pathToDataFiles)
    
    $path =  switch ($_.Type) {
         "U"  {"Tables"}
         "FN" {"Funtions"}
         "V"  {"Views"}
         "P"  {"Stored Procedures"}
         "SQ" {"Service Queue"}
         "TF" {"SQL Table Valued Function"}
         "TR" {"SQL Trigger"}
    }

    "$pathToDataFiles\$path"

}

$MakeListForItem = {
    param(  $updatedItems,
            $allItems,
            $pathToDataFiles)

    $updateItemPaths = @($updatedItems | foreach {"$($GetPath.Invoke($_, $pathToDataFiles))\$($_.Schema).$($_.Object).sql" })

    $allItemPaths = @($allItems | select -ExpandProperty FullName)
    
    $updateItemPaths + $allItemPaths | Select -Unique
}

function GetSqlFileList 
{
    param (
        [string]  $pathToDataFiles
        ,[string] $connectionString
        ,[string] $database
    )

    $objectTypes = "U,FN,V,P".Split(",")
    
    $allItems = Get-ChildItem $pathToDataFiles -Recurse | Where {$_.Extension -eq ".sql" } | Group Directory
    
    $updatedItems = GetItemListing $connectionString $database $objectTypes | Group {$GetPath.Invoke($_, $pathToDataFiles)}
    
    $masterList = $updatedItems | foreach {
    
        $updateItem = $_
        $allItemGroup = $allItems | Where {$updateItem.Name -eq $_.Name} | Select -ExpandProperty Group
        $updateItemGroup = $updateItem | Select -ExpandProperty Group
    
        $MakeListForItem.Invoke($updateItemGroup, $allItemGroup, $pathToDataFiles)
    }
    $masterList 
}      r tte