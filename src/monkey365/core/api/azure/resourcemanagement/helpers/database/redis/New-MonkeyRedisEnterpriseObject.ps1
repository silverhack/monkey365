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

Function New-MonkeyRedisEnterpriseObject {
<#
        .SYNOPSIS
		Create a new redis enterprise object

        .DESCRIPTION
		Create a new redis enterprise object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyRedisEnterpriseObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Redis object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $RedisObject = [ordered]@{
                id = $InputObject | Select-Object -ExpandProperty id -ErrorAction Ignore;
		        name = $InputObject | Select-Object -ExpandProperty name -ErrorAction Ignore;
                location = $InputObject | Select-Object -ExpandProperty location -ErrorAction Ignore;
		        tags = $InputObject | Select-Object -ExpandProperty tags -ErrorAction Ignore;
                sku = $InputObject | Select-Object -ExpandProperty sku -ErrorAction Ignore;
                type = $InputObject | Select-Object -ExpandProperty type -ErrorAction Ignore;
                identity = $InputObject | Select-Object -ExpandProperty identity -ErrorAction Ignore;
                provisioningState = $InputObject.properties | Select-Object -ExpandProperty provisioningState -ErrorAction Ignore;
                properties = $InputObject | Select-Object -ExpandProperty properties -ErrorAction Ignore;
                encryption = $InputObject.properties | Select-Object -ExpandProperty encryption -ErrorAction Ignore;
                resourceGroupName = $InputObject.Id.Split("/")[4];
                maintenanceConfiguration = $InputObject.properties | Select-Object -ExpandProperty maintenanceConfiguration -ErrorAction Ignore;
                databases = $null;
                databaseAccessPolicyAssignments = $null;
                dataAccess = [PSCustomObject]@{
                    accessPolicy = $null;
                    accessPolicyAssignments = $null;
                }
                networking = [PSCustomObject]@{
                    minimumTlsVersion = $InputObject.properties | Select-Object -ExpandProperty minimumTlsVersion -ErrorAction Ignore
                    settings = [PSCustomObject]@{
                        hostName = $InputObject.properties | Select-Object -ExpandProperty hostName -ErrorAction Ignore
                        port = $InputObject.properties | Select-Object -ExpandProperty port -ErrorAction Ignore
                        sslPort = $InputObject.properties | Select-Object -ExpandProperty sslPort -ErrorAction Ignore
                        staticIP = $InputObject.properties | Select-Object -ExpandProperty staticIP -ErrorAction Ignore
                    };
                    publicNetworkAccess = $InputObject.properties | Select-Object -ExpandProperty publicNetworkAccess -ErrorAction Ignore
                    subnet = $InputObject.properties | Select-Object -ExpandProperty subnetId -ErrorAction Ignore
                    virtualNetworkId = If($InputObject.properties.Psobject.Properties.Item('subnetId')){$InputObject.properties.subnetId.Remove($InputObject.properties.subnetId.LastIndexOf('/subnets/'))}Else{$null};
                    privateEndpointConnections = $null;
                    privateLink = $null;
                };
                diagnosticSettings = [PSCustomObject]@{
                    enabled = $false;
                    name = $null;
                    id = $null;
                    properties = $null;
                    rawData = $null;
                };
                locks = $null;
                rawObject = $InputObject;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $RedisObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "Redis object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('RedisObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "RedisObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
