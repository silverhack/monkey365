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

Function Get-OrgRegion{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-OrgRegion
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    Param()
    Begin{
        $org = $null
        $regions = @()
    }
    Process{
        if($null -ne (Get-Command Get-ExoMonkeyOrganizationConfig -ErrorAction Ignore)){
            $org = Get-ExoMonkeyOrganizationConfig
        }
        if($null -ne $org){
            $all_regions = $org.AllowedMailboxRegions
            if($all_regions){
                foreach($region in $all_regions){
                    $parsed_region = $region.Split('=')[0]
                    if($parsed_region){
                        $regions+= $parsed_region.ToUpper()
                    }
                }
            }
        }
    }
    End{
        return $regions
    }
}
