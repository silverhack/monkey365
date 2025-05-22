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

Function Get-MonkeyAzNetworkWatcherFlowLog {
    <#
        .SYNOPSIS
		Get Azure Network Watcher Flow Log metadata

        .DESCRIPTION
		Get Azure Network Watcher Flow Log metadata

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzNetworkWatcherFlowLog
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2024-05-01"
    )
    Process{
        try{
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Azure Network Watcher Flow Log");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureNetworkWatcherInfo');
			}
			Write-Information @msg
            #Get Network Security groups
            $nsg = @($O365Object.all_resources).Where({ $_.type -like 'Microsoft.Network/networkSecurityGroups' -or $_.type -like 'Microsoft.ClassicNetwork/networkSecurityGroups' }) | Select-Object id,location -ErrorAction Ignore
            #Get region
            $nwsRegion = @($nsg).Where({ $_.location -eq $InputObject.location }) | Select-Object -ExpandProperty id -ErrorAction Ignore
            If ($nwsRegion) {
				ForEach ($network in $nwsRegion) {
                    #Get flow log
					$POSTDATA = @{ "TargetResourceId" = $network; } | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
					$Id = ("{0}/queryFlowLogStatus" -f $InputObject.Id)
                    $p = @{
			            Id = $Id;
                        ApiVersion = $APIVersion;
                        Data = $POSTDATA;
                        Method = "POST";
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
		            }
		            $flowLogCnf = Get-MonkeyAzObjectById @p
                    If($flowLogCnf){
                        $flowObj = $flowLogCnf | New-MonkeyNetworkWatcherFlowLogObject
                        return $flowObj
                    }
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
