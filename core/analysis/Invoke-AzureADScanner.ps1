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

Function Invoke-EntraIDScanner{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-EntraIDScanner
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param()
    try{
        if($null -ne $O365Object.Collectors -and @($O365Object.Collectors).Count -gt 0){
            #Get Execution Info
            $O365Object.executionInfo = Get-ExecutionInfo
            #Set synchronized hashtable
            Set-Variable returnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
            if($O365Object.IncludeEntraID){
                #Set params
                $p = @{
                    Provider = 'EntraID';
                    Throttle = $O365Object.threads;
                    ReturnData = $Script:returnData;
                    Debug = $O365Object.Debug;
                    Verbose = $O365Object.Verbose;
                    InformationAction = $O365Object.InformationAction;
                }
                #Launch collectors
                Invoke-MonkeyScanner @p
            }
            if($Script:ReturnData.Count -gt 0){
                #Prepare output
                Out-MonkeyData -OutData $returnData
            }
            else{
                $msg = @{
                    MessageData = "There is no data to export";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('EntraIDScanner');
                }
                Write-Warning @msg
            }
        }
    }
    Catch{
        Write-Error $_
    }
    Finally{
        #Perform garbage collection
        [gc]::Collect()
    }
}


