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

Function Get-MonkeyAzAdvancedThreatProtection {
    <#
        .SYNOPSIS
		Get advanced threat protection settings for a resource

        .DESCRIPTION
		Get advanced threat protection settings for a resource

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzAdvancedThreatProtection
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$Resource,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2017-08-01-preview"
    )
    Process{
        $p = @{
			Id = $Resource.Id;
            Resource = "providers/Microsoft.Security/advancedThreatProtectionSettings/current";
            ApiVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
		}
		$atp = Get-MonkeyAzObjectById @p
        if($atp){
            return $atp
        }
    }
    End{
        #Nothing to do here
    }
}

