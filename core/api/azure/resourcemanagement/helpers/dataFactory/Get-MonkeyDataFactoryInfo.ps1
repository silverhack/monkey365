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

Function Get-MonkeyDataFactoryInfo {
    <#
        .SYNOPSIS
		Get Data Factory metadata from Azure

        .DESCRIPTION
		Get Data Factory metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyDataFactoryInfo
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
        [String]$APIVersion = "2018-06-01"
    )
    Process{
        try{
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Data Factory");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureDataFactoryInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $dataFactory = Get-MonkeyAzObjectById @p
            if($null -ne $dataFactory){
                $dataFactoryObject = $dataFactory | New-MonkeyDataFactoryObject
                #Get locks
                $dataFactoryObject.locks = $dataFactoryObject | Get-MonkeyAzLockInfo
                #Get private endpoints
                $dataFactoryObject.privateEndpoints = $dataFactoryObject | Get-MonkeyAzDataFactoryPrivateEndpointConnection
                #Get Diagnostic settings
                $p = @{
                    Id = $dataFactoryObject.Id;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                If($diag){
                    $dataFactoryObject.diagnosticSettings.enabled = $true;
                    $dataFactoryObject.diagnosticSettings.name = $diag.name;
                    $dataFactoryObject.diagnosticSettings.id = $diag.id;
                    $dataFactoryObject.diagnosticSettings.properties = $diag.properties;
                    $dataFactoryObject.diagnosticSettings.rawData = $diag;
                }
                #Check permissions for identity if any
                If($null -ne $dataFactoryObject.identity){
                    $sp = $dataFactoryObject.identity | Select-Object -ExpandProperty principalId -ErrorAction Ignore
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
                            $dataFactoryObject.identity | Add-Member -Type NoteProperty -Name objectPrincipalId -Value $principalObj
                            #Get permissions
                            $p = @{
			                    PrincipalId = $sp;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
		                    }
                            $rbac = Get-MonkeyAzIAMPermission @p
                            If($rbac){
                                $dataFactoryObject.identity | Add-Member -Type NoteProperty -Name permissions -Value $rbac
                            }
                        }
                    }
                }
                #Return object
                return $dataFactoryObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
