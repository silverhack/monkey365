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

Function Get-UserIdFromToken{
    <#
        .SYNOPSIS

        Get User Id from Token

        .DESCRIPTION

        Get User Id from Token

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-UserIdFromToken
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Authentication Object")]
        [Object]$InputObject
    )
    Process{
        $UserObjectId = [String]::Empty
        if($null -ne $InputObject.PsObject.Properties.Item('UniqueId') -and $null -ne $InputObject.UniqueId){
            $UserObjectId = $InputObject.UniqueId
        }
        else{
            Write-Warning -Message ("Unable to get userId. UserId not found")
        }
        return $UserObjectId
    }
}

