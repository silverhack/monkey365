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

Function Get-MonkeyDataBrickWorkspaceInfo {
    <#
        .SYNOPSIS
		Get Databrick workspace metadata from Azure

        .DESCRIPTION
		Get Databrick workspace metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyDataBrickAccessConnectorInfo
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
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"DataBricks workspaces");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureDataBricksInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $workspace = Get-MonkeyAzObjectById @p
            if($null -ne $workspace){
                $workspaceObject = $workspace | New-MonkeyDataBrickWorkspaceServiceObject
                #Get locks
                $workspaceObject.locks = $workspace | Get-MonkeyAzLockInfo
                #Check Properties
                $parameters = $workspaceObject.properties | Select-Object -ExpandProperty parameters -ErrorAction Ignore
                #Evaluate parameters
                If($null -ne $parameters){
                    #Get FedRamp cert value
                    $enableFedRampCertification = $parameters | Select-Object -ExpandProperty enableFedRampCertification -ErrorAction Ignore
                    If($null -ne $enableFedRampCertification){
                        $workspaceObject | Add-Member -Type NoteProperty -Name enableFedRampCertification -Value $enableFedRampCertification.value;
                    }
                    #Get infrastructure encryption
                    $requireInfrastructureEncryption = $parameters | Select-Object -ExpandProperty requireInfrastructureEncryption -ErrorAction Ignore
                    If($null -ne $requireInfrastructureEncryption){
                        $workspaceObject | Add-Member -Type NoteProperty -Name requireInfrastructureEncryption -Value $requireInfrastructureEncryption.value;
                    }
                    #Get public ip
                    $publicIpName = $parameters | Select-Object -ExpandProperty publicIpName -ErrorAction Ignore
                    If($null -ne $publicIpName){
                        $workspaceObject | Add-Member -Type NoteProperty -Name publicIpName -Value $publicIpName.value;
                    }
                    #Get prepare encryption
                    $prepareEncryption = $parameters | Select-Object -ExpandProperty prepareEncryption -ErrorAction Ignore
                    If($null -ne $prepareEncryption){
                        $workspaceObject | Add-Member -Type NoteProperty -Name prepareEncryption -Value $prepareEncryption.value;
                    }
                }
                #Get Authorizations
                $authorizations = $workspaceObject.properties | Select-Object -ExpandProperty authorizations -ErrorAction Ignore
                If($null -ne $authorizations){
                    ForEach ($authorization in @($authorizations)){
                        $principalId = $authorization | Select-Object -ExpandProperty principalId -ErrorAction Ignore
                        If($null -ne $principalId){
                            #Get Principal
                            $p = @{
			                    Ids = $principalId;
                                APIVersion = "beta";
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
		                    }
                            $principalObj = Get-MonkeyMSGraphDirectoryObjectById @p
                            If($null -ne $principalObj){
                                $authorization | Add-Member -Type NoteProperty -Name identity -Value $principalObj;
                            }
                            Else{
                                $authorization | Add-Member -Type NoteProperty -Name identity -Value $null;
                            }
                        }
                        #Get RBAC
                        $rid = $authorization | Select-Object -ExpandProperty roleDefinitionId -ErrorAction Ignore
                        If($rid){
                            $p = @{
			                    RoleObjectId = $rid;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
		                    }
                            $role = Get-MonkeyAzRoleDefinitionObject @p
                            If($role){
                                $authorization | Add-Member -Type NoteProperty -Name roleDefinition -Value $role;
                            }
                            Else{
                                $authorization | Add-Member -Type NoteProperty -Name roleDefinition -Value $null;
                            }
                        }
                    }
                }
                #Return object
                return $workspaceObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
