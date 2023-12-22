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

Function Get-MonkeyAzAPIMBackend {
    <#
        .SYNOPSIS
		Get APIM backend

        .DESCRIPTION
		Get APIM backend

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzAPIMBackend
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2022-09-01-preview"
    )
    Process{
        try{
            $p = @{
			    Id = $InputObject.Id;
                Resource = '/backends';
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $backends = Get-MonkeyAzObjectById @p
            foreach($backend in $backends){
                $p = @{
			        Id = $InputObject.Id;
                    Resource = ('/backends/{0}' -f $backend.name);
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
                $myBackend = Get-MonkeyAzObjectById @p
                if($null -ne $myBackend -and $null -eq $myBackend.properties.PsObject.Properties.Item('credentials')){
                    $backend | Add-Member -type NoteProperty -name authorizationCredentials -value $false -Force
                }
                else{
                    $backend | Add-Member -type NoteProperty -name authorizationCredentials -value $True -Force
                }
            }
            return $backends
        }
        catch{
            Write-Verbose $_
        }
    }
}