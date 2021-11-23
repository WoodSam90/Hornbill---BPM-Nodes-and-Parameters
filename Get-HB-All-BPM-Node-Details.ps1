clear-host

if(-not $loaded)
{
    . C:\Scripts\Hornbill\Config\Hornbill_API_Config.ps1
    $loaded = $true
}

# Define Variables
$bpmURLS = @()

# Retrieve Priorities using the Hornbill API
Clear-HB-Params

Add-HB-Param "application" "com.hornbill.servicemanager"
Add-HB-Param "entity" "priority"

$Priorities = (Invoke-HB-XMLMC "data" "entityBrowseRecords2").Params.rowData.row

# Retrieve the Business Processes using the Hornbill API
Clear-HB-Params

Add-HB-Param "application" "com.hornbill.servicemanager"
Open-HB-Element "orderBy"
    Add-HB-Param "column" "h_lastupdated_on"
    Add-HB-Param "direction" "descending"
Close-HB-Element "orderBy"
Add-HB-Param "type" "businessProcess"
Add-HB-Param "activeState" "active"

$BusinessProcesses = Invoke-HB-XMLMC "bpm" "workflowList"

foreach($process in $BusinessProcesses.Params.workflow)
{
    # Define Variables
    $processName    = $process.name
    $processTitle   = $process.title
    $processVersion = $process.version

    "`r`n".PadRight(30,"-") + "`r`n[$processTitle]"

    # Clear any HB Params
    # Get the details of the latest Business Process Version using the Hornbill API
    # Method = bpm and Service = workflowGet
    # The first parameter is the name and it's value is $processName
    # The second parameter is the version and it's value is $processVersion 
    # Invoke the API using the Method and store it's results in $processDefinition
    Clear-HB-Params
    Add-HB-Param "application" "com.hornbill.servicemanager"
    Add-HB-Param "name" $processName
    Add-HB-Param "version" $processVersion

    $processDefinition = Invoke-HB-XMLMC "bpm" "workflowGet"

    # Loop through each stage in the Business Process returned in $processDefinition
    foreach($processDefStage in $processDefinition.Params.definition.stage)
    {
        # Define Variables
        $processStageName = $processDefStage.displayName

        "`r`n" + " ".PadLeft(5," ") + "[$processStageName]"

        foreach($processDefStageFlow in $processDefStage.flow)
        {
            foreach($processDefStageFlowNode in $processDefStageFlow.node)
            {
                " ".PadLeft(10," ") + "[$($processDefStageFlowNode.displayName)]"
                
                if($processDefStageFlowNode.flowcode)
                {
                    foreach($processDefStageFlowNodeFlowcode in $processDefStageFlowNode.flowcode)
                    {
                        " ".PadLeft(15," ") + "[$($processDefStageFlowNodeFlowcode.method)]"
                        # Define Variables
                        foreach($FlowCodeParam in $processDefStageFlowNodeFlowcode.parameter)
                        {
                            $bpmURLS += [PSCustomObject]@{
                                BPM_Title       = $processTitle
                                BPM_Stage       = $processStageName
                                BPM_NodeID      = $processDefStageFlowNode.id
                                BPM_NodeName    = $processDefStageFlowNode.displayName
                                BPM_NodeParam   = $flowCodeParam.param
                                BPM_NodeAction  = $flowCodeParam.action
                                BPM_NodeValue   = $flowCodeParam.value 
                                BPM_URL         = "https://admin.hornbill.com/wbcservicedesk/app/com.hornbill.servicemanager/workflow/bpm/$processName/"
                            }

                            $flowParam = " ".PadLeft(20," ") + "[$($FlowCodeParam.param)]" + " : " + "[$($FlowCodeParam.value)]"
                            Write-Host $flowParam -ForegroundColor Gray
                            
                        }
                    }

                }
   
            }
        }
    }
}

$bpmURLS | export-csv -Path "c:\temp\WBC Priority BPMs.csv" -Force -NoTypeInformation