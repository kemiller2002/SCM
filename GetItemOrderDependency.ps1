param
(
    [string] $connectionString,
    [string] $database
)

$ExecuteReader = {
    param ($statement, $fnReader)
    
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    $connection.ChangeDatabase($database)


    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    $command.CommandText = $statement

    $reader = $command.ExecuteReader()
    
    while ($reader.Read()) 
    {
        $fnReader.Invoke($reader)
    }

    $reader.Dispose()
    $command.Dispose()
    $connection.Dispose()
}

$PopulateItemObject = {
    param($reader)

    $objectName = $reader.GetString(0)
    $schemaName = $reader.GetString(1)
    $type = $reader.GetString(2)

    @{
        Schema = $schemaName
        Object = $objectName
        Type = $type
    }
}

$GetObjectList = {
    param($executeReader, $objectType)

    $statement = "SELECT o.name AS ObjectName, s.name, o.type AS SchemaName FROM sys.objects o JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE 
        o.Type IN ('$objectType')"

    Invoke-Command $executeReader -ArgumentList $statement, $PopulateItemObject
}

$GetReferencingEntities = {

    param($executeReader, $itemDetails)

    $statement = "SELECT DISTINCT referenced_schema_name, referenced_entity_name FROM sys.dm_sql_referenced_entities ('KeyDeployment.SelectProducts','OBJECT') x 
	JOIN Sys.objects o ON x.referenced_id  = o.object_id
	AND o.type IN ('$($itemDetails.Type)')"

    @{
        Parent = $itemDetails
        Children = @($executeReader.Invoke($statement, $PopulateItemObject))
    }
}

$LookUpDependencies = {
    param(
        $items,
        $currentItem
    )
    
    foreach($item in $items.Children) 
    {
        $LookUpDependencies.Invoke($items, $_)
    }

    $currentItem.Parent

}

$BuildNameList = {
    param ($items)
    
    $items | foreach{$LookUpDependencies.Invoke($items, $_)}
}



#$items = 
"FN,V,P".Split(',') | 
    foreach{ $GetObjectlist.Invoke($ExecuteReader, $_) } | 
    foreach {$GetReferencingEntities.Invoke($ExecuteReader, $_)} |
    Group-Object {$_.Parent.Type} | 
    foreach{$BuildNameList.Invoke($_.Group)} | 
    foreach{Write-Host $_.Object}
    #


#Write-Host "$($items[0].Name)"
