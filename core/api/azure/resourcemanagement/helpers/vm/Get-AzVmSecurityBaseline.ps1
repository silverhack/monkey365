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

Function Get-AzVmSecurityBaseline {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-AzVmSecurityBaseline
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
            [Parameter(HelpMessage="VM")]
            [object]
            $vm
    )
    Begin{
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure LogAnalytics Auth
        $AnalyticsAuth = $O365Object.auth_tokens.LogAnalytics
        #Check table SecurityBaseline
        $WorkSpaceId = $vm.properties.resourceDetails | Where-Object {$_.name -eq 'Reporting workspace customer id'} | Select-Object -ExpandProperty value
        if(-NOT $WorkSpaceId){
            #Try to get analytics path from Microsoft Monitoring agent
            $agent = $vm | Where-Object {$_.properties.extensions.extension -match "MicrosoftMonitoringAgent" -or $_.resources.id -match "OmsAgentForLinux"}
            if($agent){
                $WorkSpaceId = $agent.parameters.public.workspaceId
            }
        }
        #End Checks
    }
    Process{
        if($workspaceid){
            $checkTable = "set query_take_max_records=1;set truncationmaxsize=67108864;\nSecurityBaseline"
            $requestBody = @{"query" = $checkTable;}
            #Convert to JSON data
            $checkJson = $requestBody | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
            $URI = ("{0}v1/workspaces/{1}/query" -f $O365Object.Environment.LogAnalytics, $workspaceid)
            #POST Request
            $params = @{
                Authentication = $AnalyticsAuth;
                OwnQuery = $URI;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "POST";
                Data = $checkJson;
            }
            $tableExists = Get-MonkeyRMObject @params
        }
        else{
            $msg = @{
                MessageData = ($message.WorkSpaceIdNotFoundMessage -f $vm.name);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $InformationAction;
                Tags = @('AzureVMInfo');
            }
            Write-Debug @msg
        }
    }
    End{
        if($tableExists){
            $msg = @{
                MessageData = ($message.AzureUnitResourceMessage -f $vm.name, "Security Baseline");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('AzureVMInfo');
            }
            Write-Information @msg
            $query = ('let query = \nSecurityBaseline\n| where AnalyzeResult == \"{0}\" and Computer contains \"{1}\" \n| summarize AggregatedValue = dcount(BaselineRuleId) by BaselineRuleId, RuleSeverity, SourceComputerId, BaselineId, BaselineType, OSName, CceId, BaselineRuleType, Description, RuleSetting, ExpectedResult, ActualResult | sort by RuleSeverity asc| limit 1000000000; query' -f "Failed", $vm.name)
            #Convert to JSON data
            $requestBody = @{"query" = $query;"timespan" = 'PT24H'}
            $JsonData = $requestBody | ConvertTo-Json -Depth 50 | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
            $URI = ("{0}v1/workspaces/{1}/query" -f $O365Object.Environment.LogAnalytics, $workspaceid)
            #POST Request
            $params = @{
                Authentication = $AnalyticsAuth;
                OwnQuery = $URI;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "POST";
                Data = $JsonData;
            }
            $AllSecurityBaseline = Get-MonkeyRMObject @params
            $columns = $AllSecurityBaseline.tables.columns
            $rows = $AllSecurityBaseline.tables.rows
            if($rows -and $columns){
                foreach ($update in $rows){
                    $MonkeySecBaselineObject = New-Object -TypeName PSCustomObject
                    $MonkeySecBaselineObject | Add-Member -type NoteProperty -name ServerName -value $vm.name
                    $MonkeySecBaselineObject | Add-Member -type NoteProperty -name ResourceGroupName -value $vm.id.Split("/")[4]
                    for ($counter=0; $counter -lt $update.Length; $counter++){
                        $MonkeySecBaselineObject | Add-Member -type NoteProperty -name $columns[$counter].name -value $update[$counter]
                    }
                    [void]$AllSecBaseline.Add($MonkeySecBaselineObject)
                }
            }
        }
        else{
            $msg = @{
                MessageData = ($message.SecurityBaselineENotFoundMessage -f $vm.name);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $InformationAction;
                Tags = @('AzureVMInfo');
            }
            Write-Debug @msg
        }
    }
}
