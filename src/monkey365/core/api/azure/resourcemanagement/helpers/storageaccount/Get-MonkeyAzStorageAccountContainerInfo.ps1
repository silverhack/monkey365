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

Function Get-MonkeyAzStorageAccountContainerInfo {
    <#
        .SYNOPSIS
		Get information about containers within an storage account

        .DESCRIPTION
		Get information about containers within an storage account

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzStorageAccountContainerInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Redis object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-08-01"
    )
    Process{
        Try{
            #Set array
            $allContainers = [System.Collections.Generic.List[System.Object]]::new()
            #Get containers if any
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
            $containers = Get-MonkeyAzStorageAccountBlobContainer @p
            If($null -ne $containers){
                ForEach($container in @($containers)){
                    $container | Add-Member -MemberType NoteProperty -Name immutabilityPolicy -Value $null -Force
                    #Check for immutability
                    If($container.properties.hasImmutabilityPolicy){
                        $p = @{
			                Id = $container.Id;
                            ApiVersion = $APIVersion;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
		                }
                        $container.immutabilityPolicy = Get-MonkeyAzStorageAccountBlobContainerImmutabilityPolicy @p
                    }
                    [void]$allContainers.Add($container);
                }
            }
        }
        Catch{
            Write-Verbose $_
        }
        #return Object
        Write-Output $allContainers -NoEnumerate
    }
}
