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

Function Get-MonkeyAzNetworkSecurityGroupInfo {
    <#
        .SYNOPSIS
		Get network security group info from Azure

        .DESCRIPTION
		Get network security group info from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzNetworkSecurityGroupInfo
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
        [String]$APIVersion = "2025-05-01"
    )
    Begin{
        $config = @($O365Object.internal_config.resourceManager).Where({$_.Name -eq "DiagnosticSettings"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
        If($config){
            $diag_settings_api_Version = $config.api_version;
        }
        Else{
            #Fallback
            $diag_settings_api_Version = "2021-05-01-preview"
        }
    }
    Process{
        try{
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Network Security Group");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureNSGInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                Expand = 'subnets,networkinterfaces';
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $nsg = Get-MonkeyAzObjectById @p
            If($null -ne $nsg){
                $nsgObject = $nsg | New-MonkeyNetworkSecurityGroupObject
                #Get Locks
                $nsgObject.locks = $nsg | Get-MonkeyAzLockInfo
                #Get diagnostic settings
                If($InputObject.supportsDiagnosticSettings -eq $True){
                    $p = @{
		                Id = $nsgObject.Id;
                        ApiVersion = $diag_settings_api_Version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    if($diag){
                        #Add to object
                        $nsgObject.diagnosticSettings.enabled = $true;
                        $nsgObject.diagnosticSettings.name = $diag.name;
                        $nsgObject.diagnosticSettings.id = $diag.id;
                        $nsgObject.diagnosticSettings.properties = $diag.properties;
                        $nsgObject.diagnosticSettings.rawData = $diag;
                    }
                }
                #Flatten destinationPortRange and destinationPortRanges
                ForEach($rule in $nsgObject.securityRules.Where({$null -ne $_})){
                    #Set integer arrays
		            $destinationPortRange = [System.Collections.Generic.List[System.Int32]]::new()
                    $destinationPortRanges = [System.Collections.Generic.List[System.Int32]]::new()
                    #Check destinationPortRange
                    $dpr = $rule.properties | Select-Object -ExpandProperty destinationPortRange -ErrorAction Ignore
                    If($null -ne $dpr){
                        If($dpr.ToString() -match "-"){
                            $range = [System.Linq.Enumerable]::Range($dpr.Split('-')[0],$dpr.Split('-')[1]);
                            $_dpr = [System.Linq.Enumerable]::ToList($range);
                            #Add to array
                            [void]$destinationPortRange.AddRange($_dpr);
                        }
                        Else{
                            #Add to array
                            [void]$destinationPortRange.Add($dpr);
                        }
                        #Add to property
                        $rule.properties | Add-Member -MemberType NoteProperty -Name flattenedDestinationPortRange -Value $destinationPortRange -Force
                    }
                    #Check destinationPortRanges
                    $dprs = $rule.properties | Select-Object -ExpandProperty destinationPortRanges -ErrorAction Ignore
                    If($null -ne $dprs){
                        ForEach($dpr in @($dprs)){
                            If($dpr.ToString() -match "-"){
                                $range = [System.Linq.Enumerable]::Range($dpr.Split('-')[0],$dpr.Split('-')[1]);
                                $_dpr = [System.Linq.Enumerable]::ToList($range);
                                #Add to array
                                [void]$destinationPortRanges.AddRange($_dpr);
                            }
                            Else{
                                #Add to array
                                [void]$destinationPortRanges.Add($dpr);
                            }
                            #Add to property
                            $rule.properties | Add-Member -MemberType NoteProperty -Name flattenedDestinationPortRanges -Value $destinationPortRanges -Force
                        }
                    }
                }
                #Return object
                return $nsgObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
