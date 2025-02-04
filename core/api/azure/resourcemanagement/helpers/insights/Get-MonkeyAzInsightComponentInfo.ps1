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

Function Get-MonkeyAzInsightComponentInfo {
    <#
        .SYNOPSIS
		Get Insight Component metadata from Azure

        .DESCRIPTION
		Get Insight Component metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzInsightComponentInfo
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
        [String]$APIVersion = "2020-02-02"
    )
    Process{
        try{
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Insight Component");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureInsightComponentInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $component = Get-MonkeyAzObjectById @p
            if($null -ne $component){
                $insightComponentObj = $component | New-MonkeyInsightComponentObject
                #Get Locks
                $insightComponentObj.locks = $insightComponentObj | Get-MonkeyAzLockInfo
                $p = @{
		            Id = $insightComponentObj.Id;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $diag = Get-MonkeyAzDiagnosticSettingsById @p
                if($diag){
                    #Add to object
                    $insightComponentObj.diagnosticSettings.enabled = $true;
                    $insightComponentObj.diagnosticSettings.name = $diag.name;
                    $insightComponentObj.diagnosticSettings.id = $diag.id;
                    $insightComponentObj.diagnosticSettings.properties = $diag.properties;
                    $insightComponentObj.diagnosticSettings.rawData = $diag;
                }
                #Return object
                return $insightComponentObj
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}

