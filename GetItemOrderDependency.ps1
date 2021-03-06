﻿function GetItemListing {
    param($connectionString, $database, $databaseObjectTypes)
    

$ExecuteReader = {
    param ($statement, $fnReader)

    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    $connection.ChangeDatabase($database)


    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    $command.CommandText = $statement
    try{
        $reader = $command.ExecuteReader()
       
        if($reader.HasRows){
            while ($reader.Read()) 
            {
                $fnReader.Invoke($reader)
            }
        }
    }
    catch [System.Exception] {
         $exception = New-Object System.Exception "There was a problem with executing the following sql statement.
            This could be a problem with an out of date stored procedure which during recompile
            exposed fields or tables which no longer exist: $statement


            $($_.Message)"
         
         #$Error.Add($exception)

         throw $exception
    }
    finally {
        $reader.Dispose()
        $command.Dispose()
        $connection.Dispose()
    }   
}

$PopulateItemObject = {
    param($reader)

    $objectName = $reader.GetString(0)
    $schemaName = $reader.GetString(1)
    $type = $reader.GetString(2)

    @{
        Schema = $schemaName
        Object = $objectName
        Type = $type.Trim()
    }
}

$GetObjectList = {
    param($executeReader, $objectType)

    $statement = "SELECT o.name AS ObjectName, s.name, o.type AS SchemaName FROM sys.objects o JOIN sys.schemas s ON o.schema_id = s.schema_id WHERE 
        o.Type IN ('$objectType') AND o.Name NOT LIKE 'sp_%' AND o.Name NOT LIKE 'fn_%' AND o.Name NOT LIKE 'sys%' "

    Invoke-Command $executeReader -ArgumentList $statement, $PopulateItemObject
}

$GetReferencingEntities = {

    param($executeReader, $itemDetails)

    $statement = switch($itemDetails.Type) {
        "U" {"	SELECT cs.name, co.name, co.Type FROM sys.sysreferences r
		JOIN sys.objects co ON r.rkeyid = co.object_id 
		JOIN sys.schemas cs ON co.schema_id = cs.schema_id
		
		JOIN sys.objects po ON r.fkeyid = po.object_id 
		JOIN sys.schemas ps ON po.schema_id = ps.schema_id
		WHERE 
			po.Name = '$($itemDetails.Object)'
			AND 
			ps.Name = '$($itemDetails.Schema)'"}

        default {"SELECT DISTINCT referenced_schema_name, referenced_entity_name, type FROM 
            sys.dm_sql_referenced_entities ('$($itemDetails.Schema).$($itemDetails.Object)','OBJECT') x 
	        JOIN Sys.objects o ON x.referenced_id  = o.object_id
	        AND o.type IN ('$($itemDetails.Type)')"}
    }

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
        $LookUpDependencies.Invoke($item, $_) #changed items to item
    }

    $currentItem.Parent

}

$BuildNameList = {
    param ($items)
    
    $items | foreach{$LookUpDependencies.Invoke($items, $_)}
}

$databaseObjectTypes | 
    foreach{ $GetObjectlist.Invoke($ExecuteReader, $_) } | 
    foreach {$GetReferencingEntities.Invoke($ExecuteReader, $_)} |
    Group-Object {$_.Parent.Type}  | 
    foreach{$BuildNameList.Invoke($_.Group)} 
}