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

Function Resolve-MonkeyCSOMPermission{
    <#
        .SYNOPSIS
        Get group members from Microsoft 365

        .DESCRIPTION

        Get group members from Microsoft 365

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-MonkeyCSOMPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    #[OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="SharePoint Role Definition Binging object")]
        [Object]$InputObject,

        [parameter(Mandatory= $false, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory= $false, HelpMessage="SharePoint url")]
        [String]$Endpoint
    )
    Process{
        Try{
            #Set null
            $members = $GrantedThrough = $null;
            #Set command parameters
            $p = Set-CommandParameter -Command "Resolve-MonkeyCSOMIdentity" -Params $PSBoundParameters
            #Get permissionLevel
            if($InputObject.Member.PrincipalType -eq [PrincipalType]::User){
                #Update InputObject
                $p.Item('InputObject') = $InputObject.Member;
                $members = Resolve-MonkeyCSOMIdentity @p
                #Set granted
                $GrantedThrough = "Direct Permissions";
            }
            ElseIf($InputObject.Member.PrincipalType -eq [PrincipalType]::SharePointGroup){
                if($InputObject.Member.OwnerTitle -ne "System Account"){#Remove sharing links
                    #Update InputObject
                    $p.Item('InputObject') = $InputObject.Member;
                    $members = Resolve-MonkeyCSOMIdentity @p
                    #Set granted
                    $GrantedThrough = ("SharePoint Group: {0}"-f $InputObject.Member.LoginName);
                }
            }
            ElseIf($InputObject.Member.PrincipalType -eq [PrincipalType]::SecurityGroup){
                #Update InputObject
                $p.Item('InputObject') = $InputObject.Member;
                $members = Resolve-MonkeyCSOMIdentity @p
                #Set granted
                $GrantedThrough = ("Security Group: {0}"-f $InputObject.Member.Title);
            }
            Else{
                $msg = @{
                    MessageData = "Unknown SharePoint Object";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('MonkeyCSOMUnknownIdentityObject');
                }
                Write-Verbose @msg
            }
            #Create psObject
            if($null -ne $members){
                foreach($member in @($members)){
                    try{
                        [PsCustomObject]@{
                            member = $member;
                            grantedThrough = $GrantedThrough;
                            appliedTo = [PrincipalType]$InputObject.Member.PrincipalType;
                            Permissions = ($InputObject.RoleDefinitionBindings | Select-Object Name, Description -ErrorAction Ignore);
                            RoleAssignment = $InputObject.RoleDefinitionBindings;
                            Description = ($InputObject.RoleDefinitionBindings | Select-Object -ExpandProperty Description) -join  "; ";
                            rawObject = $InputObject;
                        }
                    }
                    Catch{
                        $msg = @{
                            MessageData = $_;
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'Error';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('MonkeyCSOMUnknownIdentityObject');
                        }
                        Write-Error @msg
                    }
                }
            }
        }
        Catch{
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('MonkeyCSOMIdentityError');
            }
            Write-Verbose @msg
        }
    }
}

