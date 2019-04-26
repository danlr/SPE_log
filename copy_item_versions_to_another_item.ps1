$fromId = "{9D24A350-7900-474B-BC33-C35305317B9F}"
$toId = "{A8C7F350-D95F-495A-BACC-0B65BEECB0B9}"

Remove-ItemVersion -id $toId -Language * -ExcludeLanguage en

$fromItemVersions = Get-Item -path "master:" -id $fromId -Language *

foreach($sourceVersion in $fromItemVersions){
    Add-ItemVersion -id $toId -Language en -TargetLanguage $sourceVersion.Language -database "master" -DoNotCopyFields
    
    $newItemVersion = Get-Item -path "master:" -id $toId -Language $sourceVersion.Language
    
    $newItemVersion.Editing.BeginEdit() > $null
    $newItemVersion["Value"] = $sourceVersion["Value"]
    $newItemVersion.Editing.EndEdit() > $null
}
