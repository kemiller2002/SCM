$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

. "$dir\GetItemOrderDependency.ps1"

$objectTypes = "U,FN,V,P,SQ,TF,TR".Split(",")

GetItemListing "Server=localhost\sqlexpress;Database=AdventureWorks2012;Trusted_Connection=True;" "AdventureWorks2012" $objectTypes | 
  select Values -Unique
