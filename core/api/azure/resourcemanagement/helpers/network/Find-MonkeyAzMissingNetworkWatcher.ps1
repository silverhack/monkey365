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

Function Find-MonkeyAzMissingNetworkWatcher {
    <#
        .SYNOPSIS
		Find missing network watcher in specific regions

        .DESCRIPTION
		Find missing network watcher in specific regions

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Find-MonkeyAzMissingNetworkWatcher
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Object]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
	Param (
        [Parameter(Mandatory=$True, HelpMessage="Network Watcher objects")]
        [Object]$InputObject
    )
    Process{
        #Set array
        $disabledNetworkWatchers = [System.Collections.Generic.List[System.Object]]::new()
        try{
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Azure Network Watcher");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureNetworkWatcherInfo');
			}
			Write-Information @msg
            #Get locations
            $URI = ("{0}/locations" -f $O365Object.current_subscription.Id)
            $p = @{
	            Id = $URI;
                ApiVersion = '2022-12-01';
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $supportedLocations = Get-MonkeyAzObjectById @p
            #Get only physical locations
            $locations = $supportedLocations.Where({$_.metadata.regionType -eq "Physical"})
            #Get network watcher locations
            $nwLocations = $InputObject | Select-Object -ExpandProperty location
            #get locations
            $subscriptionLocations = $locations | Select-Object -ExpandProperty name
            #Get effective locations
            $disabledLocations = Compare-Object -ReferenceObject $nwLocations -DifferenceObject $subscriptionLocations -PassThru
            #Create object
            Foreach($loc in $disabledLocations){
                $obj = [PsCustomObject]@{
                    id = $null;
                    name = ("NetworkWatcher_{0}" -f $loc);
                    type = "Microsoft.Network/networkWatchers";
                    location = $loc;
                    tags = $null;
                    properties = [PsCustomObject]@{
                        provisioningState = $null;
                    }
                }
                $obj = $obj | New-MonkeyNetworkWatcherObject
                #Add to array
                $disabledNetworkWatchers.Add($obj);
            }
            #return object
            return $disabledNetworkWatchers;
        }
        catch{
            Write-Verbose $_
        }
    }
}

