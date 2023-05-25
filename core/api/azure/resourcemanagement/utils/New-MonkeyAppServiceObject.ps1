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
        [parameter(Mandatory= $True, HelpMessage="app service object")]
        [Object]$App
    )
    Process{
        try{
            #Create ordered dictionary
            $AppObject = [ordered]@{
                id = $App.Id;
		        name = $App.Name;
                location = $App.location;
                kind = if($null -ne $App.PsObject.Properties.Item('kind')){$App.kind}else{$null};
		        tags = $App.tags;
                properties = $App.properties;
                resourceGroupName = $App.Id.Split("/")[4];
		        fqdn = $App.properties.defaultHostName;
                httpsOnly = $App.properties.httpsOnly;
                appConfig = $null;
                identity = [PSCustomObject]@{
                    enabled = $false;
                    type = $null;
                    rawData = $null;
                };
                authSettings = $null;
                authSettingsV2 = $null;
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
                rawObject = $App;
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