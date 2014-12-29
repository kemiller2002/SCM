param (
    [string]  $pathToDataFiles
    ,[string] $connectionString
    ,[string] $database
)
    
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

. "$dir\BuildSqlFile.ps1"

$PreMigration = {
    "PreMigration".Split(',')
}

$MakePaths = {
    param($pathToDataFiles, $getPaths)

    $getPaths.Invoke() | foreach{"$pathToDataFiles\$_"}
}

$PostMigration = {
    $migrationDirectories = "StaticData,PostMigration".Split(',')
}

$GetAllFiles = {
    param($pathToDataFiles)

    $pullSqlFiles = {
        param($pathToDataFiles, $getFolders)

        $MakePaths.Invoke($pathToDataFiles, $getFolders) | 
        foreach {Get-ChildItem $_ -Recurse -Filter "*.sql" } | 
        Select -ExpandProperty FullName 
    }

    $preMigrationPaths = $pullSqlFiles.Invoke($pathToDataFiles, $PreMigration)

    $dataPaths = GetSqlFileList $pathToDataFiles $connectionString $database

    $PostMigrationPaths = $pullSqlFiles.Invoke($pathToDataFiles, $PostMigration)

    $preMigrationPaths + $dataPaths + $PostMigrationPaths
}

$MakeHeader = {
    param($fileName)
"
GO
RAISERROR('**********************************************************************************', 0, 0) WITH NOWAIT
RAISERROR('*', 0, 0) WITH NOWAIT
RAISERROR('* Starting Migration of: $fileName', 0, 0) WITH NOWAIT
RAISERROR('*', 0, 0) WITH NOWAIT
RAISERROR('**********************************************************************************', 0, 0) WITH NOWAIT
  
"

}

$MakeFooter = {
    param($fileName)
"

RAISERROR('**********************************************************************************', 0, 0) WITH NOWAIT
RAISERROR('*', 0, 0) WITH NOWAIT
RAISERROR('* Ending Migration of: $fileName', 0, 0) WITH NOWAIT
RAISERROR('*', 0, 0) WITH NOWAIT
RAISERROR('**********************************************************************************', 0, 0) WITH NOWAIT
   
"
    

}


$GetAllFiles.Invoke($pathToDataFiles) | foreach {
    $MakeHeader.Invoke($_)
    Get-Content $_
    $MakeFooter.Invoke($_)
}