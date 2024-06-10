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


Function Get-MonkeyCSOMPermission{
    <#
        .SYNOPSIS
		Get permissions applied on a particular object, such as: Web, List, Folder or List Item

        .DESCRIPTION
		Get permissions applied on a particular object, such as: Web, List, Folder or List Item

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="SharePoint Object: Web, List, Folder or List Item")]
        [Object]$Object,

        [parameter(Mandatory= $false, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory= $false, HelpMessage="SharePoint url")]
        [String]$Endpoint
    )
    Begin{
        #Set null
        $sps_uri = $null
        #Get SharePoint url from params
        if($PSBoundParameters.ContainsKey('Endpoint') -and $PSBoundParameters['Endpoint']){
            [uri]$sps_uri = $PSBoundParameters['Endpoint']
        }
        ElseIf($PSBoundParameters.ContainsKey('Authentication') -and $PSBoundParameters['Authentication']){
            $_ep = $PSBoundParameters['Authentication'] | Select-Object -ExpandProperty resource -ErrorAction Ignore
            If($null -ne $_ep){
                [uri]$sps_uri = $PSBoundParameters['Authentication'].resource
            }
        }
        ElseIf($null -ne $O365Object.auth_tokens.SharePointOnline){
            [uri]$sps_uri = $O365Object.auth_tokens.SharePointOnline.resource
        }
        Else{
            $msg = @{
                MessageData = ("Unable to resolve SharePoint Url");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('MonkeyCSOMPermissionError');
            }
            Write-Warning @msg
        }
    }
    Process{
        foreach($obj in @($PSBoundParameters['Object']).Where({$null -ne $_})){
            #Set null
            $hasUniquePermissions = $roleAssignment = $null
            #Get ObjectType
            $objectType = $obj | Get-MonkeyCSOMObjectType
            if($null -eq $objectType){
                return
            }
            #Add url to objectType
            if($null -ne $objectType.Path){
                If($null -ne $sps_uri){
                    $fullObjectPath = [System.Uri]::new($sps_uri,$objectType.Path)
                    $objectType.Url = $fullObjectPath.ToString()
                }
            }
            else{
                If($null -ne $sps_uri){
                    $objectType.Url = $sps_uri.ToString()
                }
            }
            #Clean object
            $spObject = Update-MonkeyCSOMObject -Object $obj
            #Set command parameters
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMRoleAssignment" -Params $PSBoundParameters
            #Add ClientObject
            [void]$p.Add('ClientObject',$spObject);
            #Include unique role assignment
            [void]$p.Add('IncludeHasUniqueRoleAssignment',$True);
            $roleInfo = Get-MonkeyCSOMRoleAssignment @p
            if($null -ne $roleInfo){
                #Get unique permissions
                $hasUniquePermissions = $roleInfo.HasUniqueRoleAssignments
                #Get role assignments
                $roleAssignment = $roleInfo.RoleAssignments
            }
        }
    }
    End{
        foreach($role in @($roleAssignment).Where({$null -ne $_})){
            #Set command parameters
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMRoleDefinitionBinding" -Params $PSBoundParameters
            #Add ClientObject
            [void]$p.Add('ClientObject',$role);
            #Include unique role assignment
            [void]$p.Add('IncludeMember',$True);
            $roleDefinitionBinding = Get-MonkeyCSOMRoleDefinitionBinding @p
            if($null -ne $roleDefinitionBinding){
                #Remove Limited Access
                $permLevel = $roleDefinitionBinding.RoleDefinitionBindings.Where({$_.Name -ne "Limited Access"}) | Select-Object Name, Description -ErrorAction Ignore
                if($null -ne $permLevel){
                    #Set command parameters
                    $p = Set-CommandParameter -Command "Resolve-MonkeyCSOMPermission" -Params $PSBoundParameters
                    $members = $roleDefinitionBinding | Resolve-MonkeyCSOMPermission @p
                    $PermObject = $objectType | New-MonkeyCSOMPermissionObject
                    $PermObject.HasUniquePermissions = $hasUniquePermissions;
                    $PermObject.AppliedTo = [PrincipalType]$roleDefinitionBinding.Member.PrincipalType;;
                    $PermObject.Permissions = ($roleDefinitionBinding.RoleDefinitionBindings | Select-Object Name, Description -ErrorAction Ignore);
                    $PermObject.GrantedThrough = $members | Select-Object -ExpandProperty GrantedThrough -First 1;
                    $PermObject.RoleAssignment = $roleDefinitionBinding.RoleDefinitionBindings;
                    $PermObject.Description = ($roleDefinitionBinding.RoleDefinitionBindings | Select-Object -ExpandProperty Description) -join  "; ";
                    $PermObject.members = $members | Select-Object -ExpandProperty member -ErrorAction Ignore;
                    $PermObject.rawObject = $obj;
                    $PermObject
                }
            }
        }
        #Sleep
        Start-Sleep -Milliseconds 500
    }
}