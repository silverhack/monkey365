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

Function Get-MonkeyAIHubCognitiveAccountInfo {
    <#
        .SYNOPSIS
		Get AI Hub workspace metadata from Azure

        .DESCRIPTION
		Get AI Hub workspace metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAIHubWorkspaceInfo
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
        [String]$APIVersion = "2024-10-01"
    )
    Process{
        try{
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"AI Hub Cognitive Account");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureAIHubCognitiveAccountInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $aiHubCognitiveAccount = Get-MonkeyAzObjectById @p
            if($null -ne $aiHubCognitiveAccount){
                $cognitiveAccountObject = $aiHubCognitiveAccount | New-MonkeyAIHubCognitiveAccountObject
                #Get locks
                $cognitiveAccountObject.locks = $cognitiveAccountObject | Get-MonkeyAzLockInfo
                #Get Diagnostic settings
                $p = @{
                    Id = $cognitiveAccountObject.Id;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                If($diag){
                    $cognitiveAccountObject.diagnosticSettings.enabled = $true;
                    $cognitiveAccountObject.diagnosticSettings.name = $diag.name;
                    $cognitiveAccountObject.diagnosticSettings.id = $diag.id;
                    $cognitiveAccountObject.diagnosticSettings.properties = $diag.properties;
                    $cognitiveAccountObject.diagnosticSettings.rawData = $diag;
                }
                #Check permissions for identity if any
                If($null -ne $cognitiveAccountObject.identity){
                    $sp = $cognitiveAccountObject.identity | Select-Object -ExpandProperty principalId -ErrorAction Ignore
                    If($null -ne $sp){
                        #Get Principal
                        $p = @{
			                Ids = $sp;
                            APIVersion = "beta";
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
		                }
                        $principalObj = Get-MonkeyMSGraphDirectoryObjectById @p
                        If($principalObj){
                            $cognitiveAccountObject.identity | Add-Member -Type NoteProperty -Name objectPrincipalId -Value $principalObj
                            #Get permissions
                            $p = @{
			                    PrincipalId = $sp;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
		                    }
                            $rbac = Get-MonkeyAzIAMPermission @p
                            If($rbac){
                                $cognitiveAccountObject.identity | Add-Member -Type NoteProperty -Name permissions -Value $rbac
                            }
                        }
                    }
                }
                #Get Encryption
                $capabilities = $cognitiveAccountObject.properties | Select-Object -ExpandProperty capabilities -ErrorAction Ignore
                If($null -ne $capabilities){
                    $cmk = $capabilities.Where({$_.name -eq "CustomerManagedKey"}) | Select-Object -ExpandProperty Value -ErrorAction Ignore
                    If($null -eq $cmk){
                        $cognitiveAccountObject.cmkEncryption = $false;
                    }
                }
                #Return object
                return $cognitiveAccountObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}

