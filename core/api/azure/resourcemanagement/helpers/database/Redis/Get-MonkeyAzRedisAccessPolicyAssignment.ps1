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

Function Get-MonkeyAzRedisAccessPolicyAssignment {
    <#
        .SYNOPSIS
		Get Redis policy assignment

        .DESCRIPTION
		Get Redis policy assignment

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzRedisAccessPolicyAssignment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, HelpMessage="Redis object")]
        [Object]$RedisObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2023-08-01"
    )
    try{
        $p = @{
			Id = $RedisObject.Id;
            Resource = '/accessPolicyAssignments';
            ApiVersion = $APIVersion;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
            InformationAction = $O365Object.InformationAction;
		}
		Get-MonkeyAzObjectById @p
    }
    catch{
        Write-Verbose $_
    }
}

