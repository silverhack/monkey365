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

Function New-MonkeyStorageManagedLustreObject {
<#
        .SYNOPSIS
		Create a new storage managed Lustre object

        .DESCRIPTION
		Create a new storage managed Lustre object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyStorageManagedLustreObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Manage Lustre object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $lustreObj = [ordered]@{
                id = $InputObject | Select-Object -ExpandProperty id -ErrorAction Ignore;
		        name = $InputObject | Select-Object -ExpandProperty name -ErrorAction Ignore;
                type = $InputObject | Select-Object -ExpandProperty type -ErrorAction Ignore;
                zones = $InputObject | Select-Object -ExpandProperty zones -ErrorAction Ignore;
                location = $InputObject | Select-Object -ExpandProperty location -ErrorAction Ignore;
                tags = $InputObject | Select-Object -ExpandProperty tags -ErrorAction Ignore;
                sku = $InputObject | Select-Object -ExpandProperty sku -ErrorAction Ignore;
                systemData = $InputObject | Select-Object -ExpandProperty systemData -ErrorAction Ignore;
                properties = $InputObject | Select-Object -ExpandProperty properties -ErrorAction Ignore;
                importJobs = $null;
                autoExportJobs = $null;
                networking = [PSCustomObject]@{
                    settings = [PSCustomObject]@{
                        mgsAddress = $InputObject.properties.clientInfo | Select-Object -ExpandProperty mgsAddress -ErrorAction Ignore
                        mountCommand = $InputObject.properties.clientInfo | Select-Object -ExpandProperty mountCommand -ErrorAction Ignore
                        lustreVersion = $InputObject.properties.clientInfo | Select-Object -ExpandProperty lustreVersion -ErrorAction Ignore
                        staticIP = $InputObject.properties.clientInfo | Select-Object -ExpandProperty mgsAddress -ErrorAction Ignore
                    };
                    subnet = If($InputObject.properties.Psobject.Properties.Item('filesystemSubnet')){$InputObject.properties.filesystemSubnet}Else{$null};
                    virtualNetworkId = If($InputObject.properties.Psobject.Properties.Item('filesystemSubnet')){$InputObject.properties.filesystemSubnet.Remove($InputObject.properties.filesystemSubnet.LastIndexOf('/subnets/'))}Else{$null};
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
            $_obj = New-Object -TypeName PsObject -Property $lustreObj
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = $_;
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('ManagedLustreObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "ManagedLustreObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
