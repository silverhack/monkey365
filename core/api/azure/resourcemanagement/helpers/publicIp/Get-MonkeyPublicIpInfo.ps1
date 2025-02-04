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

Function Get-MonkeyPublicIpInfo {
    <#
        .SYNOPSIS
		Get Public IP metadata from Azure

        .DESCRIPTION
		Get Public IP metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPublicIpInfo
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
        [String]$APIVersion = "2024-01-01"
    )
    Process{
        try{
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Public IP");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePublicIPInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $publicIp = Get-MonkeyAzObjectById @p
            if($null -ne $publicIp){
                $publicIpObject = $publicIp | New-MonkeyPublicIpObject
                #Get diagnostic settings
                $p = @{
		            Id = $publicIpObject.Id;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $diag = Get-MonkeyAzDiagnosticSettingsById @p
                if($diag){
                    #Add to object
                    $publicIpObject.diagnosticSettings.enabled = $true;
                    $publicIpObject.diagnosticSettings.name = $diag.name;
                    $publicIpObject.diagnosticSettings.id = $diag.id;
                    $publicIpObject.diagnosticSettings.properties = $diag.properties;
                    $publicIpObject.diagnosticSettings.rawData = $diag;
                }
                #Return object
                return $publicIpObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}

