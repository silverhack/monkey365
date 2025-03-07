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

Function Get-MonkeyCSOMRoleAssignment{
    <#
        .SYNOPSIS
        Get role assignment from SharePoint Online

        .DESCRIPTION
        Get role assignment from SharePoint Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMRoleAssignment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="SharePoint Object")]
        [Object]$ClientObject,

        [parameter(Mandatory=$False, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$False, HelpMessage="Endpoint")]
        [String]$Endpoint,

        [parameter(Mandatory=$False, HelpMessage="Include HasUniqueRoleAssignment property")]
        [Switch]$IncludeHasUniqueRoleAssignment
    )
    Process{
        try{
            #Get command metadata
            $CommandMetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-MonkeyCSOMProperty")
            #Set new dict
            $newPsboundParams = [ordered]@{}
            $param = $CommandMetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                }
            }
            #Add verbose, debug, etc..
            [void]$newPsboundParams.Add('InformationAction',$O365Object.InformationAction)
            [void]$newPsboundParams.Add('Verbose',$O365Object.verbose)
            [void]$newPsboundParams.Add('Debug',$O365Object.debug)
            If($PSBoundParameters.ContainsKey('IncludeHasUniqueRoleAssignment') -and $PSBoundParameters['IncludeHasUniqueRoleAssignment'].IsPresent){
                [void]$newPsboundParams.Add('Properties',("RoleAssignments","HasUniqueRoleAssignments"))
            }
            Else{
                [void]$newPsboundParams.Add('Properties',"RoleAssignments")
            }
            Get-MonkeyCSOMProperty @newPsboundParams
        }
        Catch{
            $msg = @{
                MessageData = ("Unable to get role assignment");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('MonkeyCSOMRoleAssignmentError');
            }
            Write-Verbose @msg
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Error';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('MonkeyCSOMRoleAssignmentError');
            }
            Write-Error $_
        }
    }
}


