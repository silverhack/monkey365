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

Function Test-HasUniqueRoleAssignment{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-HasUniqueRoleAssignment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([Bool])]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Inputobject")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [Parameter(Mandatory=$false, HelpMessage="Url")]
        [String]$Endpoint
    )
    Process{
        Try{
            #Set command parameters
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMProperty" -Params $PSBoundParameters
            #Add ClientObject
            $p.Item('ClientObject') = $InputObject;
            #Add properties
            $p.Item('Properties') = "HasUniqueRoleAssignments";
            #Add authentication header if missing
            if(!$p.ContainsKey('Authentication')){
                if($null -ne $O365Object.auth_tokens.SharePointOnline){
                    [void]$p.Add('Authentication',$O365Object.auth_tokens.SharePointOnline);
                }
                Else{
                    Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online")
                    break
                }
            }
            #Check if object has direct permissions
            $role = Get-MonkeyCSOMProperty @p
            if($null -ne $role){
                $role.HasUniqueRoleAssignments
            }
            else{
                Write-Warning "Unable to get unique role assignments for SharePoint Online"
                $false
            }
        }
        Catch{
            Write-Verbose $_
            return $false
        }
    }
}

