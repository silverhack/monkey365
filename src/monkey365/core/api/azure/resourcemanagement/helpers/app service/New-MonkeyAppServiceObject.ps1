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

Function New-MonkeyAppServiceObject {
<#
        .SYNOPSIS
		Create a new app service object

        .DESCRIPTION
		Create a new app service object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyAppServiceObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="app service object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $AppObject = [ordered]@{
                id = $InputObject.Id;
		        name = $InputObject.Name;
                location = $InputObject.location;
                kind = $InputObject | Select-Object -ExpandProperty kind -ErrorAction Ignore
		        tags = $InputObject | Select-Object -ExpandProperty tags -ErrorAction Ignore
                type = $InputObject | Select-Object -ExpandProperty type -ErrorAction Ignore
                properties = $InputObject | Select-Object -ExpandProperty properties -ErrorAction Ignore
                resourceGroupName = $InputObject.Id.Split("/")[4];
		        fqdn = $InputObject.properties.defaultHostName;
                networking = [PSCustomObject]@{
                    httpsOnly = $InputObject.properties | Select-Object -ExpandProperty httpsOnly -ErrorAction Ignore
                    endToEndEncryptionEnabled = $InputObject.properties | Select-Object -ExpandProperty endToEndEncryptionEnabled -ErrorAction Ignore
                    minimumTlsVersion = $null;
                    settings = [PSCustomObject]@{
                        hostName = $InputObject.properties | Select-Object -ExpandProperty defaultHostName -ErrorAction Ignore
                        inboundIpAddress = $InputObject.properties | Select-Object -ExpandProperty inboundIpAddress -ErrorAction Ignore
                        outboundIpAddresses = $InputObject.properties | Select-Object -ExpandProperty outboundIpAddresses -ErrorAction Ignore
                    };
                    publicNetworkAccess = $InputObject.properties | Select-Object -ExpandProperty publicNetworkAccess -ErrorAction Ignore
                    subnet = $null;
                    virtualNetworkId = $null;
                    privateEndpointConnections = $null;
                    virtualNetworkConnections = $null;
                    hybridConnectionRelays = $null;
                    privateDNS = $null;
                };
                config = $null;
                identity = [PSCustomObject]@{
                    enabled = $false;
                    type = $null;
                    rawData = $null;
                };
                stack = [PSCustomObject]@{
                    operatingSystem = $null;
                    python = [PSCustomObject]@{
                        enabled = $false
                        version = $null;
                    };
                    dotnet = [PSCustomObject]@{
                        enabled = $false
                        version = $null;
                    };
                    php = [PSCustomObject]@{
                        enabled = $false
                        version = $null;
                    };
                    node = [PSCustomObject]@{
                        enabled = $false
                        version = $null;
                    };
                    java = [PSCustomObject]@{
                        enabled = $false
                        version = $null;
                    };
                };
                basicPublishingCredentialsPolicies = $null;
                authSettings = $null;
                authSettingsV2 = $null;
                appSettings = $null;
                locks = $null;
                diagnosticSettings = [PSCustomObject]@{
                    enabled = $false;
                    name = $null;
                    id = $null;
                    properties = $null;
                    rawData = $null;
                };
                recovery = [PSCustomObject]@{
                    backup = [PSCustomObject]@{
                        count = $null;
                        rawData = $null;
                    };
                    snapShot = [PSCustomObject]@{
                        count = $null;
                        rawData = $null;
                    };
                };
                rawObject = $InputObject;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $AppObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "App service");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('AppServiceObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "AppServiceObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
