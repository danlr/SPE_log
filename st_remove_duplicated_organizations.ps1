function Clean-Duplicates($path) {
     $items = Get-ChildItem -Path $path -Recurse | Where-Object { -not ($_.TemplateName -eq 'Bucket') -and -not ($_.Name -eq 'Content Elements') }
     
     foreach($item in $items){
         $dblPath = "$($item.ItemPath) 1"
         
         $dubl = Get-Item -Path $dblPath -ErrorAction SilentlyContinue
         
         if ( -not ($dubl-eq $null) -and ($dubl."GAdmin uuid" -eq $item."GAdmin uuid") ){
             write-host $dubl.ItemPath
             Remove-Links $dubl
             Remove-Item -Path $dubl.ItemPath -Recurse
         }
     }
}


function Remove-Links($item){
    $linkDb = [Sitecore.Globals]::LinkDatabase

    $links = $linkDb.GetReferrers($item)
    
    foreach($link in $links) {
        $linkedItem = Get-Item -Path master:\ -ID $link.SourceItemID 
        
        write-host "Linked item:" $linkedItem.ItemPath
        
        $itemField = $linkedItem.Fields[$link.SourceFieldID]
        $field = [Sitecore.Data.Fields.FieldTypeManager]::GetField($itemField)
    
        $linkedItem.Editing.BeginEdit()
        $field.RemoveLink($link)
        $linkedItem.Editing.EndEdit()
    }
}

Clean-Duplicates "master:/sitecore/content/Resources/Organisations"
