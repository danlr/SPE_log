<#
based on https://gist.github.com/marcduiker/950e0358bb4752ed5b047931a8c958c1
#>

# This is the ID of the workflow that will be set on the content items.
$script:workflowID = "{18AA8C2E-4F06-4B50-A8EC-40DBA74E8BA3}" #Content Workflow

# This is the ID of the workflow state that will be set on the content items.
$script:workflowStateID = "{02117B0E-0B07-4868-B2B9-CD7472782705}" #Approved State

# This is the ID of the workflow state that will be set on the locaked versions.
$script:workflowDraftStateID = "{F9CAFF4A-A2DE-4755-AD57-A7B5DF65005F}" #Draft State

function GetTemplatesWhichUseTheWorkflow()
{
    $itemsWithMatchingDefaultWorkflow = Get-Item -Path master: -Query "/sitecore/templates//*[@__Default workflow='$script:workflowID']"
    
    Write-Host "Templates which use workflow" $script:workflowID":"
    foreach ($item in $itemsWithMatchingDefaultWorkflow)
    {
        # The Default workflow field can only be set for __Standard Value items but checking that nevertheless.
        if ($item.Name -eq "__Standard Values")
        {
            $script:templateIDsWithDefaultWorkflow.Add($item.TemplateID) > $null # The output of the Add is ignored
            #Write-Host " -" $item.TemplateName $item.TemplateID
        }
    }
}

function SetWorkflowAndState([Sitecore.Data.Items.Item]$item)
{
    $item.Editing.BeginEdit()
    $item.Fields["__Workflow"].Value = $script:workflowID
    
    if ($item.Locking.IsLocked()){
        $item.Fields["__Workflow state"].Value = $script:workflowDraftStateID
    }else{
        $item.Fields["__Workflow state"].Value = $script:workflowStateID
    }
    
    $item.Editing.EndEdit($false, $true) > $null
    $script:itemCount++
    Write-Host "  " $item.ItemPath "[" $item.Language "]"
}

function ProcessContentItems()
{
    # Update only the content items for the matching templateIDs and an empty Workflow state field and target default workflow.
    # And do not overwrite if already set something
    Write-Host "Updating content items to set workflow to" $script:workflowID "and state to" $script:workflowStateID":" 
    $processedItems = Get-ChildItem -Path "master:/sitecore/content" -Language * -Version * -Recurse | Where-Object { ($script:templateIDsWithDefaultWorkflow.Contains($_.TemplateID)) -and ($_."__Workflow state" -eq "") -and ($_["{CA9B9F52-4FB0-4F87-A79F-24DEA62CDA65}"] -eq $script:workflowID)} 
                
    foreach($item in $processedItems){
        SetWorkflowAndState($item)
    }
    
    Write-Host "# of processed items:" $script:itemCount
}

# An ArrayList is used instead of the the default PS Array because the latter is immutable and not efficient when working with large arrays.
$script:templateIDsWithDefaultWorkflow = New-Object System.Collections.ArrayList

# Counter to keep track of the updated content items. 
$script:itemCount = 0

GetTemplatesWhichUseTheWorkflow

if ($script:templateIDsWithDefaultWorkflow.Count -eq 0)
{
    Write-Warning "No templates found which use the workflow."
}
else
{
    ProcessContentItems
}

Write-Host "Done."
