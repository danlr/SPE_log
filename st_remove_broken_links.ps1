#adapted 'Broken Links' SPE report


$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\Internet"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\Internet")])
$linksToCheck =  @("internal","external")
$linkTypes = [ordered]@{"Internal Links"="internal";"External Links"="external"};

$versionOptions = [ordered]@{
    "Latest"="1"
}

$props = @{
    Parameters = @(
        @{Name="root"; Title="Choose the report root"; Tooltip="Only items in this branch will be returned."; Columns=9},
        @{Name="searchVersion"; Value="1"; Title="Version"; Options=$versionOptions; Tooltip="Choose a version."; Columns="3"; Placeholder="All"}
    )
    Title = "Broken Links Report"
    Description = "Choose the criteria for the report."
    Width = 550
    Height = 300
    ShowHints = $true
}

$result = Read-Variable @props

if($result -eq "cancel"){
    exit
}

filter HasBrokenLink {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item,
        
        [Parameter()]
        [bool]$IncludeAllVersions
    )
    
    if($Item) {
        $brokenLinks = $item.Links.GetBrokenLinks($IncludeAllVersions)
        if($brokenlinks -ne $null -and $brokenlinks.Length -gt 0) {
            foreach($brokenLink in $brokenLinks) {
                $brokenItem = $brokenLink.GetSourceItem() | Initialize-Item
                Add-Member -InputObject $brokenItem -NotePropertyName "Broken Link Field" -NotePropertyValue ((Get-Item . -Database ($root.Database) -ID $brokenLink.SourceFieldID).Name)
                Add-Member -InputObject $brokenItem -NotePropertyName "Target Url" -NotePropertyValue $brokenLink.TargetPath
                Add-Member -InputObject $brokenItem -NotePropertyName "Status Code" -NotePropertyValue "Missing Target Item"
                $brokenItem
            }
        }
    }
}

function Remove-BrokenLinks($item){
    $brokenLinks = $item.Links.GetBrokenLinks((!$searchVersion))
    foreach($brokenLink in $brokenLinks) {
        $field = $item.Fields[$brokenLink.SourceFieldID]
        
        $customField = [Sitecore.Data.Fields.FieldTypeManager]::GetField($field)
        if (-not ($customField -eq $null)){
            $item.Editing.BeginEdit() > $null
            $customField.RemoveLink($brokenLink)
            $item.Editing.EndEdit() > $null
        }
    }
}

$items = Get-ChildItem -Path $root.ProviderPath -Recurse | HasBrokenLink -IncludeAllVersions (!$searchVersion)

if($items.Count -eq 0){
    Show-Alert "There are no items found which have broken links in the current language."
} else {

    $action = Show-ModalDialog -Control "ConfirmChoice" -Parameters @{btn_0="View report"; btn_1="Delete now"; te="View report or delete links?"; cp="Broken links action"} -Height 120 -Width 450

    if($action -eq "btn_0"){
        $props = @{
            Title = "Broken links report"
            InfoTitle = "$($items.Count) items with broken links found!"
            InfoDescription = "The report checked for $($linksToCheck -join ' & ') links in $(@('all versions','latest versions')[[byte]($searchVersion='1')]) of items."
            MissingDataMessage = "There are no items found which have broken links in the current language."
            PageSize = 25
        }
            
        $items |
            Show-ListView @props -Property "Status Code", "Broken Link Field","Target Url",
                @{Label="Name"; Expression={$_.DisplayName} },
                @{Label="Path"; Expression={$_.ItemPath} },
                "Version",
                "Language",
                @{Label="Updated"; Expression={$_.__Updated} },
                @{Label="Updated by"; Expression={$_."__Updated by"} }
    } else{
        write-host "Deleting"
        foreach($item in $items){
            Remove-BrokenLinks $item
        }
    }
}
Close-Window
