# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Get-MonkeyVMConfigurationManagement{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyVMConfigurationManagement
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="VM object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2024-04-01"
    )
    Process{
        #Set array
		$configurationManagement = [System.Collections.Generic.List[System.Object]]::new()
        $query = ("GuestConfigurationResources\n    | extend vmid = split(properties.targetResourceId,'/')\n    | where id startswith strcat(\'{0}',\'/\')\n    | extend resources = parse_json(properties.latestAssignmentReport.resources)\n    | extend totalResources = array_length(resources)\n    | mv-expand complianceResourceExpanded=properties.latestAssignmentReport.resources limit 400\n    | extend compliantState=complianceResourceExpanded.complianceStatus\n    | summarize totalResourcesCount=count(), totalNonCompliantResourcesCount=countif(compliantState != 'true'),\n    totalCompliantResourcesCount=countif(compliantState== 'true') by id, complianceState = tostring(properties.complianceStatus),\n    version = iif(isempty(tostring(properties.guestConfiguration.version)) or isnull(tostring(properties.guestConfiguration.version)), '-', tostring(properties.guestConfiguration.version)),\n    name = tostring(properties.guestConfiguration.name),\n    assignmentType = iif(isempty(tostring(properties.guestConfiguration.assignmentType)) or isnull(tostring(properties.guestConfiguration.assignmentType)), 'Audit', tostring(properties.guestConfiguration.assignmentType)),\n    policyAssignmentId = iif(isempty(tostring(properties.policyAssignmentId)) or isnull(tostring(properties.policyAssignmentId)), '', tostring(properties.policyAssignmentId)),\n    machine = tostring(vmid[(-1)]), type = tostring(vmid[(-3)]), kind, tags = tostring(tags),  location, resourceGroup, subscriptionId,\n    assignmentSource = iif(isempty(tostring(properties.guestConfiguration.assignmentSource)) or isnull(tostring(properties.guestConfiguration.assignmentSource)), \'Not available\', tostring(properties.guestConfiguration.assignmentSource))\n    | extend compliantPercentage = tostring(toint((totalCompliantResourcesCount)/todouble(totalResourcesCount)*100)), nonCompliantPercentage = tostring(toint((totalNonCompliantResourcesCount)/todouble(totalResourcesCount)*100))\n    | extend complianceState=iif(strcmp(complianceState,\'NonCompliant\')==0, \'Non-compliant\', complianceState)\n    | project complianceState, version, name, assignmentType, machine, type, id, kind, tags, location, resourceGroup,\n    subscriptionId, compliantPercentage, nonCompliantPercentage, totalResourcesCount, totalCompliantResourcesCount,\n    totalNonCompliantResourcesCount, assignmentSource, policyAssignmentId | where assignmentType in~ (\'ApplyAndAutoCorrect\', \'ApplyAndMonitor\', \'Audit\') and assignmentSource in~ (\'Azure Policy\', \'Azure Security Center\', \'Manual assignment\', \'Not available\') and complianceState in~ (\'Compliant\', \'Non-compliant\', \'Pending\')" -f $InputObject.Id);
        #Data object
        $data = @{
            subscriptions = @($O365Object.current_subscription.subscriptionId);
            query = $query;
        } | ConvertTo-Json -Depth 10 -Compress | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        $p = @{
            Resource = '/providers/Microsoft.ResourceGraph/resources';
            Method = 'POST';
            Data = $data;
            ApiVersion = $APIVersion;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
            InformationAction = $O365Object.InformationAction;
		}
		$result = Get-MonkeyAzObjectById @p
        if($result){
            foreach($element in $result.data.GetEnumerator()){
                $obj = $element | New-MonkeyVMConfigurationManagementObject
                #Add to array
                [void]$configurationManagement.Add($obj);
            }
        }
        #return object
        Write-Output $configurationManagement -NoEnumerate
    }
}
