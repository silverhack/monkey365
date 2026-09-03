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

Function Get-MonkeyAzNetworkWatcherInfo {
    <#
        .SYNOPSIS
		Get Azure Network Watcher metadata

        .DESCRIPTION
		Get Azure Network Watcher metadata

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzNetworkWatcherInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Network Watcher Object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-05-01"
    )
    Process{
        try{
            #Set array
            $allFlowLogs = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Azure Network Watcher");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureNetworkWatcherInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $_object = Get-MonkeyAzObjectById @p
            If($null -ne $_object){
                $networkWatcherObj = $_object | New-MonkeyNetworkWatcherObject
                #Get Associated flog log if any
                $p = @{
			        Id = $networkWatcherObj.Id;
                    Resource = "flowLogs";
                    ApiVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
                $flowLogs = Get-MonkeyAzObjectById @p
                ForEach($flowLog in @($flowLogs).Where({$null -ne $_})){
                    [void]$allFlowLogs.Add($flowLog);
                }
                #Add to object
		        $networkWatcherObj.flowLogs = $allFlowLogs;
                #Get Locks
                $networkWatcherObj.locks = $networkWatcherObj | Get-MonkeyAzLockInfo
                #return object
                return $networkWatcherObj
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
